/// Status do pedido de RMA (Request for a Return).
enum RmaStatus {
  pending,
  authorized,
  received,
  inspected,
  completed,
  rejected;

  /// Nome de exibição em português.
  String get label => switch (this) {
    RmaStatus.pending => 'Solicitado',
    RmaStatus.authorized => 'Autorizado',
    RmaStatus.received => 'Recebido',
    RmaStatus.inspected => 'Em Inspeção',
    RmaStatus.completed => 'Concluído',
    RmaStatus.rejected => 'Rejeitado',
  };
}
