import 'package:dio/dio.dart';
import 'package:ecommerce_b2b/app/core/network/api_client.dart';
import 'package:ecommerce_b2b/app/core/network/session_events.dart';
import 'package:ecommerce_b2b/app/core/network/token_store.dart';
import 'package:ecommerce_b2b/modules/order_flow/model/enums/order_status.dart';
import 'package:ecommerce_b2b/modules/order_flow/quote/model/enums/quote_status.dart';
import 'package:ecommerce_b2b/modules/order_flow/quote/model/quote.dart';
import 'package:ecommerce_b2b/modules/order_flow/quote/model/quote_item.dart';
import 'package:ecommerce_b2b/modules/order_flow/quote/infrastructure/repositories/api_quote_repository.dart';
import 'package:ecommerce_b2b/modules/shared_kernel/model/common/ids/product_id.dart';
import 'package:ecommerce_b2b/modules/shared_kernel/model/common/ids/quote_id.dart';
import 'package:ecommerce_b2b/modules/shared_kernel/model/finance/value_objects/money.dart';
import 'package:ecommerce_b2b/modules/shared_kernel/model/finance/value_objects/quantity.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../../support/fake_http_adapter.dart';

void main() {
  late SessionEvents events;

  ApiQuoteRepository buildRepository(FakeHttpAdapter adapter) {
    final dio = Dio()..httpClientAdapter = adapter;
    final client = ApiClient(
      baseUrl: 'http://localhost:5143',
      dio: dio,
      refreshDio: dio,
      tokenStore: InMemoryTokenStore(),
      sessionEvents: events,
    );
    return ApiQuoteRepository(client);
  }

  Map<String, dynamic> quoteJson({String status = 'ConvertedToOrder'}) => {
    'id': 'q1',
    'createdAt': '2026-09-21T10:00:00.000+00:00',
    'expiresAt': '2026-10-21T10:00:00.000+00:00',
    'status': status,
    'companyId': 'c1',
    'companyName': 'ACME',
    'companyLegalName': 'ACME Ltda',
    'representativeId': 'rep-456',
    'representativeName': 'Representante Mock',
    'itemsTotal': 100,
    'shippingCost': 22,
    'total': 122,
    'items': [
      {
        'productId': 'p1',
        'productName': 'Produto',
        'productSku': 'SKU-1',
        'quantity': 2,
        'unitPrice': 50,
      },
    ],
  };

  Map<String, dynamic> orderJson() => {
    'id': 'o1',
    'createdAt': '2026-09-21T10:00:00.000+00:00',
    'lastActivityAt': '2026-09-21T10:00:00.000+00:00',
    'companyId': 'c1',
    'companyName': 'ACME',
    'companyLegalName': 'ACME Ltda',
    'status': 'PickingPacking',
    'creditStatus': 'Approved',
    'itemsTotal': 100,
    'shippingCost': 22,
    'total': 122,
    'items': [
      {
        'productId': 'p1',
        'productName': 'Produto',
        'productSku': 'SKU-1',
        'quantity': 2,
        'unitPrice': 50,
      },
    ],
  };

  setUp(() => events = SessionEvents());
  tearDown(() => events.dispose());

  group('ApiQuoteRepository', () {
    test('should map ConvertedToOrder and include freight', () async {
      final adapter = FakeHttpAdapter(
        (options) async => jsonResponse(successEnvelope(quoteJson())),
      );
      final repository = buildRepository(adapter);

      final quote = (await repository.getById(const QuoteId('q1')))!;

      expect(quote.status, QuoteStatus.convertedToOrder);
      expect(quote.companyId, 'c1');
      expect(quote.companyName, 'ACME');
      expect(quote.companyLegalName, 'ACME Ltda');
      expect(quote.representativeId, 'rep-456');
      expect(quote.representativeName, 'Representante Mock');
      expect(quote.shippingCost.amount, 22);
      expect(quote.total.amount, 122);
    });

    test('should send company and price table when creating a quote', () async {
      Map<String, dynamic>? body;
      final adapter = FakeHttpAdapter((options) async {
        body = Map<String, dynamic>.from(options.data as Map);
        return jsonResponse(
          successEnvelope(quoteJson(status: 'Sent')),
          statusCode: 201,
        );
      });
      final repository = buildRepository(adapter);

      await repository.save(
        Quote(
          id: const QuoteId('q1'),
          companyId: 'c1',
          representativeId: 'rep-456',
          status: QuoteStatus.sent,
          items: [
            QuoteItem(
              productId: const ProductId('p1'),
              quantity: Quantity.create(2).getOrThrow(),
              unitPrice: Money.create(50).getOrThrow(),
              priceTableId: 'pt-1',
            ),
          ],
        ),
      );

      expect(body!['companyId'], 'c1');
      final item = (body!['items'] as List).single;
      expect(item['priceTableId'], 'pt-1');
      expect(item['quantity'], 2);
    });

    test('should send variant and omit an empty price table', () async {
      Map<String, dynamic>? body;
      final adapter = FakeHttpAdapter((options) async {
        body = Map<String, dynamic>.from(options.data as Map);
        return jsonResponse(
          successEnvelope(quoteJson(status: 'Sent')),
          statusCode: 201,
        );
      });
      final repository = buildRepository(adapter);

      await repository.save(
        Quote(
          id: const QuoteId('q1'),
          companyId: 'c1',
          representativeId: null,
          status: QuoteStatus.sent,
          items: [
            QuoteItem(
              productId: const ProductId('p1'),
              variantId: 'p1-v2',
              quantity: Quantity.create(1).getOrThrow(),
              unitPrice: Money.create(120).getOrThrow(),
            ),
          ],
        ),
      );

      final item = (body!['items'] as List).single;
      expect(item['variantId'], 'p1-v2');
      expect(item.containsKey('priceTableId'), isFalse);
    });

    test('should map variant fields from the item payload', () async {
      final json = quoteJson();
      (json['items'] as List)[0] = {
        'productId': 'p1',
        'productName': 'Monitor UltraWide 34',
        'productSku': 'SKU-002',
        'variantId': 'p2-v1',
        'variantSku': 'SKU-002-P34',
        'variantLabel': 'Preto · 34pol · Bivolt',
        'quantity': 1,
        'unitPrice': 120,
      };

      final adapter = FakeHttpAdapter(
        (options) async => jsonResponse(successEnvelope(json)),
      );
      final repository = buildRepository(adapter);

      final item = (await repository.getById(
        const QuoteId('q1'),
      ))!.items.single;

      expect(item.variantId, 'p2-v1');
      expect(item.variantSku, 'SKU-002-P34');
      expect(item.variantLabel, 'Preto · 34pol · Bivolt');
    });

    test('should query by representative', () async {
      RequestOptions? captured;
      final adapter = FakeHttpAdapter((options) async {
        captured = options;
        return jsonResponse(successEnvelope([quoteJson(status: 'Sent')]));
      });
      final repository = buildRepository(adapter);

      final quotes = await repository.findByRepresentativeId('rep-456');

      expect(captured!.queryParameters['representativeId'], 'rep-456');
      expect(quotes.single.status, QuoteStatus.sent);
    });

    test('should query by company for the buyer', () async {
      RequestOptions? captured;
      final adapter = FakeHttpAdapter((options) async {
        captured = options;
        return jsonResponse(successEnvelope([quoteJson(status: 'Sent')]));
      });
      final repository = buildRepository(adapter);

      final quotes = await repository.findByCompanyId('c1');

      expect(captured!.path, '/api/quotes');
      expect(captured!.queryParameters['companyId'], 'c1');
      expect(quotes.single.status, QuoteStatus.sent);
    });

    test('should map createdAt and tolerate its absence', () async {
      final adapter = FakeHttpAdapter(
        (options) async => jsonResponse(successEnvelope(quoteJson())),
      );
      final repository = buildRepository(adapter);

      final quote = (await repository.getById(const QuoteId('q1')))!;
      expect(quote.createdAt, DateTime.utc(2026, 9, 21, 10));
      expect(quote.expiresAt, DateTime.utc(2026, 10, 21, 10));

      final legacy = quoteJson()
        ..remove('createdAt')
        ..remove('expiresAt');
      final legacyAdapter = FakeHttpAdapter(
        (options) async => jsonResponse(successEnvelope(legacy)),
      );
      final legacyRepository = buildRepository(legacyAdapter);

      final legacyQuote = (await legacyRepository.getById(
        const QuoteId('q1'),
      ))!;
      expect(legacyQuote.createdAt, isNull);
      expect(legacyQuote.expiresAt, isNull);
    });

    test('should convert a quote into an order', () async {
      RequestOptions? captured;
      final adapter = FakeHttpAdapter((options) async {
        captured = options;
        return jsonResponse(successEnvelope(orderJson()), statusCode: 201);
      });
      final repository = buildRepository(adapter);

      final order = await repository.convert(
        const QuoteId('q1'),
        companyId: 'c1',
      );

      expect(captured!.path, '/api/quotes/q1/convert');
      expect((captured!.data as Map)['companyId'], 'c1');
      expect(order.id.value, 'o1');
      expect(order.status, OrderStatus.pickingPacking);
    });
    test('should map the pricing explanation on an item', () async {
      final json = quoteJson();
      (json['items'] as List)[0] = {
        'productId': 'p1',
        'quantity': 10,
        'unitPrice': 5000,
        'pricing': {
          'referenceUnitPrice': 5500,
          'discountPerUnit': 500,
          'discountTotal': 5000,
          'discountPercentage': 9.09,
          'priceTableId': 'pt-1',
          'priceTableName': 'Tabela Atacado SP',
          'scopeType': 'Regional',
          'minQuantity': 10,
          'maxQuantity': 999,
          'state': 'SaoPaulo',
        },
      };

      final adapter = FakeHttpAdapter(
        (options) async => jsonResponse(successEnvelope(json)),
      );
      final repository = buildRepository(adapter);

      final quote = (await repository.getById(const QuoteId('q1')))!;
      final pricing = quote.items.single.pricing;

      expect(pricing, isNotNull);
      expect(pricing!.referenceUnitPrice.amount, 5500);
      expect(pricing.discountTotal.amount, 5000);
      expect(pricing.priceTableName, 'Tabela Atacado SP');
      expect(pricing.locationLabel, 'São Paulo (SP)');
    });

    test('should request team scope instead of representativeId', () async {
      RequestOptions? captured;
      final adapter = FakeHttpAdapter((options) async {
        captured = options;
        return jsonResponse(successEnvelope([quoteJson()]));
      });
      final repository = buildRepository(adapter);

      await repository.findByRepresentativeId('rep-456', teamScope: true);

      expect(captured!.queryParameters['scope'], 'team');
      expect(
        captured!.queryParameters.containsKey('representativeId'),
        isFalse,
      );
    });

    test('should map the product name and sku resolved by the API', () async {
      final adapter = FakeHttpAdapter(
        (options) async => jsonResponse(successEnvelope(quoteJson())),
      );
      final repository = buildRepository(adapter);

      final quote = (await repository.getById(const QuoteId('q1')))!;
      final item = quote.items.single;

      expect(item.productName, 'Produto');
      expect(item.productSku, 'SKU-1');
    });
  });
}
