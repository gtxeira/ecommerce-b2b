import 'dart:async';

import 'package:ecommerce_b2b/app/core/events/order_events.dart';
import 'package:ecommerce_b2b/modules/order_flow/model/enums/order_status.dart';
import 'package:ecommerce_b2b/modules/order_flow/sales_order/model/repositories/sales_order_repository.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

part 'open_orders_state.dart';

/// Contador de pedidos em aberto, compartilhado pela navegação e pela home.
///
/// Vive fora das telas (criado no `MyApp`) porque o badge precisa sobreviver à
/// navegação. Relê quando o login acontece e quando `OrderEvents` avisa que
/// algum pedido mudou — as listas continuam recarregando ao montar, por isso
/// elas não escutam o evento.
class OpenOrdersCubit extends Cubit<OpenOrdersState> {
  final SalesOrderRepository _orderRepository;
  final OrderEvents _orderEvents;

  StreamSubscription<void>? _subscription;

  OpenOrdersCubit(this._orderRepository, this._orderEvents)
    : super(const OpenOrdersInitial()) {
    _subscription = _orderEvents.onChanged.listen((_) => load());
  }

  Future<void> load() async {
    try {
      final orders = await _orderRepository.getAll();
      emit(
        OpenOrdersLoaded(orders.where((order) => order.status.isOpen).length),
      );
    } catch (error) {
      // Contador desatualizado é melhor que badge quebrado: mantém o último
      // valor e expõe a falha só para quem quiser observar.
      emit(OpenOrdersFailure(error.toString(), lastCount: state.count));
    }
  }

  /// Zera o contador (logout ou sessão de comprador, que não usa a navegação).
  void clear() => emit(const OpenOrdersInitial());

  @override
  Future<void> close() async {
    await _subscription?.cancel();
    return super.close();
  }
}
