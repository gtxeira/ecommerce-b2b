import 'package:ecommerce_b2b/modules/logistics/shipment/model/shipment.dart';
import 'package:ecommerce_b2b/modules/shared_kernel/model/common/ids/shipment_id.dart';

abstract class ShipmentRepository {
  Future<void> save(Shipment shipment);
  Future<Shipment?> getById(ShipmentId id);
  Future<Shipment?> getByOrderId(String orderId);
}
