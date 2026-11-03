import 'package:ecommerce_b2b/app/core/network/api_client.dart';
import 'package:ecommerce_b2b/app/core/network/api_exception.dart';
import 'package:ecommerce_b2b/app/core/network/json_read.dart';
import 'package:ecommerce_b2b/modules/logistics/shipment/model/enums/shipment_status.dart';
import 'package:ecommerce_b2b/modules/logistics/shipment/model/repositories/shipment_repository.dart';
import 'package:ecommerce_b2b/modules/logistics/shipment/model/shipment.dart';
import 'package:ecommerce_b2b/modules/logistics/shipment/model/shipping_label.dart';
import 'package:ecommerce_b2b/modules/shared_kernel/model/common/ids/shipment_id.dart';
import 'package:ecommerce_b2b/modules/shared_kernel/model/logistics/value_objects/tracking_code.dart';

class ApiShipmentRepository implements ShipmentRepository {
  final ApiClient _api;

  ApiShipmentRepository(this._api);

  @override
  Future<void> save(Shipment shipment) async {
    // A expedição é feita pelos endpoints de picking/packing/shipment.
    throw UnsupportedError('A API não aceita salvar um envio genérico.');
  }

  @override
  Future<Shipment?> getById(ShipmentId id) async {
    // A API expõe o envio pelo pedido; sem o pedido não há como resolver o id.
    return null;
  }

  @override
  Future<Shipment?> getByOrderId(String orderId) async {
    try {
      final data = await _api.get('/api/orders/$orderId/shipment');
      if (data is! Map) return null;
      return fromJson(Map<String, dynamic>.from(data));
    } on ApiException catch (error) {
      if (error.isNotFound) return null;
      rethrow;
    }
  }

  static Shipment fromJson(Map<String, dynamic> json) => Shipment(
    id: ShipmentId(readString(json, 'shipmentId')),
    orderId: readString(json, 'orderId'),
    trackingCode: TrackingCode.create(
      readString(json, 'trackingCode'),
    ).getOrThrow(),
    status: _statusFromApi(readString(json, 'status')),
    shippingLabel: ShippingLabel(readString(json, 'labelNumber')),
  );

  static ShipmentStatus _statusFromApi(String value) =>
      switch (value.toLowerCase()) {
        'shipped' => ShipmentStatus.shipped,
        'intransit' => ShipmentStatus.inTransit,
        'delivered' => ShipmentStatus.delivered,
        'cancelled' => ShipmentStatus.cancelled,
        _ => ShipmentStatus.pending,
      };
}
