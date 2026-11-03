import 'package:ecommerce_b2b/app/core/events/order_events.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('OrderEvents', () {
    late OrderEvents events;

    setUp(() => events = OrderEvents());
    tearDown(() => events.dispose());

    test('notifica todos os ouvintes', () async {
      var first = 0;
      var second = 0;
      final sub1 = events.onChanged.listen((_) => first++);
      final sub2 = events.onChanged.listen((_) => second++);
      addTearDown(sub1.cancel);
      addTearDown(sub2.cancel);

      events.notifyChanged();
      await pumpEventQueue();

      expect(first, 1);
      expect(second, 1);
    });

    test('não notifica depois do dispose', () async {
      await events.dispose();

      expect(events.notifyChanged, returnsNormally);
    });

    test('sem ouvintes, notificar é inofensivo', () {
      expect(events.notifyChanged, returnsNormally);
    });
  });
}
