import 'package:dio/dio.dart';
import 'package:ecommerce_b2b/app/core/network/api_client.dart';
import 'package:ecommerce_b2b/app/core/network/session_events.dart';
import 'package:ecommerce_b2b/app/core/network/token_store.dart';
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

  Map<String, dynamic> quoteJson({String status = 'Converted'}) => {
    'id': 'q1',
    'status': status,
    'companyId': 'c1',
    'representativeId': 'rep-456',
    'itemsTotal': 100,
    'shippingCost': 22,
    'total': 122,
    'items': [
      {'productId': 'p1', 'quantity': 2, 'unitPrice': 50},
    ],
  };

  setUp(() => events = SessionEvents());
  tearDown(() => events.dispose());

  group('ApiQuoteRepository', () {
    test(
      'should map Converted to convertedToOrder and include freight',
      () async {
        final adapter = FakeHttpAdapter(
          (options) async => jsonResponse(successEnvelope(quoteJson())),
        );
        final repository = buildRepository(adapter);

        final quote = (await repository.getById(const QuoteId('q1')))!;

        expect(quote.status, QuoteStatus.convertedToOrder);
        expect(quote.companyId, 'c1');
        expect(quote.representativeId, 'rep-456');
        expect(quote.shippingCost.amount, 22);
        expect(quote.total.amount, 122);
      },
    );

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
  });
}
