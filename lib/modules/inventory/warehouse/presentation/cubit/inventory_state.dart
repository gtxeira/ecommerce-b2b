part of 'inventory_cubit.dart';

abstract class InventoryState extends Equatable {
  const InventoryState();

  @override
  List<Object?> get props => [];
}

class InventoryInitial extends InventoryState {}

class InventoryLoading extends InventoryState {}

class InventoryLoaded extends InventoryState {
  const InventoryLoaded({
    required this.products,
    required this.warehouses,
    required this.consolidatedStock,
  });

  final List<Product> products;
  final List<Warehouse> warehouses;
  final Map<String, int> consolidatedStock;

  @override
  List<Object?> get props => [products, warehouses, consolidatedStock];
}

class InventoryFailure extends InventoryState {
  const InventoryFailure(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}
