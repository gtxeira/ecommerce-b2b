/// Status do orçamento.
enum QuoteStatus {
  /// Orçamento criado.
  draft,

  /// Orçamento enviado.
  sent,

  /// Orçamento expirado.
  expired,

  /// Orçamento convertido em pedido.
  convertedToOrder,

  /// Orçamento cancelado.
  cancelled;

  /// Nome de exibição em português.
  String get label => switch (this) {
    QuoteStatus.draft => 'Rascunho',
    QuoteStatus.sent => 'Enviado',
    QuoteStatus.expired => 'Expirado',
    QuoteStatus.convertedToOrder => 'Convertido em Pedido',
    QuoteStatus.cancelled => 'Cancelado',
  };
}
