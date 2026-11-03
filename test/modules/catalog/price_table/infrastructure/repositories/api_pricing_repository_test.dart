import 'package:dio/dio.dart';
import 'package:ecommerce_b2b/app/core/network/api_client.dart';
import 'package:ecommerce_b2b/app/core/network/session_events.dart';
import 'package:ecommerce_b2b/app/core/network/token_store.dart';
import 'package:ecommerce_b2b/modules/catalog/price_table/infrastructure/repositories/api_pricing_repository.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../../support/fake_http_adapter.dart';

void main() {
  late SessionEvents events;

  ApiPricingRepository buildRepository(FakeHttpAdapter adapter) {
    final dio = Dio()..httpClientAdapter = adapter;
    final client = ApiClient(
      baseUrl: 'http://localhost:5143',
      dio: dio,
      refreshDio: dio,
      tokenStore: InMemoryTokenStore(),
      sessionEvents: events,
    );
    return ApiPricingRepository(client);
  }

  setUp(() => events = SessionEvents());
  tearDown(() => events.dispose());

  group('ApiPricingRepository', () {
    test('should map preview with discount, rule and next tier', () async {
      final adapter = FakeHttpAdapter(
        (options) async => jsonResponse(
          successEnvelope({
            'productId': 'p1',
            'quantity': 10,
            'unitPrice': 5000.0,
            'referenceUnitPrice': 5500.0,
            'subtotal': 50000.0,
            'discount': {'perUnit': 500.0, 'total': 5000.0, 'percentage': 9.09},
            'appliedRule': {
              'priceTableId': 'pt-1',
              'priceTableName': 'Tabela Atacado SP',
              'scopeType': 'Regional',
              'minQuantity': 10,
              'maxQuantity': 999,
              'state': 'SaoPaulo',
            },
            'nextTier': {
              'minQuantity': 50,
              'maxQuantity': 999,
              'unitPrice': 4500.0,
              'savingsPerUnit': 500.0,
              'unitsMissing': 40,
              'priceTableName': 'Tabela Atacado SP',
              'state': 'SaoPaulo',
            },
          }),
        ),
      );
      final repository = buildRepository(adapter);

      final preview = await repository.preview(
        companyId: 'c1',
        productId: 'p1',
        quantity: 10,
        priceTableId: 'pt-1',
      );

      expect(preview.unitPrice.amount, 5000);
      expect(preview.referenceUnitPrice.amount, 5500);
      expect(preview.subtotal.amount, 50000);
      expect(preview.discount!.perUnit.amount, 500);
      expect(preview.discount!.percentage, 9.09);
      expect(preview.appliedRule!.priceTableName, 'Tabela Atacado SP');
      expect(preview.appliedRule!.locationLabel, 'São Paulo (SP)');
      expect(preview.nextTier!.minQuantity, 50);
      expect(preview.nextTier!.unitsMissing, 40);
      expect(preview.nextTier!.unitPrice.amount, 4500);
      expect(preview.nextTier!.savingsPerUnit.amount, 500);
    });

    test('should send the preview payload expected by the API', () async {
      Map<String, dynamic>? body;
      final adapter = FakeHttpAdapter((options) async {
        body = Map<String, dynamic>.from(options.data as Map);
        return jsonResponse(
          successEnvelope({
            'productId': 'p1',
            'quantity': 2,
            'unitPrice': 5500.0,
            'referenceUnitPrice': 5500.0,
            'subtotal': 11000.0,
            'discount': null,
            'appliedRule': null,
            'nextTier': {
              'minQuantity': 10,
              'maxQuantity': 999,
              'unitPrice': 5000.0,
              'savingsPerUnit': 500.0,
              'unitsMissing': 8,
              'priceTableName': 'Tabela Atacado SP',
              'state': 'SaoPaulo',
            },
          }),
        );
      });
      final repository = buildRepository(adapter);

      await repository.preview(
        companyId: 'c1',
        productId: 'p1',
        quantity: 2,
        priceTableId: 'pt-1',
      );

      expect(adapter.requests.single.path, '/api/pricing/preview');
      expect(body, {
        'companyId': 'c1',
        'productId': 'p1',
        'quantity': 2,
        'priceTableId': 'pt-1',
      });
    });

    test('should map eligible price tiers', () async {
      final adapter = FakeHttpAdapter(
        (options) async => jsonResponse(
          successEnvelope([
            {
              'productId': 'p1',
              'productName': 'Notebook Pro 15',
              'productSku': 'SKU-001',
              'priceTableId': 'pt-1',
              'priceTableName': 'Tabela Atacado SP',
              'scopeType': 'Regional',
              'minQuantity': 10,
              'maxQuantity': 999,
              'state': 'SaoPaulo',
              'unitPrice': 5000.0,
              'referenceUnitPrice': 5500.0,
              'discountPerUnit': 500.0,
              'discountPercentage': 9.09,
            },
          ]),
        ),
      );
      final repository = buildRepository(adapter);

      final tiers = await repository.findPriceTiers();

      final tier = tiers.single;
      expect(tier.productName, 'Notebook Pro 15');
      expect(tier.rangeLabel, 'De 10 a 999 un.');
      expect(tier.locationLabel, 'São Paulo (SP)');
      expect(tier.unitPrice.amount, 5000);
      expect(tier.discountPerUnit.amount, 500);
      expect(adapter.requests.single.path, '/api/catalog/price-tiers');
    });

    test(
      'should send companyId when the caller is not the session buyer',
      () async {
        final adapter = FakeHttpAdapter(
          (options) async => jsonResponse(successEnvelope([])),
        );
        final repository = buildRepository(adapter);

        await repository.findPriceTiers(companyId: 'c2');

        expect(adapter.requests.single.queryParameters, {'companyId': 'c2'});
      },
    );
  });
}
