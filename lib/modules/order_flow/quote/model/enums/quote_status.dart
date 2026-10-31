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
}
