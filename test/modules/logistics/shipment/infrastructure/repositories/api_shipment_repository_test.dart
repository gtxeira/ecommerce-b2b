import 'package:dio/dio.dart';
import 'package:ecommerce_b2b/app/core/network/api_client.dart';
import 'package:ecommerce_b2b/app/core/network/session_events.dart';
import 'package:ecommerce_b2b/app/core/network/token_store.dart';
import 'package:ecommerce_b2b/modules/logistics/shipment/domain/enums/shipment_status.dart';
import 'package:ecommerce_b2b/modules/logistics/shipment/infrastructure/repositories/api_shipment_repository.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../../support/fake_http_adapter.dart';

void main() {
  late SessionEvents events;

  ApiShipmentRepository buildRepository(FakeHttpAdapter adapter) {
    final dio = Dio()..httpClientAdapter = adapter;
    final client = ApiClient(
      baseUrl: 'http://localhost:5143',
      dio: dio,
      refreshDio: dio,
      tokenStore: InMemoryTokenStore(),
      sessionEvents: events,
    );
    return ApiShipmentRepository(client);
  }

  setUp(() => events = SessionEvents());
  tearDown(() => events.dispose());

  group('ApiShipmentRepository', () {
    test('should map the shipment of an order', () async {
      final adapter = FakeHttpAdapter(
        (options) async => jsonResponse(
          successEnvelope({
            'shipmentId': 's1',
            'orderId': 'o1',
            'status': 'InTransit',
            'trackingCode': 'BR123456789BR',
            'labelNumber': 'LD-1',
          }),
        ),
      );
      final repository = buildRepository(adapter);

      final shipment = (await repository.getByOrderId('o1'))!;

      expect(shipment.id.value, 's1');
      expect(shipment.status, ShipmentStatus.inTransit);
      expect(shipment.trackingCode.value, 'BR123456789BR');
      expect(shipment.shippingLabel.labelNumber, 'LD-1');
    });

    test('should return null when the order has no shipment yet', () async {
      final adapter = FakeHttpAdapter(
        (options) async => jsonResponse(
          errorEnvelope(
            code: 'SHIPMENT_NOT_FOUND',
            message: 'Envio não encontrado.',
          ),
          statusCode: 404,
        ),
      );
      final repository = buildRepository(adapter);

      expect(await repository.getByOrderId('o1'), isNull);
    });
  });
}
