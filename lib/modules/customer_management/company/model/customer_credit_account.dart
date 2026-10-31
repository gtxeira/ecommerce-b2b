import 'package:ecommerce_b2b/modules/shared_kernel/model/finance/value_objects/money.dart';

/// Objeto de Valor que representa a conta de crédito de um cliente.
class CustomerCreditAccount {
  /// Limite total pré-aprovado.
  final Money preApprovedLimit;
  /// Saldo devedor atual (faturas já emitidas e não pagas).
  final Money openBalance;
  /// Valor total de pedidos em processamento (faturamento pendente).
  final Money pendingOrdersBalance;

  const CustomerCreditAccount({
    required this.preApprovedLimit,
    required this.openBalance,
    required this.pendingOrdersBalance,
  });

  /// Calcula o limite disponível real.
  /// Subtrai do limite total o saldo devedor e os pedidos pendentes (RN10).
  Money get availableLimit {
    try {
      return preApprovedLimit - (openBalance + pendingOrdersBalance);
    } on StateError {
      // Se o saldo devedor + pendentes for maior que o limite, retorna 0.
      return Money.create(0, currency: preApprovedLimit.currency).getOrThrow();
    }
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CustomerCreditAccount &&
          runtimeType == other.runtimeType &&
          preApprovedLimit == other.preApprovedLimit &&
          openBalance == other.openBalance &&
          pendingOrdersBalance == other.pendingOrdersBalance;

  @override
  int get hashCode =>
      preApprovedLimit.hashCode ^
      openBalance.hashCode ^
      pendingOrdersBalance.hashCode;
}
