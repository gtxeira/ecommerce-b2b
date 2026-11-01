import 'package:ecommerce_b2b/modules/catalog/product/application/delete_product/delete_product_use_case.dart';
import 'package:ecommerce_b2b/modules/catalog/product/application/delete_product_variant/delete_product_variant_use_case.dart';
import 'package:ecommerce_b2b/modules/catalog/product/application/get_products/get_products_use_case.dart';
import 'package:ecommerce_b2b/modules/catalog/product/application/save_product/save_product_use_case.dart';
import 'package:ecommerce_b2b/modules/catalog/product/model/product.dart';
import 'package:ecommerce_b2b/modules/catalog/product/presentation/cubit/catalog_state.dart';
import 'package:ecommerce_b2b/modules/inventory/warehouse/model/repositories/inventory_repository.dart';
import 'package:ecommerce_b2b/modules/inventory/warehouse/model/stock_item.dart';
import 'package:ecommerce_b2b/modules/shared_kernel/model/common/ids/product_id.dart';
import 'package:ecommerce_b2b/modules/shared_kernel/model/common/ids/product_variant_id.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class CatalogCubit extends Cubit<CatalogState> {
  static const int pageSize = 20;

  final GetProductsUseCase _getProductsUseCase;
  final SaveProductUseCase _saveProductUseCase;
  final DeleteProductUseCase _deleteProductUseCase;
  final DeleteProductVariantUseCase _deleteProductVariantUseCase;
  final InventoryRepository _inventoryRepository;

  String? _query;
  int _requestId = 0;

  CatalogCubit(
    this._getProductsUseCase,
    this._saveProductUseCase,
    this._deleteProductUseCase,
    this._deleteProductVariantUseCase,
    this._inventoryRepository,
  ) : super(CatalogInitial());

  Future<void> loadProducts({String? query}) async {
    _query = query == null || query.trim().isEmpty ? null : query.trim();
    final requestId = ++_requestId;
    emit(CatalogLoading());

    final result = await _getProductsUseCase.executePage(
      query: _query,
      page: 1,
      pageSize: pageSize,
    );

    // Uma busca mais nova pode ter começado enquanto esta resposta vinha; nesse caso, descarta.
    if (requestId != _requestId) return;

    // Estoque é complementar: se a chamada falhar, o catálogo ainda aparece.
    var consolidatedStock = const <StockItem>[];
    try {
      consolidatedStock = await _inventoryRepository.getConsolidatedStock();
    } catch (_) {
      consolidatedStock = const <StockItem>[];
    }

    if (requestId != _requestId) return;

    final Map<String, int> stockMap = {
      for (var item in consolidatedStock)
        item.productId.value: item.physicalQuantity.value,
    };

    result.fold(
      (error) => emit(CatalogError(error.toString())),
      (page) => emit(
        CatalogLoaded(
          page.items,
          stockMap: stockMap,
          page: page.page,
          totalItems: page.totalItems,
          totalPages: page.totalPages,
        ),
      ),
    );
  }

  /// Carrega a próxima página e acrescenta ao final, sem limpar o que já está na tela.
  Future<void> loadMore() async {
    final current = state;
    if (current is! CatalogLoaded ||
        current.isLoadingMore ||
        !current.hasMore) {
      return;
    }

    emit(current.copyWith(isLoadingMore: true));

    final requestId = _requestId;
    final result = await _getProductsUseCase.executePage(
      query: _query,
      page: current.page + 1,
      pageSize: pageSize,
    );

    // Uma busca/refresh começou enquanto esta página vinha: a lista atual já é outra.
    if (requestId != _requestId) return;

    result.fold(
      (error) => emit(
        CatalogLoadMoreFailed(
          products: current.products,
          stockMap: current.stockMap,
          page: current.page,
          totalItems: current.totalItems,
          totalPages: current.totalPages,
          message: error.toString(),
        ),
      ),
      (page) {
        final ids = current.products.map((product) => product.id.value).toSet();
        final merged = [
          ...current.products,
          ...page.items.where((product) => ids.add(product.id.value)),
        ];

        emit(
          CatalogLoaded(
            merged,
            stockMap: current.stockMap,
            page: page.page,
            totalItems: page.totalItems,
            totalPages: page.totalPages,
          ),
        );
      },
    );
  }

  Future<void> saveProduct(Product product) async {
    final result = await _saveProductUseCase.execute(product);

    result.fold(
      (error) => emit(CatalogError(error.toString())),
      (_) => loadProducts(query: _query),
    );
  }

  Future<void> deleteProduct(ProductId productId) async {
    final result = await _deleteProductUseCase.execute(productId);

    result.fold((error) => emit(CatalogError(error.toString())), (_) {
      emit(CatalogProductDeleted());
      loadProducts(query: _query);
    });
  }

  Future<void> deleteVariant(
    ProductId productId,
    ProductVariantId variantId,
  ) async {
    final result = await _deleteProductVariantUseCase.execute(
      productId,
      variantId,
    );

    result.fold((error) => emit(CatalogError(error.toString())), (_) {
      emit(CatalogVariantDeleted());
      loadProducts(query: _query);
    });
  }
}
