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
  final int page;
  final int totalItems;
  final int totalPages;
  final bool isLoadingMore;

  const CatalogLoaded(
    this.products, {
    this.stockMap = const {},
    this.page = 1,
    this.totalItems = 0,
    this.totalPages = 0,
    this.isLoadingMore = false,
  });

  bool get hasMore => page < totalPages;

  CatalogLoaded copyWith({
    List<Product>? products,
    Map<String, int>? stockMap,
    int? page,
    int? totalItems,
    int? totalPages,
    bool? isLoadingMore,
  }) => CatalogLoaded(
    products ?? this.products,
    stockMap: stockMap ?? this.stockMap,
    page: page ?? this.page,
    totalItems: totalItems ?? this.totalItems,
    totalPages: totalPages ?? this.totalPages,
    isLoadingMore: isLoadingMore ?? this.isLoadingMore,
  );

  @override
  List<Object?> get props => [
    products,
    stockMap,
    page,
    totalItems,
    totalPages,
    isLoadingMore,
  ];
}

/// Falha ao carregar a próxima página: mantém o que já está na tela e permite tentar de novo.
class CatalogLoadMoreFailed extends CatalogLoaded {
  final String message;

  const CatalogLoadMoreFailed({
    required List<Product> products,
    Map<String, int> stockMap = const {},
    int page = 1,
    int totalItems = 0,
    int totalPages = 0,
    bool isLoadingMore = false,
    required this.message,
  }) : super(
         products,
         stockMap: stockMap,
         page: page,
         totalItems: totalItems,
         totalPages: totalPages,
         isLoadingMore: isLoadingMore,
       );

  @override
  List<Object?> get props => [...super.props, message];
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
