import 'package:ecommerce_b2b/modules/order_flow/model/enums/credit_status.dart';
import 'package:ecommerce_b2b/modules/order_flow/model/enums/order_status.dart';
import 'package:ecommerce_b2b/modules/order_flow/sales_order/model/order_item.dart';
import 'package:ecommerce_b2b/modules/order_flow/sales_order/model/sales_order.dart';
import 'package:ecommerce_b2b/modules/shared_kernel/model/common/ids/order_id.dart';
import 'package:ecommerce_b2b/modules/shared_kernel/model/common/ids/product_id.dart';
import 'package:ecommerce_b2b/modules/shared_kernel/model/finance/value_objects/money.dart';
import 'package:ecommerce_b2b/modules/shared_kernel/model/finance/value_objects/quantity.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('SalesOrder', () {
    // O total deve ser calculado corretamente com base nos itens do pedido.
    test('total should calculate correctly', () {
      final order = SalesOrder(
        id: const OrderId('o1'),
        status: OrderStatus.pendingFinanceApproval,
        creditStatus: CreditStatus.pending,
        items: [
          OrderItem(
            productId: const ProductId('p1'),
            quantity: Quantity.create(2).getOrThrow(),
            unitPriceSnapshot: Money.create(100).getOrThrow(),
          ),
          OrderItem(
            productId: const ProductId('p2'),
            quantity: Quantity.create(1).getOrThrow(),
            unitPriceSnapshot: Money.create(50).getOrThrow(),
          ),
        ],
      );

      expect(order.total.amount, 250);
    });

    // O total deve retornar 0 se não houver itens no pedido.
    test('total should return 0 if no items', () {
      final order = SalesOrder(
        id: const OrderId('o1'),
        status: OrderStatus.pendingFinanceApproval,
        creditStatus: CreditStatus.pending,
        items: [],
      );

      expect(order.total.amount, 0);
    });
  });
}
