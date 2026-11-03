import 'package:ecommerce_b2b/modules/order_flow/model/enums/credit_status.dart';
import 'package:ecommerce_b2b/modules/order_flow/model/enums/order_status.dart';
import 'package:ecommerce_b2b/modules/order_flow/sales_order/model/enums/finance_decision.dart';
import 'package:ecommerce_b2b/modules/order_flow/sales_order/model/order_timeline_entry.dart';
import 'package:ecommerce_b2b/modules/order_flow/sales_order/presentation/widgets/order_timeline.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget wrap(Widget child) => MaterialApp(
    home: Scaffold(body: SingleChildScrollView(child: child)),
  );

  final created = OrderTimelineEntry(
    id: 'e1',
    occurredAt: DateTime.utc(2026, 9, 20, 10),
    type: OrderTimelineEventType.created,
    toStatus: OrderStatus.pendingFinanceApproval,
    toCreditStatus: CreditStatus.approved,
    actorRole: 'System',
  );

  final changed = OrderTimelineEntry(
    id: 'e2',
    occurredAt: DateTime.utc(2026, 9, 21, 11),
    type: OrderTimelineEventType.statusChanged,
    fromStatus: OrderStatus.pendingFinanceApproval,
    toStatus: OrderStatus.pickingPacking,
    actorId: 'fin-1',
    actorRole: 'Finance',
  );

  testWidgets('renderiza o mais recente primeiro, mesmo fora de ordem', (
    tester,
  ) async {
    await tester.pumpWidget(wrap(OrderTimeline(entries: [created, changed])));

    final newest = tester.getTopLeft(find.text(changed.title)).dy;
    final oldest = tester.getTopLeft(find.text('Pedido criado')).dy;

    expect(newest, lessThan(oldest));
    expect(find.text('Histórico do pedido'), findsOneWidget);
    expect(find.text('2 eventos'), findsOneWidget);
  });

  testWidgets('mostra ator, crédito e observação', (tester) async {
    final reviewed = OrderTimelineEntry(
      id: 'e3',
      occurredAt: DateTime.utc(2026, 9, 21, 12),
      type: OrderTimelineEventType.financeReviewed,
      decision: FinanceDecision.rejected,
      actorId: 'fin-1',
      actorRole: 'Finance',
      note: 'Limite insuficiente',
    );

    await tester.pumpWidget(wrap(OrderTimeline(entries: [created, reviewed])));

    expect(find.text('Análise financeira: Reprovado'), findsOneWidget);
    expect(find.text('Limite insuficiente'), findsOneWidget);
    expect(find.textContaining('Financeiro · fin-1'), findsOneWidget);
    expect(find.text('Crédito: Aprovado'), findsOneWidget);
    expect(find.textContaining('Sistema'), findsOneWidget);
  });

  testWidgets('estado vazio', (tester) async {
    await tester.pumpWidget(wrap(const OrderTimeline(entries: [])));

    expect(find.text('Sem eventos registrados.'), findsOneWidget);
  });

  testWidgets('estado de carregamento', (tester) async {
    await tester.pumpWidget(
      wrap(const OrderTimeline(entries: [], loading: true)),
    );

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('estado de erro oferece retry', (tester) async {
    var retries = 0;
    await tester.pumpWidget(
      wrap(
        OrderTimeline(
          entries: const [],
          error: 'Falha de rede',
          onRetry: () async => retries++,
        ),
      ),
    );

    expect(find.text('Não foi possível carregar o histórico.'), findsOneWidget);
    expect(find.text('Falha de rede'), findsOneWidget);

    await tester.tap(find.text('Tentar novamente'));
    await tester.pump();

    expect(retries, 1);
  });
}
