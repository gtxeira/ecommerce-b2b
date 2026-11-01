import 'package:ecommerce_b2b/app/core/result/result.dart';
import 'package:ecommerce_b2b/modules/catalog/product/application/delete_product/delete_product_use_case.dart';
import 'package:ecommerce_b2b/modules/catalog/product/application/delete_product_variant/delete_product_variant_use_case.dart';
import 'package:ecommerce_b2b/modules/catalog/product/application/get_products/get_products_use_case.dart';
import 'package:ecommerce_b2b/modules/catalog/product/application/save_product/save_product_use_case.dart';
import 'package:ecommerce_b2b/modules/catalog/product/model/product.dart';
import 'package:ecommerce_b2b/modules/catalog/product/model/product_page.dart';
import 'package:ecommerce_b2b/modules/catalog/product/presentation/cubit/catalog_cubit.dart';
import 'package:ecommerce_b2b/modules/catalog/product/presentation/cubit/catalog_state.dart';
import 'package:ecommerce_b2b/modules/inventory/warehouse/model/repositories/inventory_repository.dart';
import 'package:ecommerce_b2b/modules/inventory/warehouse/model/stock_item.dart';
import 'package:ecommerce_b2b/modules/shared_kernel/model/common/ids/product_id.dart';
import 'package:ecommerce_b2b/modules/shared_kernel/model/finance/value_objects/money.dart';
import 'package:ecommerce_b2b/modules/shared_kernel/model/finance/value_objects/quantity.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockGetProductsUseCase extends Mock implements GetProductsUseCase {}

class MockSaveProductUseCase extends Mock implements SaveProductUseCase {}

class MockDeleteProductUseCase extends Mock implements DeleteProductUseCase {}

class MockDeleteProductVariantUseCase extends Mock
    implements DeleteProductVariantUseCase {}

class MockInventoryRepository extends Mock implements InventoryRepository {}

void main() {
  late MockGetProductsUseCase getProducts;
  late MockInventoryRepository inventory;
  late CatalogCubit cubit;

  Product createProduct(String id, String name) => Product(
    id: ProductId(id),
    name: name,
    sku: 'SKU-$id',
    description: 'Desc $name',
    active: true,
    basePrice: Money.create(10.0).getOrThrow(),
  );

  ProductPage page(
    List<Product> items, {
    required int page,
    required int totalPages,
  }) => ProductPage(
    items: items,
    page: page,
    pageSize: 20,
    totalItems: totalPages * 2,
    totalPages: totalPages,
  );

  setUp(() {
    getProducts = MockGetProductsUseCase();
    inventory = MockInventoryRepository();

    when(() => inventory.getConsolidatedStock()).thenAnswer(
      (_) async => [
        StockItem(
          productId: const ProductId('p1'),
          physicalQuantity: Quantity.create(7).getOrThrow(),
        ),
      ],
    );

    cubit = CatalogCubit(
      getProducts,
      MockSaveProductUseCase(),
      MockDeleteProductUseCase(),
      MockDeleteProductVariantUseCase(),
      inventory,
    );
  });

  tearDown(() {
    cubit.close();
  });

  group('CatalogCubit', () {
    test('loadProducts should emit Loading and then the first page', () async {
      when(
        () => getProducts.executePage(query: null, page: 1, pageSize: 20),
      ).thenAnswer(
        (_) async => Success(
          page(
            [createProduct('p1', 'Furadeira'), createProduct('p2', 'Serra')],
            page: 1,
            totalPages: 2,
          ),
        ),
      );

      final states = expectLater(
        cubit.stream,
        emitsInOrder([
          isA<CatalogLoading>(),
          isA<CatalogLoaded>()
              .having((state) => state.products.length, 'products', 2)
              .having((state) => state.totalItems, 'totalItems', 4)
              .having((state) => state.hasMore, 'hasMore', isTrue)
              .having((state) => state.stockMap['p1'], 'stock', 7),
        ]),
      );

      await cubit.loadProducts();

      await states;
    });

    test('loadMore should append and deduplicate the next page', () async {
      when(
        () => getProducts.executePage(query: null, page: 1, pageSize: 20),
      ).thenAnswer(
        (_) async => Success(
          page(
            [createProduct('p1', 'Furadeira'), createProduct('p2', 'Serra')],
            page: 1,
            totalPages: 2,
          ),
        ),
      );
      when(
        () => getProducts.executePage(query: null, page: 2, pageSize: 20),
      ).thenAnswer(
        (_) async => Success(
          page(
            [createProduct('p2', 'Serra'), createProduct('p3', 'Lixadeira')],
            page: 2,
            totalPages: 2,
          ),
        ),
      );

      await cubit.loadProducts();
      await cubit.loadMore();

      final loaded = cubit.state as CatalogLoaded;
      expect(loaded.page, 2);
      expect(loaded.products.map((p) => p.id.value), ['p1', 'p2', 'p3']);
      expect(loaded.hasMore, isFalse);
    });

    test('loadProducts should emit CatalogError when the API fails', () async {
      when(
        () => getProducts.executePage(query: null, page: 1, pageSize: 20),
      ).thenAnswer((_) async => Failure(Exception('sem conexão')));

      await cubit.loadProducts();

      expect(cubit.state, isA<CatalogError>());
    });

    test('loadMore should keep the list when the next page fails', () async {
      when(
        () => getProducts.executePage(query: null, page: 1, pageSize: 20),
      ).thenAnswer(
        (_) async => Success(
          page([createProduct('p1', 'Furadeira')], page: 1, totalPages: 2),
        ),
      );
      when(
        () => getProducts.executePage(query: null, page: 2, pageSize: 20),
      ).thenAnswer((_) async => Failure(Exception('falhou')));

      await cubit.loadProducts();
      await cubit.loadMore();

      final failed = cubit.state as CatalogLoadMoreFailed;
      expect(failed.products.map((p) => p.id.value), ['p1']);
      expect(failed.message, contains('falhou'));
    });
  });
}
