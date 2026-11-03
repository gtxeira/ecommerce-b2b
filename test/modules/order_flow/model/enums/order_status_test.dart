import 'package:ecommerce_b2b/modules/order_flow/model/enums/order_status.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('OrderStatusGrouping', () {
    test('status em fluxo são abertos', () {
      expect(OrderStatus.pendingFinanceApproval.isOpen, isTrue);
      expect(OrderStatus.blockedByFinance.isOpen, isTrue);
      expect(OrderStatus.pickingPacking.isOpen, isTrue);
      expect(OrderStatus.inTransit.isOpen, isTrue);
    });

    test('status terminais são encerrados', () {
      expect(OrderStatus.delivered.isOpen, isFalse);
      expect(OrderStatus.invoiced.isOpen, isFalse);
      expect(OrderStatus.cancelled.isOpen, isFalse);
      expect(OrderStatus.rma.isOpen, isFalse);
    });

    test('group acompanha isOpen', () {
      for (final status in OrderStatus.values) {
        expect(
          status.group,
          status.isOpen ? OrderStatusGroup.open : OrderStatusGroup.closed,
          reason: 'status $status',
        );
      }
    });

    test('todo status pertence a exatamente um grupo', () {
      final open = OrderStatus.values.where((s) => s.isOpen).length;
      final closed = OrderStatus.values.where((s) => !s.isOpen).length;

      expect(open + closed, OrderStatus.values.length);
      expect(open, 4);
      expect(closed, 4);
    });

    test('grupos têm rótulos em português', () {
      expect(OrderStatusGroup.open.label, 'Abertos');
      expect(OrderStatusGroup.closed.label, 'Encerrados');
    });
  });
}
