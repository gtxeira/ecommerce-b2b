import 'package:ecommerce_b2b/modules/catalog/product/model/product.dart';
import 'package:equatable/equatable.dart';

sealed class CatalogState extends Equatable {
  const CatalogState();

  @override
  List<Object?> get props => [];
}

class CatalogInitial extends CatalogState {}

class CatalogLoading extends CatalogState {}

class CatalogLoaded extends CatalogState {
  final List<Product> products;
  final Map<String, int> stockMap;

  const CatalogLoaded(this.products, {this.stockMap = const {}});

  @override
  List<Object?> get props => [products, stockMap];
}

class CatalogError extends CatalogState {
  final String message;

  const CatalogError(this.message);

  @override
  List<Object?> get props => [message];
}

/// Estado emitido quando um produto é excluído com sucesso.
class CatalogProductDeleted extends CatalogState {}

/// Estado emitido quando uma variante é excluída com sucesso.
class CatalogVariantDeleted extends CatalogState {}
