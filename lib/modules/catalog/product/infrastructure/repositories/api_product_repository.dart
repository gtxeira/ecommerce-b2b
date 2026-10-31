import 'package:ecommerce_b2b/app/core/network/api_client.dart';
import 'package:ecommerce_b2b/app/core/network/json_read.dart';
import 'package:ecommerce_b2b/modules/catalog/product/domain/product.dart';
import 'package:ecommerce_b2b/modules/catalog/product/domain/product_variant.dart';
import 'package:ecommerce_b2b/modules/catalog/product/domain/repositories/product_repository.dart';
import 'package:ecommerce_b2b/modules/shared_kernel/domain/common/ids/product_id.dart';
import 'package:ecommerce_b2b/modules/shared_kernel/domain/common/ids/product_variant_id.dart';
import 'package:ecommerce_b2b/modules/shared_kernel/domain/finance/value_objects/money.dart';
import 'package:ecommerce_b2b/modules/shared_kernel/domain/logistics/value_objects/weight.dart';

class ApiProductRepository implements ProductRepository {
  final ApiClient _api;

  ApiProductRepository(this._api);

  @override
  Future<List<Product>> getAll() async {
    final data = await _api.get('/api/products');
    if (data is! List) return const [];
    return data
        .whereType<Map>()
        .map((item) => _fromJson(Map<String, dynamic>.from(item)))
        .toList();
  }

  @override
  Future<void> save(Product product) async {
    await _api.post('/api/products', data: _toJson(product));
  }

  @override
  Future<void> delete(ProductId id) async {
    await _api.delete('/api/products/${id.value}');
  }

  @override
  Future<void> deleteVariant(
    ProductId productId,
    ProductVariantId variantId,
  ) async {
    await _api.delete(
      '/api/products/${productId.value}/variants/${variantId.value}',
    );
  }

  Map<String, dynamic> _toJson(Product product) => {
    'id': product.id.value,
    'sku': product.sku,
    'name': product.name,
    'description': product.description,
    'basePrice': product.basePrice.amount,
    'active': product.active,
    'variants': product.variants
        .map(
          (variant) => {
            'id': variant.id.value,
            'color': variant.color,
            'size': variant.size,
            'voltage': variant.voltage,
            'variantSku': variant.variantSku,
            'price': variant.price?.amount,
            'sameAsParent': variant.sameAsParent,
            'weight': variant.weight?.value ?? 0,
          },
        )
        .toList(),
  };

  Product _fromJson(Map<String, dynamic> json) {
    final id = ProductId(readString(json, 'id'));
    final basePrice = Money.create(readDouble(json, 'basePrice')).getOrThrow();

    return Product(
      id: id,
      sku: readString(json, 'sku'),
      name: readString(json, 'name'),
      description: readString(json, 'description'),
      basePrice: basePrice,
      active: readBool(json, 'active', true),
      variants: readMapList(json, 'variants').map(_variantFromJson).toList(),
    );
  }

  ProductVariant _variantFromJson(Map<String, dynamic> json) {
    final price = readNullableDouble(json, 'price');
    final weight = readDouble(json, 'weight');

    return ProductVariant(
      id: ProductVariantId(readString(json, 'id')),
      color: readString(json, 'color'),
      size: readString(json, 'size'),
      voltage: readString(json, 'voltage'),
      variantSku: readString(json, 'variantSku'),
      price: price == null ? null : Money.create(price).getOrThrow(),
      sameAsParent: readBool(json, 'sameAsParent', true),
      weight: Weight.create(weight).getOrThrow(),
    );
  }
}
