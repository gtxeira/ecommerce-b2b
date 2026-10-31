import 'package:dio/dio.dart';
import 'package:ecommerce_b2b/app/core/network/api_client.dart';
import 'package:ecommerce_b2b/app/core/network/session_events.dart';
import 'package:ecommerce_b2b/app/core/network/token_store.dart';
import 'package:ecommerce_b2b/modules/catalog/product/domain/product.dart';
import 'package:ecommerce_b2b/modules/catalog/product/domain/product_variant.dart';
import 'package:ecommerce_b2b/modules/catalog/product/infrastructure/repositories/api_product_repository.dart';
import 'package:ecommerce_b2b/modules/shared_kernel/domain/common/ids/product_id.dart';
import 'package:ecommerce_b2b/modules/shared_kernel/domain/common/ids/product_variant_id.dart';
import 'package:ecommerce_b2b/modules/shared_kernel/domain/finance/value_objects/money.dart';
import 'package:ecommerce_b2b/modules/shared_kernel/domain/logistics/value_objects/weight.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../../support/fake_http_adapter.dart';

void main() {
  late SessionEvents events;

  ApiProductRepository buildRepository(FakeHttpAdapter adapter) {
    final dio = Dio()..httpClientAdapter = adapter;
    final client = ApiClient(
      baseUrl: 'http://localhost:5143',
      dio: dio,
      refreshDio: dio,
      tokenStore: InMemoryTokenStore(),
      sessionEvents: events,
    );
    return ApiProductRepository(client);
  }

  setUp(() => events = SessionEvents());
  tearDown(() => events.dispose());

  group('ApiProductRepository', () {
    test(
      'should map products, variants and weight from the envelope',
      () async {
        final adapter = FakeHttpAdapter(
          (options) async => jsonResponse(
            successEnvelope([
              {
                'id': 'p1',
                'sku': 'SKU-1',
                'name': 'Furadeira',
                'description': '750W',
                'basePrice': 349.90,
                'active': true,
                'variants': [
                  {
                    'id': 'v1',
                    'color': 'Preto',
                    'size': 'M',
                    'voltage': '220V',
                    'variantSku': 'SKU-1-PT',
                    'price': 379.90,
                    'sameAsParent': false,
                    'weight': 2.4,
                  },
                ],
              },
            ]),
          ),
        );
        final repository = buildRepository(adapter);

        final products = await repository.getAll();

        final product = products.single;
        expect(product.id.value, 'p1');
        expect(product.basePrice.amount, 349.90);
        final variant = product.variants.single;
        expect(variant.weight!.value, 2.4);
        expect(variant.price!.amount, 379.90);
      },
    );

    test('should send product and variants to POST /api/products', () async {
      Map<String, dynamic>? body;
      final adapter = FakeHttpAdapter((options) async {
        body = Map<String, dynamic>.from(options.data as Map);
        return jsonResponse(successEnvelope(body), statusCode: 201);
      });
      final repository = buildRepository(adapter);

      final product = Product(
        id: const ProductId('p1'),
        sku: 'SKU-1',
        name: 'Produto',
        description: 'Desc',
        basePrice: Money.create(10.5).getOrThrow(),
        active: true,
        variants: [
          ProductVariant(
            id: const ProductVariantId('v1'),
            color: 'Preto',
            size: 'M',
            voltage: '220V',
            variantSku: 'SKU-1-PT',
            weight: Weight.create(1.2).getOrThrow(),
          ),
        ],
      );
      await repository.save(product);

      expect(body!['sku'], 'SKU-1');
      expect(body!['basePrice'], 10.5);
      expect((body!['variants'] as List).single['weight'], 1.2);
    });

    test('should delete product and variant via the API', () async {
      final calls = <String>[];
      final adapter = FakeHttpAdapter((options) async {
        calls.add('${options.method} ${options.path}');
        return jsonResponse(null, statusCode: 204);
      });
      final repository = buildRepository(adapter);

      await repository.delete(const ProductId('p1'));
      await repository.deleteVariant(
        const ProductId('p1'),
        const ProductVariantId('v1'),
      );

      expect(calls, [
        'DELETE /api/products/p1',
        'DELETE /api/products/p1/variants/v1',
      ]);
    });
  });
}
