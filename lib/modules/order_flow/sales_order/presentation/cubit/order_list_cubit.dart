import 'package:ecommerce_b2b/modules/order_flow/model/enums/order_status.dart';
import 'package:ecommerce_b2b/modules/order_flow/sales_order/model/repositories/sales_order_repository.dart';
import 'package:ecommerce_b2b/modules/order_flow/sales_order/model/sales_order.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

part 'order_list_state.dart';

/// Lista de pedidos separada por situação (abertos x encerrados).
///
/// A API só aceita um `status` por consulta, então a carga é feita uma única vez
/// com `getAll()` (já escopada por papel no backend) e o recorte é local.
class OrderListCubit extends Cubit<OrderListState> {
  final SalesOrderRepository _orderRepository;

  OrderStatusGroup _filter;

  OrderListCubit(
    this._orderRepository, {
    OrderStatusGroup initialFilter = OrderStatusGroup.open,
  }) : _filter = initialFilter,
       super(OrderListInitial());

  Future<void> load() async {
    emit(OrderListLoading());
    try {
      final orders = await _orderRepository.getAll();
      emit(OrderListLoaded(allOrders: orders, filter: _filter));
    } catch (e) {
      emit(OrderListFailure(e.toString()));
    }
  }

  void setFilter(OrderStatusGroup group) {
    _filter = group;
    final current = state;
    if (current is OrderListLoaded) {
      emit(OrderListLoaded(allOrders: current.allOrders, filter: group));
    }
  }
}
