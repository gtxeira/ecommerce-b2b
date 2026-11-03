import 'package:ecommerce_b2b/modules/order_flow/model/enums/credit_status.dart';
import 'package:ecommerce_b2b/modules/order_flow/model/enums/order_status.dart';
import 'package:ecommerce_b2b/modules/order_flow/sales_order/model/enums/finance_decision.dart';
import 'package:ecommerce_b2b/modules/order_flow/sales_order/model/order_timeline_entry.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('OrderTimelineEntry.fromJson', () {
    test('mapeia o evento de criação', () {
      final entry = OrderTimelineEntry.fromJson({
        'id': 'e1',
        'occurredAt': '2026-09-20T10:00:00.000+00:00',
        'type': 'Created',
        'fromStatus': null,
        'toStatus': 'PendingFinanceApproval',
        'toCreditStatus': 'Approved',
        'decision': null,
        'actorId': null,
        'actorRole': 'System',
        'note': null,
      });

      expect(entry.type, OrderTimelineEventType.created);
      expect(entry.occurredAt, DateTime.utc(2026, 9, 20, 10));
      expect(entry.fromStatus, isNull);
      expect(entry.toStatus, OrderStatus.pendingFinanceApproval);
      expect(entry.toCreditStatus, CreditStatus.approved);
      expect(entry.title, 'Pedido criado');
      expect(entry.details, 'Crédito: Aprovado');
      expect(entry.actorLabel, 'Sistema');
    });

    test('mapeia uma transição de status com ator', () {
      final entry = OrderTimelineEntry.fromJson({
        'id': 'e2',
        'occurredAt': '2026-09-21T11:00:00.000+00:00',
        'type': 'StatusChanged',
        'fromStatus': 'PendingFinanceApproval',
        'toStatus': 'PickingPacking',
        'actorId': 'finance@test.com',
        'actorRole': 'Finance',
      });

      expect(entry.type, OrderTimelineEventType.statusChanged);
      expect(entry.fromStatus, OrderStatus.pendingFinanceApproval);
      expect(entry.toStatus, OrderStatus.pickingPacking);
      expect(
        entry.title,
        'Aguardando Aprovação Financeira → Em Separação e Embalagem',
      );
      expect(entry.actorLabel, 'Financeiro · finance');
    });

    test('mapeia a análise financeira com decisão e justificativa', () {
      final entry = OrderTimelineEntry.fromJson({
        'id': 'e3',
        'occurredAt': '2026-09-21T09:00:00.000+00:00',
        'type': 'FinanceReviewed',
        'decision': 'Rejected',
        'actorId': 'fin-1',
        'actorRole': 'Finance',
        'note': 'Limite insuficiente',
      });

      expect(entry.type, OrderTimelineEventType.financeReviewed);
      expect(entry.decision, FinanceDecision.rejected);
      expect(entry.title, 'Análise financeira: Reprovado');
      expect(entry.details, 'Limite insuficiente');
      expect(entry.actorLabel, 'Financeiro · fin-1');
    });

    test('tipo desconhecido cai no fallback sem derrubar o parsing', () {
      final entry = OrderTimelineEntry.fromJson({
        'id': 'e4',
        'type': 'SomethingNew',
        'occurredAt': 'not-a-date',
      });

      expect(entry.type, OrderTimelineEventType.unknown);
      expect(entry.occurredAt, isNull);
      expect(entry.title, 'Evento do pedido');
      expect(entry.actorLabel, isNull);
    });
  });
}
