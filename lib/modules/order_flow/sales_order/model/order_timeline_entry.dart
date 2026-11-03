import 'package:ecommerce_b2b/app/core/format/display_labels.dart';
import 'package:ecommerce_b2b/app/core/network/json_read.dart';
import 'package:ecommerce_b2b/modules/order_flow/model/enums/credit_status.dart';
import 'package:ecommerce_b2b/modules/order_flow/model/enums/order_status.dart';
import 'package:ecommerce_b2b/modules/order_flow/sales_order/model/enums/finance_decision.dart';

/// Tipo de evento do histórico do pedido.
enum OrderTimelineEventType {
  /// Pedido criado (com o status e o crédito iniciais).
  created,

  /// Transição de status.
  statusChanged,

  /// Decisão da análise financeira.
  financeReviewed,

  /// Tipo desconhecido, para um contrato mais novo que este app.
  unknown;

  static OrderTimelineEventType fromApi(String value) =>
      switch (value.toLowerCase()) {
        'created' => OrderTimelineEventType.created,
        'statuschanged' => OrderTimelineEventType.statusChanged,
        'financereviewed' => OrderTimelineEventType.financeReviewed,
        _ => OrderTimelineEventType.unknown,
      };
}

/// Um fato da vida do pedido, como devolvido por
/// `GET /api/orders/{id}/timeline`.
///
/// O contrato não carrega texto pronto: o rótulo é composto aqui, a partir dos
/// enums, para o idioma ficar só no app.
class OrderTimelineEntry {
  final String id;

  /// Momento do evento, em UTC. `null` em payload inesperado.
  final DateTime? occurredAt;
  final OrderTimelineEventType type;
  final OrderStatus? fromStatus;
  final OrderStatus? toStatus;
  final CreditStatus? toCreditStatus;
  final FinanceDecision? decision;
  final String? actorId;
  final String? actorRole;

  /// Nome do ator congelado no momento do evento. Nulo em eventos do sistema ou
  /// anteriores ao snapshot.
  final String? actorName;

  final String? note;

  const OrderTimelineEntry({
    required this.id,
    required this.type,
    this.occurredAt,
    this.fromStatus,
    this.toStatus,
    this.toCreditStatus,
    this.decision,
    this.actorId,
    this.actorRole,
    this.actorName,
    this.note,
  });

  factory OrderTimelineEntry.fromJson(Map<String, dynamic> json) =>
      OrderTimelineEntry(
        id: readString(json, 'id'),
        occurredAt: readDate(json, 'occurredAt'),
        type: OrderTimelineEventType.fromApi(readString(json, 'type')),
        fromStatus: _status(json['fromStatus']),
        toStatus: _status(json['toStatus']),
        toCreditStatus: _credit(json['toCreditStatus']),
        decision: _decision(json['decision']),
        actorId: readNullableString(json, 'actorId'),
        actorRole: readNullableString(json, 'actorRole'),
        actorName: readNullableString(json, 'actorName'),
        note: readNullableString(json, 'note'),
      );

  /// Título legível do evento.
  String get title => switch (type) {
    OrderTimelineEventType.created => 'Pedido criado',
    OrderTimelineEventType.statusChanged =>
      '${fromStatus?.label ?? '—'} → ${toStatus?.label ?? '—'}',
    OrderTimelineEventType.financeReviewed =>
      'Análise financeira: ${decision?.label ?? '—'}',
    OrderTimelineEventType.unknown => 'Evento do pedido',
  };

  /// Quem realizou o evento: `Nome (Papel) · #id`, com fallback para papel + ID
  /// quando o nome não foi congelado. Eventos do sistema aparecem como "Sistema".
  String? get actorLabel {
    final id = actorId;
    final hasName = actorName != null && actorName!.isNotEmpty;
    if (id == null || id.isEmpty) {
      return hasName ? actorName : displayRole(actorRole);
    }
    return personLabel(name: actorName, role: actorRole, id: id);
  }

  /// Linha secundária do cartão: data, crédito (na criação) e observação.
  String get details {
    final parts = <String>[
      if (toCreditStatus != null) 'Crédito: ${toCreditStatus!.label}',
      if (note != null && note!.isNotEmpty) note!,
    ];
    return parts.join(' · ');
  }

  static OrderStatus? _status(dynamic value) =>
      value is String && value.isNotEmpty ? OrderStatus.fromApi(value) : null;

  static CreditStatus? _credit(dynamic value) =>
      value is String && value.isNotEmpty ? CreditStatus.fromApi(value) : null;

  static FinanceDecision? _decision(dynamic value) =>
      value is String && value.isNotEmpty
      ? FinanceDecision.fromApi(value)
      : null;
}
