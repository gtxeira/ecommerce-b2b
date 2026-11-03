part of 'order_list_cubit.dart';

/// Ordem de atenção dentro do grupo "abertos": o que está travado ou esperando
/// decisão aparece primeiro. `closed` mantém a ordem devolvida pela API, já que
/// o pedido não carrega data de criação.
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
  final OrderStatusGroup filter;

  const OrderListLoaded({required this.allOrders, required this.filter});

  /// Pedidos do grupo selecionado, já ordenados para exibição.
  List<SalesOrder> get visibleOrders {
    final orders = allOrders
        .where((order) => order.status.group == filter)
        .toList();

    if (filter == OrderStatusGroup.open) {
      orders.sort(
        (a, b) => (_openStatusPriority[a.status] ?? 99).compareTo(
          _openStatusPriority[b.status] ?? 99,
        ),
      );
    }

    return orders;
  }

  /// Quantos pedidos existem no agrupamento informado (para os contadores).
  int countFor(OrderStatusGroup group) =>
      allOrders.where((order) => order.status.group == group).length;

  // O `==` de `SalesOrder` compara apenas o id, então a assinatura inclui o
  // status: sem isso, um pedido que mudou de status não dispararia rebuild.
  @override
  List<Object?> get props => [
    filter,
    allOrders.map((order) => '${order.id.value}:${order.status.name}').toList(),
  ];
}

class OrderListFailure extends OrderListState {
  final String message;

  const OrderListFailure(this.message);

  @override
  List<Object?> get props => [message];
}
