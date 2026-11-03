import 'package:ecommerce_b2b/modules/order_flow/model/enums/credit_status.dart';
import 'package:ecommerce_b2b/modules/order_flow/model/enums/order_status.dart';
import 'package:ecommerce_b2b/modules/order_flow/sales_order/model/enums/finance_decision.dart';
import 'package:ecommerce_b2b/modules/order_flow/sales_order/model/finance_review.dart';
import 'package:ecommerce_b2b/modules/order_flow/sales_order/model/order_item.dart';
import 'package:ecommerce_b2b/modules/order_flow/sales_order/model/sales_order.dart';
import 'package:ecommerce_b2b/modules/order_flow/sales_order/presentation/widgets/order_details_content.dart';
import 'package:ecommerce_b2b/modules/order_flow/sales_order/presentation/widgets/order_summary_tile.dart';
import 'package:ecommerce_b2b/modules/shared_kernel/model/common/ids/order_id.dart';
import 'package:ecommerce_b2b/modules/shared_kernel/model/common/ids/product_id.dart';
import 'package:ecommerce_b2b/modules/shared_kernel/model/finance/value_objects/money.dart';
import 'package:ecommerce_b2b/modules/shared_kernel/model/finance/value_objects/quantity.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final order = SalesOrder(
    id: const OrderId('order-101'),
    companyId: 'company-1',
    status: OrderStatus.delivered,
    creditStatus: CreditStatus.approved,
    items: [
      OrderItem(
        productId: const ProductId('product-1'),
        quantity: Quantity.create(2).getOrThrow(),
        unitPriceSnapshot: Money.create(10).getOrThrow(),
      ),
    ],
    shippingCost: Money.create(5).getOrThrow(),
  );

  Widget wrap(Widget child) => MaterialApp(home: Scaffold(body: child));

  group('OrderSummaryTile', () {
    testWidgets('mostra id, status e total', (tester) async {
      await tester.pumpWidget(
        wrap(OrderSummaryTile(order: order, onTap: () {})),
      );

      expect(find.text('Pedido #order-101'), findsOneWidget);
      expect(
        find.textContaining('Status: ${order.status.label}'),
        findsOneWidget,
      );
      expect(find.textContaining(order.total.formatted), findsOneWidget);
      expect(find.byIcon(Icons.chevron_right_rounded), findsOneWidget);
    });

    testWidgets('tocar no tile dispara onTap', (tester) async {
      var taps = 0;
      await tester.pumpWidget(
        wrap(OrderSummaryTile(order: order, onTap: () => taps++)),
      );

      await tester.tap(find.byType(ListTile));
      await tester.pump();

      expect(taps, 1);
    });
  });

  group('OrderDetailsContent', () {
    testWidgets('mostra itens, frete e total', (tester) async {
      await tester.pumpWidget(wrap(OrderDetailsContent(order: order)));

      expect(find.textContaining('2x Produto #product-1'), findsOneWidget);
      expect(find.text('Frete'), findsOneWidget);
      expect(find.text('Total'), findsOneWidget);
      expect(find.text(order.total.formatted), findsOneWidget);
    });

    testWidgets('mostra a decisão financeira quando existe', (tester) async {
      await tester.pumpWidget(
        wrap(
          OrderDetailsContent(
            order: SalesOrder(
              id: const OrderId('order-102'),
              status: OrderStatus.pendingFinanceApproval,
              creditStatus: CreditStatus.pending,
              items: const [],
              financeReview: FinanceReview(
                decision: FinanceDecision.approved,
                reviewerId: 'u1',
                reviewedAt: DateTime(2026, 1, 1),
                justification: 'Crédito ok',
              ),
            ),
          ),
        ),
      );

      expect(find.text('Análise Financeira'), findsOneWidget);
      expect(find.textContaining('Aprovado'), findsOneWidget);
    });
  });
}
