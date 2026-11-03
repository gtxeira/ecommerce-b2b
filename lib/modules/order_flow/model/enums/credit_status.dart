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

  /// Converte o nome devolvido pela API (case-insensitive).
  static CreditStatus fromApi(String value) => switch (value.toLowerCase()) {
    'approved' => CreditStatus.approved,
    'rejected' => CreditStatus.rejected,
    'blocked' => CreditStatus.blocked,
    _ => CreditStatus.pending,
  };

  /// Nome de exibição em português.
  String get label => switch (this) {
    CreditStatus.approved => 'Aprovado',
    CreditStatus.pending => 'Pendente',
    CreditStatus.rejected => 'Reprovado',
    CreditStatus.blocked => 'Bloqueado',
  };
}
