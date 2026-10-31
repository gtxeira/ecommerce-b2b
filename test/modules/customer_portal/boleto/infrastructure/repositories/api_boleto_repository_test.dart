import 'package:dio/dio.dart';
import 'package:ecommerce_b2b/app/core/network/api_client.dart';
import 'package:ecommerce_b2b/app/core/network/session_events.dart';
import 'package:ecommerce_b2b/app/core/network/token_store.dart';
import 'package:ecommerce_b2b/modules/customer_portal/boleto/infrastructure/repositories/api_boleto_repository.dart';
import 'package:ecommerce_b2b/modules/shared_kernel/model/common/ids/order_id.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../../support/fake_http_adapter.dart';

void main() {
  late SessionEvents events;

  ApiBoletoRepository buildRepository(FakeHttpAdapter adapter) {
    final dio = Dio()..httpClientAdapter = adapter;
    final client = ApiClient(
      baseUrl: 'http://localhost:5143',
      dio: dio,
      refreshDio: dio,
      tokenStore: InMemoryTokenStore(),
      sessionEvents: events,
    );
    return ApiBoletoRepository(client);
  }

  setUp(() => events = SessionEvents());
  tearDown(() => events.dispose());

  test('should map barcode and URL from the API', () async {
    final adapter = FakeHttpAdapter(
      (options) async => jsonResponse(
        successEnvelope({
          'barcode': '34191.79001 01043.5100479102.510184',
          'url': 'https://boletos.example.com/o1.pdf',
        }),
      ),
    );
    final repository = buildRepository(adapter);

    final boleto = await repository.getBoletoByOrder(const OrderId('o1'));

    expect(boleto.barcode, contains('34191'));
    expect(boleto.url, endsWith('o1.pdf'));
  });
}
