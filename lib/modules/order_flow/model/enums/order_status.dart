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

  /// Converte o nome devolvido pela API (case-insensitive).
  static OrderStatus fromApi(String value) => switch (value.toLowerCase()) {
    'pendingfinanceapproval' => OrderStatus.pendingFinanceApproval,
    'blockedbyfinance' => OrderStatus.blockedByFinance,
    'pickingpacking' => OrderStatus.pickingPacking,
    'intransit' => OrderStatus.inTransit,
    'delivered' => OrderStatus.delivered,
    'cancelled' => OrderStatus.cancelled,
    'rma' => OrderStatus.rma,
    'invoiced' => OrderStatus.invoiced,
    _ => OrderStatus.pendingFinanceApproval,
  };

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

/// Agrupamento de exibição dos status: o que ainda está em andamento e o que
/// já terminou. Usado pelos filtros da listagem de pedidos.
enum OrderStatusGroup {
  /// Pedido ainda em fluxo (aguardando análise, bloqueado, em separação ou em
  /// transporte).
  open,

  /// Pedido encerrado (entregue, faturado, cancelado ou em RMA).
  closed;

  /// Nome de exibição em português.
  String get label => switch (this) {
    OrderStatusGroup.open => 'Abertos',
    OrderStatusGroup.closed => 'Encerrados',
  };
}

/// Classifica o status do pedido no agrupamento de exibição.
extension OrderStatusGrouping on OrderStatus {
  /// `true` enquanto o pedido ainda está em fluxo operacional.
  bool get isOpen => switch (this) {
    OrderStatus.pendingFinanceApproval ||
    OrderStatus.blockedByFinance ||
    OrderStatus.pickingPacking ||
    OrderStatus.inTransit => true,
    OrderStatus.delivered ||
    OrderStatus.invoiced ||
    OrderStatus.cancelled ||
    OrderStatus.rma => false,
  };

  /// Agrupamento ao qual o status pertence.
  OrderStatusGroup get group =>
      isOpen ? OrderStatusGroup.open : OrderStatusGroup.closed;
}
