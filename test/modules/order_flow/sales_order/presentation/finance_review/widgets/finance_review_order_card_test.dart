import 'package:ecommerce_b2b/modules/order_flow/model/enums/credit_status.dart';
import 'package:ecommerce_b2b/modules/order_flow/model/enums/order_status.dart';
import 'package:ecommerce_b2b/modules/order_flow/sales_order/model/sales_order.dart';
import 'package:ecommerce_b2b/modules/order_flow/sales_order/presentation/finance_review/widgets/finance_review_order_card.dart';
import 'package:ecommerce_b2b/modules/shared_kernel/model/common/ids/order_id.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

SalesOrder _order() => SalesOrder(
  id: const OrderId('order-101'),
  status: OrderStatus.blockedByFinance,
  creditStatus: CreditStatus.blocked,
  items: const [],
);

Widget _wrap(
  SalesOrder order, {
  required VoidCallback onOpenDetails,
  required VoidCallback onApprove,
  required VoidCallback onReject,
}) => MaterialApp(
  home: Scaffold(
    body: SingleChildScrollView(
      child: FinanceReviewOrderCard(
        order: order,
        onOpenDetails: onOpenDetails,
        onApprove: onApprove,
        onReject: onReject,
      ),
    ),
  ),
);

void main() {
  testWidgets('tocar no card abre os detalhes', (tester) async {
    var opened = 0;
    final order = _order();

    await tester.pumpWidget(
      _wrap(
        order,
        onOpenDetails: () => opened++,
        onApprove: () {},
        onReject: () {},
      ),
    );

    await tester.tap(find.text('Itens do Pedido'));
    await tester.pumpAndSettle();

    expect(opened, 1);
  });

  testWidgets('botão de detalhes abre os detalhes', (tester) async {
    var opened = 0;
    final order = _order();

    await tester.pumpWidget(
      _wrap(
        order,
        onOpenDetails: () => opened++,
        onApprove: () {},
        onReject: () {},
      ),
    );

    await tester.tap(find.text('Ver detalhes do pedido'));
    await tester.pumpAndSettle();

    expect(opened, 1);
  });

  testWidgets('aprovar e reprovar não navegam para o detalhe', (tester) async {
    var opened = 0;
    var approved = 0;
    var rejected = 0;
    final order = _order();

    await tester.pumpWidget(
      _wrap(
        order,
        onOpenDetails: () => opened++,
        onApprove: () => approved++,
        onReject: () => rejected++,
      ),
    );

    await tester.tap(find.text('APROVAR'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('REPROVAR CRÉDITO'));
    await tester.pumpAndSettle();

    expect(approved, 1);
    expect(rejected, 1);
    expect(opened, 0);
  });

  testWidgets('badge de bloqueio explica o motivo sem navegar', (tester) async {
    var opened = 0;
    final order = _order();

    await tester.pumpWidget(
      _wrap(
        order,
        onOpenDetails: () => opened++,
        onApprove: () {},
        onReject: () {},
      ),
    );

    await tester.tap(find.text('BLOQUEADO'));
    await tester.pumpAndSettle();

    expect(find.text('Pedido bloqueado pelo Financeiro'), findsOneWidget);
    expect(opened, 0);
  });
}
