import 'package:ecommerce_b2b/modules/logistics/shipment/model/tracking_event.dart';
import 'package:ecommerce_b2b/modules/logistics/shipment/model/enums/tracking_status.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('TrackingEvent', () {
    /// deve comparar igualdade baseada nos valores
    test('should compare equality based on values', () {
      final now = DateTime.now();
      final event1 = TrackingEvent(
        status: TrackingStatus.pickedUp,
        occurredAt: now,
        location: 'Sao Paulo',
      );
      final event2 = TrackingEvent(
        status: TrackingStatus.pickedUp,
        occurredAt: now,
        location: 'Sao Paulo',
      );

      expect(event1, equals(event2));
    });

    /// deve falhar na igualdade se qualquer campo for diferente
    test('should fail equality if any field is different', () {
      final now = DateTime.now();
      final event1 = TrackingEvent(
        status: TrackingStatus.pickedUp,
        occurredAt: now,
      );
      final event2 = TrackingEvent(
        status: TrackingStatus.atTerminal,
        occurredAt: now,
      );

      expect(event1, isNot(equals(event2)));
    });
  });
}
