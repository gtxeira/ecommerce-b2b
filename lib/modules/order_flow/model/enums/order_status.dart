/// Status do pedido.
enum OrderStatus {
  /// Pedido aguardando aprovação financeira.
  pendingFinanceApproval,
  /// Pedido bloqueado pelo departamento financeiro.
  blockedByFinance,
  /// Pedido aguardando separação/expedição.
  pickingPacking,
  /// Pedido em trânsito.
  inTransit,
  /// Pedido entregue.
  delivered,
  /// Pedido cancelado.
  cancelled,
  /// Pedido em RMA.
  rma,
  /// Pedido faturado (a comissão do representante nasce aqui).
  invoiced;
}
