import 'package:dio/dio.dart';
import 'package:ecommerce_b2b/app/core/network/api_client.dart';
import 'package:ecommerce_b2b/app/core/network/session_events.dart';
import 'package:ecommerce_b2b/app/core/network/token_store.dart';
import 'package:ecommerce_b2b/modules/catalog/price_table/domain/enums/price_scope_type.dart';
import 'package:ecommerce_b2b/modules/catalog/price_table/domain/price_rule.dart';
import 'package:ecommerce_b2b/modules/catalog/price_table/domain/price_table.dart';
import 'package:ecommerce_b2b/modules/catalog/price_table/infrastructure/repositories/api_price_table_repository.dart';
import 'package:ecommerce_b2b/modules/shared_kernel/domain/address/enums/state.dart';
import 'package:ecommerce_b2b/modules/shared_kernel/domain/common/ids/price_table_id.dart';
import 'package:ecommerce_b2b/modules/shared_kernel/domain/common/ids/product_id.dart';
import 'package:ecommerce_b2b/modules/shared_kernel/domain/finance/value_objects/money.dart';
import 'package:ecommerce_b2b/modules/shared_kernel/domain/finance/value_objects/quantity.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../../support/fake_http_adapter.dart';

void main() {
  late SessionEvents events;

  ApiPriceTableRepository buildRepository(FakeHttpAdapter adapter) {
    final dio = Dio()..httpClientAdapter = adapter;
    final client = ApiClient(
      baseUrl: 'http://localhost:5143',
      dio: dio,
      refreshDio: dio,
      tokenStore: InMemoryTokenStore(),
      sessionEvents: events,
    );
    return ApiPriceTableRepository(client);
  }

  setUp(() => events = SessionEvents());
  tearDown(() => events.dispose());

  group('ApiPriceTableRepository', () {
    test('should map scope, rules and state', () async {
      final adapter = FakeHttpAdapter(
        (options) async => jsonResponse(
          successEnvelope([
            {
              'id': 'pt-1',
              'name': 'Tabela Nacional',
              'scopeType': 'Regional',
              'rules': [
                {
                  'productId': 'p1',
                  'variantId': null,
                  'minQuantity': 10,
                  'maxQuantity': 50,
                  'unitPrice': 329.90,
                  'state': 'SaoPaulo',
                },
              ],
            },
          ]),
        ),
      );
      final repository = buildRepository(adapter);

      final tables = await repository.findAll();

      final table = tables.single;
      expect(table.scopeType, PriceScopeType.regional);
      final rule = table.rules.single;
      expect(rule.minQuantity.value, 10);
      expect(rule.state, State.saoPaulo);
    });

    test('should send scope and state names expected by the API', () async {
      Map<String, dynamic>? body;
      final adapter = FakeHttpAdapter((options) async {
        body = Map<String, dynamic>.from(options.data as Map);
        return jsonResponse(successEnvelope(body), statusCode: 201);
      });
      final repository = buildRepository(adapter);

      await repository.save(
        PriceTable(
          id: const PriceTableId('pt-1'),
          name: 'Tabela',
          scopeType: PriceScopeType.customerSpecific,
          rules: [
            PriceRule(
              productId: const ProductId('p1'),
              minQuantity: Quantity.create(1).getOrThrow(),
              maxQuantity: Quantity.create(10).getOrThrow(),
              unitPrice: Money.create(10).getOrThrow(),
              state: State.saoPaulo,
            ),
          ],
        ),
      );

      expect(body!['scopeType'], 'CustomerSpecific');
      expect((body!['rules'] as List).single['state'], 'saoPaulo');
    });
  });
}
