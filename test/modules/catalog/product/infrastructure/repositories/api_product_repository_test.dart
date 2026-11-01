import 'package:dio/dio.dart';
import 'package:ecommerce_b2b/app/core/network/api_client.dart';
import 'package:ecommerce_b2b/app/core/network/session_events.dart';
import 'package:ecommerce_b2b/app/core/network/token_store.dart';
import 'package:ecommerce_b2b/modules/catalog/product/model/product.dart';
import 'package:ecommerce_b2b/modules/catalog/product/model/product_variant.dart';
import 'package:ecommerce_b2b/modules/catalog/product/infrastructure/repositories/api_product_repository.dart';
import 'package:ecommerce_b2b/modules/shared_kernel/model/common/ids/product_id.dart';
import 'package:ecommerce_b2b/modules/shared_kernel/model/common/ids/product_variant_id.dart';
import 'package:ecommerce_b2b/modules/shared_kernel/model/finance/value_objects/money.dart';
import 'package:ecommerce_b2b/modules/shared_kernel/model/logistics/value_objects/weight.dart';
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

  Map<String, dynamic> productJson(String id, String name) => {
    'id': id,
    'sku': 'SKU-$id',
    'name': name,
    'description': 'Desc $name',
    'basePrice': 10.0,
    'active': true,
    'variants': <Map<String, dynamic>>[],
  };

  Map<String, dynamic> pageEnvelope({
    required List<Map<String, dynamic>> data,
    required int page,
    required int pageSize,
    required int totalItems,
    required int totalPages,
  }) => {
    'data': data,
    'meta': {
      'timestamp': '2026-09-21T10:00:00.000+00:00',
      'pagination': {
        'page': page,
        'pageSize': pageSize,
        'totalItems': totalItems,
        'totalPages': totalPages,
      },
    },
  };

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

    test('should send query and pagination and read meta.pagination', () async {
      final adapter = FakeHttpAdapter(
        (options) async => jsonResponse(
          pageEnvelope(
            data: [productJson('p1', 'Furadeira')],
            page: 2,
            pageSize: 5,
            totalItems: 6,
            totalPages: 2,
          ),
        ),
      );
      final repository = buildRepository(adapter);

      final page = await repository.getPage(
        query: 'furadeira',
        page: 2,
        pageSize: 5,
      );

      expect(adapter.requests.single.uri.queryParameters, {
        'query': 'furadeira',
        'page': '2',
        'pageSize': '5',
      });
      expect(page.items.single.name, 'Furadeira');
      expect(page.page, 2);
      expect(page.pageSize, 5);
      expect(page.totalItems, 6);
      expect(page.totalPages, 2);
      expect(page.hasMore, isFalse);
    });

    test('should walk all pages in getAll', () async {
      final adapter = FakeHttpAdapter((options) async {
        final page = int.parse(options.uri.queryParameters['page']!);
        return jsonResponse(
          pageEnvelope(
            data: page == 1
                ? [productJson('p1', 'Primeiro'), productJson('p2', 'Segundo')]
                : [productJson('p3', 'Terceiro')],
            page: page,
            pageSize: 100,
            totalItems: 3,
            totalPages: 2,
          ),
        );
      });
      final repository = buildRepository(adapter);

      final products = await repository.getAll();

      expect(products.map((p) => p.id.value), ['p1', 'p2', 'p3']);
      expect(adapter.requests, hasLength(2));
      expect(adapter.requests.map((r) => r.uri.queryParameters['page']), [
        '1',
        '2',
      ]);
    });

    test('should not send ?query when the term is empty', () async {
      final adapter = FakeHttpAdapter(
        (options) async => jsonResponse(successEnvelope([])),
      );
      final repository = buildRepository(adapter);

      await repository.getAll(query: '   ');

      final params = adapter.requests.single.uri.queryParameters;
      expect(params.containsKey('query'), isFalse);
      expect(params['page'], '1');
      expect(params['pageSize'], '100');
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
