part of 'order_list_cubit.dart';

/// Ordem de atenção dentro do grupo "abertos": o que está travado ou esperando
/// decisão aparece primeiro.
const Map<OrderStatus, int> _openStatusPriority = {
  OrderStatus.blockedByFinance: 0,
  OrderStatus.pendingFinanceApproval: 1,
  OrderStatus.pickingPacking: 2,
  OrderStatus.inTransit: 3,
};

abstract class OrderListState extends Equatable {
  const OrderListState();

  @override
  List<Object?> get props => [];
}

class OrderListInitial extends OrderListState {}

class OrderListLoading extends OrderListState {}

class OrderListLoaded extends OrderListState {
  final List<SalesOrder> allOrders;
  final Map<String, String> companyNames;
  final OrderStatusGroup filter;
  final String query;

  const OrderListLoaded({
    required this.allOrders,
    required this.companyNames,
    required this.filter,
    required this.query,
  });

  /// Nome fantasia da empresa do pedido, quando conhecido.
  String? companyNameFor(SalesOrder order) => companyNames[order.companyId];

  /// Pedidos do grupo selecionado, filtrados pela busca e ordenados.
  ///
  /// Abertos: prioridade de atenção e, no empate, o mais recente primeiro.
  /// Encerrados: mais recente primeiro.
  List<SalesOrder> get visibleOrders {
    final term = query.trim().toLowerCase();

    final orders = allOrders
        .where((order) => order.status.group == filter)
        .where((order) => term.isEmpty || _matches(order, term))
        .toList();

    orders.sort((a, b) {
      if (filter == OrderStatusGroup.open) {
        final byPriority = (_openStatusPriority[a.status] ?? 99).compareTo(
          _openStatusPriority[b.status] ?? 99,
        );
        if (byPriority != 0) return byPriority;
      }
      return compareSalesOrdersByCreatedAtDesc(a, b);
    });

    return orders;
  }

  bool _matches(SalesOrder order, String term) {
    if (order.id.value.toLowerCase().contains(term)) return true;
    if ((order.companyId ?? '').toLowerCase().contains(term)) return true;
    final name = companyNameFor(order);
    return name != null && name.toLowerCase().contains(term);
  }

  /// Quantos pedidos existem no agrupamento informado (para os contadores).
  ///
  /// Reflete o total do grupo, não o resultado da busca: o contador é contexto,
  /// não um espelho da lista filtrada.
  int countFor(OrderStatusGroup group) =>
      allOrders.where((order) => order.status.group == group).length;

  // O `==` de `SalesOrder` compara apenas o id, então a assinatura inclui o
  // status: sem isso, um pedido que mudou de status não dispararia rebuild.
  @override
  List<Object?> get props => [
    filter,
    query,
    companyNames.length,
    allOrders.map((order) => '${order.id.value}:${order.status.name}').toList(),
  ];
}

class OrderListFailure extends OrderListState {
  final String message;

  const OrderListFailure(this.message);

  @override
  List<Object?> get props => [message];
}
