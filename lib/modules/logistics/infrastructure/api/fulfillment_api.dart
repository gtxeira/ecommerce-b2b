import 'package:ecommerce_b2b/app/core/network/api_client.dart';
import 'package:ecommerce_b2b/app/core/network/json_read.dart';
import 'package:ecommerce_b2b/modules/logistics/shipment/domain/shipment.dart';
import 'package:ecommerce_b2b/modules/logistics/shipment/infrastructure/repositories/api_shipment_repository.dart';
import 'package:ecommerce_b2b/modules/order_flow/sales_order/domain/sales_order.dart';
import 'package:ecommerce_b2b/modules/shared_kernel/domain/common/ids/warehouse_id.dart';

class FulfillmentState {
  final bool hasPicking;
  final bool pickingCompleted;
  final bool hasPacking;
  final bool packingCompleted;
  final Shipment? shipment;

  const FulfillmentState({
    required this.hasPicking,
    required this.pickingCompleted,
    required this.hasPacking,
    required this.packingCompleted,
    required this.shipment,
  });

  bool get isDispatched => shipment != null;
}

/// Fluxo de expedição: separação -> embalagem -> envio.
class FulfillmentApi {
  final ApiClient _api;

  FulfillmentApi(this._api);

  Future<FulfillmentState> getState(String orderId) async {
    final data = await _api.get('/api/orders/$orderId/fulfillment');
    if (data is! Map) {
      return const FulfillmentState(
        hasPicking: false,
        pickingCompleted: false,
        hasPacking: false,
        packingCompleted: false,
        shipment: null,
      );
    }

    final json = Map<String, dynamic>.from(data);
    final picking = json['picking'];
    final packing = json['packing'];
    final shipment = json['shipment'];

    return FulfillmentState(
      hasPicking: picking is Map,
      pickingCompleted:
          picking is Map &&
          readString(Map<String, dynamic>.from(picking), 'status') ==
              'Completed',
      hasPacking: packing is Map,
      packingCompleted:
          packing is Map &&
          readString(Map<String, dynamic>.from(packing), 'status') ==
              'Completed',
      shipment: shipment is Map
          ? ApiShipmentRepository.fromJson(Map<String, dynamic>.from(shipment))
          : null,
    );
  }

  /// Executa as etapas que ainda faltam e registra o envio.
  Future<Shipment> processShipment({
    required SalesOrder order,
    required WarehouseId warehouseId,
    required String trackingCode,
    required String labelNumber,
    String? packageDescription,
  }) async {
    final items = order.items
        .map(
          (item) => {
            'productId': item.productId.value,
            'quantity': item.quantity.value,
          },
        )
        .toList();

    final pickingData = await _api.post(
      '/api/orders/${order.id.value}/picking',
      data: {'warehouseId': warehouseId.value},
    );
    final pickingId = readString(
      Map<String, dynamic>.from(pickingData as Map),
      'pickingId',
    );

    await _api.post('/api/picking/$pickingId/complete', data: {'items': items});

    final packingData = await _api.post(
      '/api/packing/$pickingId/start',
      data: {'packageDescription': packageDescription},
    );
    final packingId = readString(
      Map<String, dynamic>.from(packingData as Map),
      'packingId',
    );

    await _api.post(
      '/api/packing/$packingId/complete',
      data: {'items': items, 'packageDescription': packageDescription},
    );

    final shipmentData = await _api.post(
      '/api/orders/${order.id.value}/shipment',
      data: {'trackingCode': trackingCode, 'labelNumber': labelNumber},
    );

    return ApiShipmentRepository.fromJson(
      Map<String, dynamic>.from(shipmentData as Map),
    );
  }
}
