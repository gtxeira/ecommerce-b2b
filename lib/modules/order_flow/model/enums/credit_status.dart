/// Status de crédito do pedido.
enum CreditStatus {
  /// Pedido aprovado.
  approved,

  /// Pedido em análise.
  pending,

  /// Pedido recusado.
  rejected,

  /// Pedido bloqueado.
  blocked;

  /// Nome de exibição em português.
  String get label => switch (this) {
    CreditStatus.approved => 'Aprovado',
    CreditStatus.pending => 'Pendente',
    CreditStatus.rejected => 'Reprovado',
    CreditStatus.blocked => 'Bloqueado',
  };
}
