import 'package:ecommerce_b2b/modules/catalog/price_table/model/price_table.dart';
import 'package:equatable/equatable.dart';

sealed class PriceTableState extends Equatable {
  const PriceTableState();
  @override
  List<Object?> get props => [];
}

class PriceTableInitial extends PriceTableState {}

class PriceTableLoading extends PriceTableState {}

class PriceTableLoaded extends PriceTableState {
  final List<PriceTable> tables;
  const PriceTableLoaded(this.tables);
  @override
  List<Object?> get props => [tables];
}

class PriceTableError extends PriceTableState {
  final String message;
  const PriceTableError(this.message);
  @override
  List<Object?> get props => [message];
}
