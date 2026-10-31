import 'package:ecommerce_b2b/modules/catalog/product/application/get_products/get_products_use_case.dart';
import 'package:ecommerce_b2b/modules/catalog/product/model/product.dart';
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
    test('should delegate to the repository without a query', () async {
      final products = [
        createProduct('1', 'Notebook', 'SKU-001'),
        createProduct('2', 'Monitor', 'SKU-002'),
      ];
      when(
        () => productRepository.getAll(query: null),
      ).thenAnswer((_) async => products);

      final result = await useCase.execute();

      expect(result.isSuccess, isTrue);
      expect(result.getOrThrow(), products);
      verify(() => productRepository.getAll(query: null)).called(1);
    });

    test('should delegate the query to the repository', () async {
      final products = [createProduct('1', 'Notebook', 'SKU-001')];
      when(
        () => productRepository.getAll(query: 'Note'),
      ).thenAnswer((_) async => products);

      final result = await useCase.execute(query: 'Note');

      expect(result.isSuccess, isTrue);
      expect(result.getOrThrow(), products);
      verify(() => productRepository.getAll(query: 'Note')).called(1);
    });
  });
}
