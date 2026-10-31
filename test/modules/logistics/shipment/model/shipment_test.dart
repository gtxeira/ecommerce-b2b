import 'package:ecommerce_b2b/modules/logistics/shipment/model/shipment.dart';
import 'package:ecommerce_b2b/modules/logistics/shipment/model/shipping_label.dart';
import 'package:ecommerce_b2b/modules/logistics/shipment/model/enums/shipment_status.dart';
import 'package:ecommerce_b2b/modules/shared_kernel/model/common/ids/shipment_id.dart';
import 'package:ecommerce_b2b/modules/shared_kernel/model/logistics/value_objects/tracking_code.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Shipment', () {
    // Deve criar um envio corretamente e atualizar o status.
    test('should create repositories and update status', () {
      const id = ShipmentId('s1');
      final trackingCode = TrackingCode.create('ABC123XYZ').getOrThrow();
      final label = ShippingLabel('LABEL123');
      
      final shipment = Shipment(
        id: id,
        orderId: 'order-1',
        trackingCode: trackingCode,
        status: ShipmentStatus.pending,
        shippingLabel: label,
      );

      expect(shipment.id, id);
      expect(shipment.status, ShipmentStatus.pending);

      shipment.updateStatus(ShipmentStatus.shipped);
      expect(shipment.status, ShipmentStatus.shipped);
    });
  });
}
