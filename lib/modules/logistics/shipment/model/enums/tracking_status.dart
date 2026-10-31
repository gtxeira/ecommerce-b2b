/// Status de rastreamento de encomenda.
enum TrackingStatus {
  /// Coletado
  pickedUp,
  /// Em separação (No depósito)
  atTerminal,
  /// Em trânsito (No transporte)
  inTransit,
  /// Em rota de entrega
  outForDelivery,
  /// Entregue
  delivered,
  /// Falha na entrega
  failedAttempt;
}
