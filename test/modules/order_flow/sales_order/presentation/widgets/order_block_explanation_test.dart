import 'package:ecommerce_b2b/modules/order_flow/model/enums/credit_status.dart';
import 'package:ecommerce_b2b/modules/order_flow/model/enums/order_status.dart';
import 'package:ecommerce_b2b/modules/order_flow/sales_order/model/enums/finance_decision.dart';
import 'package:ecommerce_b2b/modules/order_flow/sales_order/model/finance_review.dart';
import 'package:ecommerce_b2b/modules/order_flow/sales_order/model/sales_order.dart';
import 'package:ecommerce_b2b/modules/order_flow/sales_order/presentation/widgets/order_block_explanation.dart';
import 'package:ecommerce_b2b/modules/order_flow/sales_order/presentation/widgets/order_details_content.dart';
import 'package:ecommerce_b2b/modules/shared_kernel/model/common/ids/order_id.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

SalesOrder _order({
  OrderStatus status = OrderStatus.blockedByFinance,
  CreditStatus creditStatus = CreditStatus.blocked,
  FinanceReview? financeReview,
}) => SalesOrder(
  id: const OrderId('order-101'),
  status: status,
  creditStatus: creditStatus,
  items: const [],
  financeReview: financeReview,
);

void main() {
  group('OrderBlockExplanation', () {
    test('usa fallback quando o bloqueio por crédito não tem análise', () {
      final explanation = OrderBlockExplanation.fromOrder(_order());

      expect(explanation, isNotNull);
      expect(explanation!.isBlocked, isTrue);
      expect(explanation.hasFinanceReview, isFalse);
      expect(explanation.reason, OrderBlockExplanation.blockedFallbackReason);
      expect(explanation.sourceLabel, 'Política de crédito');
      expect(explanation.reviewerLabel, isNull);
    });

    test('usa a justificativa real da análise financeira', () {
      final review = FinanceReview(
        decision: FinanceDecision.rejected,
        reviewerId: 'finance@test.com',
        reviewerName: 'Financeiro Mock',
        reviewerRole: 'Finance',
        reviewedAt: DateTime.utc(2026, 11, 3, 10, 30),
        justification: 'Limite de crédito insuficiente para o pedido.',
      );
      final explanation = OrderBlockExplanation.fromOrder(
        _order(creditStatus: CreditStatus.rejected, financeReview: review),
      );

      expect(explanation, isNotNull);
      expect(explanation!.hasFinanceReview, isTrue);
      expect(
        explanation.reason,
        'Limite de crédito insuficiente para o pedido.',
      );
      expect(explanation.sourceLabel, 'Análise financeira');
      expect(explanation.decision, FinanceDecision.rejected);
      expect(explanation.reviewerLabel, contains('Financeiro Mock'));
      expect(explanation.reviewedAt, DateTime.utc(2026, 11, 3, 10, 30));
    });

    test('explica também o pedido aguardando informações', () {
      final review = FinanceReview(
        decision: FinanceDecision.requestMoreInfo,
        reviewerId: 'finance@test.com',
        reviewedAt: DateTime.utc(2026, 11, 3),
        justification: 'Solicitado comprovante de faturamento.',
      );
      final explanation = OrderBlockExplanation.fromOrder(
        _order(
          status: OrderStatus.awaitingInfo,
          creditStatus: CreditStatus.approved,
          financeReview: review,
        ),
      );

      expect(explanation, isNotNull);
      expect(explanation!.isBlocked, isFalse);
      expect(explanation.title, 'Informações solicitadas pelo Financeiro');
      expect(explanation.reason, 'Solicitado comprovante de faturamento.');
    });

    test('não gera explicação para pedidos sem bloqueio', () {
      final explanation = OrderBlockExplanation.fromOrder(
        _order(
          status: OrderStatus.pickingPacking,
          creditStatus: CreditStatus.approved,
        ),
      );

      expect(explanation, isNull);
    });
  });

  testWidgets('trigger abre o dialog com a explicação completa', (
    tester,
  ) async {
    final order = _order();

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => Center(
              child: OrderBlockExplanationTrigger(
                order: order,
                child: const Text('BLOQUEADO'),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('BLOQUEADO'));
    await tester.pumpAndSettle();

    expect(find.text('Pedido bloqueado pelo Financeiro'), findsOneWidget);
    expect(
      find.text(OrderBlockExplanation.blockedFallbackReason),
      findsOneWidget,
    );
    expect(find.text('Entendi'), findsOneWidget);
  });

  testWidgets('detalhe do pedido mostra o bloco de motivo do bloqueio', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: OrderDetailsContent(order: _order()),
          ),
        ),
      ),
    );

    expect(find.text('Pedido bloqueado pelo Financeiro'), findsOneWidget);
    expect(
      find.text(OrderBlockExplanation.blockedFallbackReason),
      findsOneWidget,
    );
  });
}
