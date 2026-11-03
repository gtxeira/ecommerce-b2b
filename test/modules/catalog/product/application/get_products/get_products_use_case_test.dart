import 'package:ecommerce_b2b/modules/catalog/product/application/get_products/get_products_use_case.dart';
import 'package:ecommerce_b2b/modules/catalog/product/model/product.dart';
import 'package:ecommerce_b2b/modules/catalog/product/model/product_page.dart';
import 'package:ecommerce_b2b/modules/catalog/product/model/repositories/product_repository.dart';
import 'package:ecommerce_b2b/modules/shared_kernel/model/common/ids/product_id.dart';
import 'package:ecommerce_b2b/modules/shared_kernel/model/finance/value_objects/money.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockProductRepository extends Mock implements ProductRepository {}

void main() {
  late MockProductRepository productRepository;
  late GetProductsUseCase useCase;

  setUp(() {
    productRepository = MockProductRepository();
    useCase = GetProductsUseCase(productRepository);
  });

  Product createProduct(String id, String name, String sku) {
    return Product(
      id: ProductId(id),
      name: name,
      sku: sku,
      description: 'Desc $name',
      active: true,
      basePrice: Money.create(100.0).getOrThrow(),
    );
  }

  group('GetProductsUseCase', () {
    test('should delegate executePage with page and pageSize', () async {
      final page = ProductPage(
        items: [createProduct('1', 'Notebook', 'SKU-001')],
        page: 2,
        pageSize: 10,
        totalItems: 11,
        totalPages: 2,
      );
      when(
        () => productRepository.getPage(query: 'Note', page: 2, pageSize: 10),
      ).thenAnswer((_) async => page);

      final result = await useCase.executePage(
        query: 'Note',
        page: 2,
        pageSize: 10,
      );

      expect(result.isSuccess, isTrue);
      expect(result.getOrThrow(), same(page));
      verify(
        () => productRepository.getPage(query: 'Note', page: 2, pageSize: 10),
      ).called(1);
    });

    test('should use the defaults when executePage has no arguments', () async {
      final page = ProductPage(
        items: const [],
        page: 1,
        pageSize: 20,
        totalItems: 0,
        totalPages: 0,
      );
      when(
        () => productRepository.getPage(query: null, page: 1, pageSize: 20),
      ).thenAnswer((_) async => page);

      final result = await useCase.executePage();

      expect(result.isSuccess, isTrue);
      verify(
        () => productRepository.getPage(query: null, page: 1, pageSize: 20),
      ).called(1);
    });
  });
}
