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
  final GetProductsUseCase _getProductsUseCase;
  final SaveProductUseCase _saveProductUseCase;
  final DeleteProductUseCase _deleteProductUseCase;
  final DeleteProductVariantUseCase _deleteProductVariantUseCase;
  final InventoryRepository _inventoryRepository;

  CatalogCubit(
    this._getProductsUseCase,
    this._saveProductUseCase,
    this._deleteProductUseCase,
    this._deleteProductVariantUseCase,
    this._inventoryRepository,
  ) : super(CatalogInitial());

  Future<void> loadProducts({String? query}) async {
    emit(CatalogLoading());
    final result = await _getProductsUseCase.execute(query: query);

    // Estoque é complementar: se a chamada falhar, o catálogo ainda aparece.
    var consolidatedStock = const <StockItem>[];
    try {
      consolidatedStock = await _inventoryRepository.getConsolidatedStock();
    } catch (_) {
      consolidatedStock = const <StockItem>[];
    }

    final Map<String, int> stockMap = {
      for (var item in consolidatedStock)
        item.productId.value: item.physicalQuantity.value,
    };

    result.fold(
      (error) => emit(CatalogError(error.toString())),
      (products) => emit(CatalogLoaded(products, stockMap: stockMap)),
    );
  }

  Future<void> saveProduct(Product product) async {
    final result = await _saveProductUseCase.execute(product);

    result.fold(
      (error) => emit(CatalogError(error.toString())),
      (_) => loadProducts(),
    );
  }

  Future<void> deleteProduct(ProductId productId) async {
    final result = await _deleteProductUseCase.execute(productId);

    result.fold((error) => emit(CatalogError(error.toString())), (_) {
      emit(CatalogProductDeleted());
      loadProducts();
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
      loadProducts();
    });
  }
}
