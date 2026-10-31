import 'package:ecommerce_b2b/modules/logistics/infrastructure/api/fulfillment_api.dart';
import 'package:ecommerce_b2b/modules/logistics/shipment/domain/shipment.dart';
import 'package:ecommerce_b2b/modules/order_flow/sales_order/domain/sales_order.dart';
import 'package:ecommerce_b2b/modules/shared_kernel/domain/common/ids/warehouse_id.dart';
import 'package:ecommerce_b2b/modules/shared_kernel/domain/logistics/value_objects/tracking_code.dart';

/// Executa a expedição completa na API: picking, packing e shipment.
class ProcessOrderShipmentUseCase {
  final FulfillmentApi _fulfillmentApi;

  ProcessOrderShipmentUseCase(this._fulfillmentApi);

  Future<Shipment> execute({
    required SalesOrder order,
    required WarehouseId warehouseId,
    required TrackingCode trackingCode,
    required String labelNumber,
    String? packageDescription,
  }) {
    return _fulfillmentApi.processShipment(
      order: order,
      warehouseId: warehouseId,
      trackingCode: trackingCode.value,
      labelNumber: labelNumber,
      packageDescription: packageDescription,
    );
  }
}
