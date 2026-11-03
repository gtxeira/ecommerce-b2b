part of 'open_orders_cubit.dart';

abstract class OpenOrdersState extends Equatable {
  const OpenOrdersState();

  /// Quantidade de pedidos em aberto conhecida no momento.
  int get count;

  @override
  List<Object?> get props => [count];
}

class OpenOrdersInitial extends OpenOrdersState {
  const OpenOrdersInitial();

  @override
  int get count => 0;
}

class OpenOrdersLoaded extends OpenOrdersState {
  @override
  final int count;

  const OpenOrdersLoaded(this.count);
}

class OpenOrdersFailure extends OpenOrdersState {
  final String message;

  /// Último valor conhecido, preservado para o badge não piscar.
  final int lastCount;

  const OpenOrdersFailure(this.message, {required this.lastCount});

  @override
  int get count => lastCount;

  @override
  List<Object?> get props => [count, message];
}
