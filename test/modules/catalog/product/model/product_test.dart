import 'package:ecommerce_b2b/modules/catalog/product/model/product.dart';
import 'package:ecommerce_b2b/modules/catalog/product/model/product_variant.dart';
import 'package:ecommerce_b2b/modules/shared_kernel/model/common/ids/product_id.dart';
import 'package:ecommerce_b2b/modules/shared_kernel/model/common/ids/product_variant_id.dart';
import 'package:ecommerce_b2b/modules/shared_kernel/model/finance/value_objects/money.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Product Aggregate', () {
    test('should add variant correctly', () {
      final product = Product(
        id: const ProductId('p1'),
        sku: 'SKU-001',
        name: 'Product 1',
        description: 'Description 1',
        basePrice: Money.create(100).getOrThrow(),
        active: true,
      );

      final variant = ProductVariant(
        id: const ProductVariantId('v1'),
        variantSku: 'SKU-001-RED',
        color: 'Red',
        size: 'G',
        voltage: 'N/A',
        sameAsParent: true,
      );

      product.addVariant(variant);

      expect(product.variants, hasLength(1));
      expect(product.variants.first.variantSku, 'SKU-001-RED');
    });

    test('variants list should be unmodifiable from outside', () {
      final product = Product(
        id: const ProductId('p1'),
        sku: 'SKU-001',
        name: 'Product 1',
        description: 'Description 1',
        basePrice: Money.create(100).getOrThrow(),
        active: true,
      );

      expect(
        () => product.variants.add(
          ProductVariant(
            id: const ProductVariantId('v1'),
            variantSku: 'V1',
            color: '',
            size: '',
            voltage: '',
          ),
        ),
        throwsUnsupportedError,
      );
    });

    test('should remove variant by ID correctly', () {
      final product = Product(
        id: const ProductId('p1'),
        sku: 'SKU-001',
        name: 'Product 1',
        description: 'Description 1',
        basePrice: Money.create(100).getOrThrow(),
        active: true,
        variants: [
          ProductVariant(
            id: const ProductVariantId('v1'),
            variantSku: 'SKU-001-RED',
            color: 'Red',
            size: 'G',
            voltage: 'N/A',
          ),
          ProductVariant(
            id: const ProductVariantId('v2'),
            variantSku: 'SKU-001-BLUE',
            color: 'Blue',
            size: 'M',
            voltage: 'N/A',
          ),
        ],
      );

      final removed = product.removeVariant(const ProductVariantId('v1'));

      expect(removed, isTrue);
      expect(product.variants, hasLength(1));
      expect(product.variants.first.id, const ProductVariantId('v2'));
    });

    test('removeVariant should return false when variant does not exist', () {
      final product = Product(
        id: const ProductId('p1'),
        sku: 'SKU-001',
        name: 'Product 1',
        description: 'Description 1',
        basePrice: Money.create(100).getOrThrow(),
        active: true,
      );

      final removed = product.removeVariant(
        const ProductVariantId('non-existent'),
      );

      expect(removed, isFalse);
      expect(product.variants, isEmpty);
    });
  });
}
