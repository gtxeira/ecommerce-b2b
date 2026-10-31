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

  /// Nome de exibição em português.
  String get label => switch (this) {
    OrderStatus.pendingFinanceApproval => 'Aguardando Aprovação Financeira',
    OrderStatus.blockedByFinance => 'Bloqueado pelo Financeiro',
    OrderStatus.pickingPacking => 'Em Separação e Embalagem',
    OrderStatus.inTransit => 'Em Transporte',
    OrderStatus.delivered => 'Entregue',
    OrderStatus.cancelled => 'Cancelado',
    OrderStatus.rma => 'Devolução / RMA',
    OrderStatus.invoiced => 'Faturado',
  };
}
