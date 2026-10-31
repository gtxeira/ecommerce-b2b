import 'package:dio/dio.dart';
import 'package:ecommerce_b2b/app/core/network/api_client.dart';
import 'package:ecommerce_b2b/app/core/network/session_events.dart';
import 'package:ecommerce_b2b/app/core/network/token_store.dart';
import 'package:ecommerce_b2b/modules/logistics/infrastructure/api/fulfillment_api.dart';
import 'package:ecommerce_b2b/modules/order_flow/model/enums/credit_status.dart';
import 'package:ecommerce_b2b/modules/order_flow/model/enums/order_status.dart';
import 'package:ecommerce_b2b/modules/order_flow/sales_order/model/order_item.dart';
import 'package:ecommerce_b2b/modules/order_flow/sales_order/model/sales_order.dart';
import 'package:ecommerce_b2b/modules/shared_kernel/model/common/ids/order_id.dart';
import 'package:ecommerce_b2b/modules/shared_kernel/model/common/ids/product_id.dart';
import 'package:ecommerce_b2b/modules/shared_kernel/model/common/ids/warehouse_id.dart';
import 'package:ecommerce_b2b/modules/shared_kernel/model/finance/value_objects/money.dart';
import 'package:ecommerce_b2b/modules/shared_kernel/model/finance/value_objects/quantity.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../support/fake_http_adapter.dart';

void main() {
  late SessionEvents events;

  FulfillmentApi buildApi(FakeHttpAdapter adapter) {
    final dio = Dio()..httpClientAdapter = adapter;
    final client = ApiClient(
      baseUrl: 'http://localhost:5143',
      dio: dio,
      refreshDio: dio,
      tokenStore: InMemoryTokenStore(),
      sessionEvents: events,
    );
    return FulfillmentApi(client);
  }

  final order = SalesOrder(
    id: const OrderId('o1'),
    companyId: 'c1',
    status: OrderStatus.pickingPacking,
    creditStatus: CreditStatus.approved,
    items: [
      OrderItem(
        productId: const ProductId('p1'),
        quantity: Quantity.create(2).getOrThrow(),
        unitPriceSnapshot: Money.create(50).getOrThrow(),
      ),
    ],
  );

  setUp(() => events = SessionEvents());
  tearDown(() => events.dispose());

  group('FulfillmentApi', () {
    test('should execute picking, packing and shipment in order', () async {
      final calls = <String>[];
      final adapter = FakeHttpAdapter((options) async {
        calls.add('${options.method} ${options.path}');

        return switch (options.path) {
          '/api/orders/o1/picking' => jsonResponse(
            successEnvelope({
              'pickingId': 'pk1',
              'orderId': 'o1',
              'warehouseId': 'wh-main',
              'status': 'Open',
              'startedAt': '2026-09-21T10:00:00Z',
              'completedAt': null,
              'completedBy': null,
              'isFullyPicked': false,
              'items': [],
            }),
          ),
          '/api/picking/pk1/complete' => jsonResponse(
            successEnvelope({
              'pickingId': 'pk1',
              'orderId': 'o1',
              'warehouseId': 'wh-main',
              'status': 'Completed',
              'startedAt': '2026-09-21T10:00:00Z',
              'completedAt': '2026-09-21T11:00:00Z',
              'completedBy': 'rep-456',
              'isFullyPicked': true,
              'items': [],
            }),
          ),
          '/api/packing/pk1/start' => jsonResponse(
            successEnvelope({
              'packingId': 'pa1',
              'orderId': 'o1',
              'pickingId': 'pk1',
              'status': 'Open',
              'startedAt': '2026-09-21T11:00:00Z',
              'completedAt': null,
              'completedBy': null,
              'packageDescription': 'Caixa',
              'isFullyPacked': false,
              'items': [],
            }),
          ),
          '/api/packing/pa1/complete' => jsonResponse(
            successEnvelope({
              'packingId': 'pa1',
              'orderId': 'o1',
              'pickingId': 'pk1',
              'status': 'Completed',
              'startedAt': '2026-09-21T11:00:00Z',
              'completedAt': '2026-09-21T12:00:00Z',
              'completedBy': 'rep-456',
              'packageDescription': 'Caixa',
              'isFullyPacked': true,
              'items': [],
            }),
          ),
          _ => jsonResponse(
            successEnvelope({
              'shipmentId': 's1',
              'orderId': 'o1',
              'status': 'Shipped',
              'trackingCode': 'BR1',
              'labelNumber': 'LD1',
            }),
          ),
        };
      });
      final api = buildApi(adapter);

      final shipment = await api.processShipment(
        order: order,
        warehouseId: const WarehouseId('wh-main'),
        trackingCode: 'BR1',
        labelNumber: 'LD1',
        packageDescription: 'Caixa',
      );

      expect(shipment.id.value, 's1');
      expect(calls, [
        'POST /api/orders/o1/picking',
        'POST /api/picking/pk1/complete',
        'POST /api/packing/pk1/start',
        'POST /api/packing/pa1/complete',
        'POST /api/orders/o1/shipment',
      ]);
    });

    test(
      'should map the fulfillment state including completed stages',
      () async {
        final adapter = FakeHttpAdapter(
          (options) async => jsonResponse(
            successEnvelope({
              'orderId': 'o1',
              'status': 'PickingPacking',
              'picking': {'status': 'Completed'},
              'packing': {'status': 'Open'},
              'shipment': null,
            }),
          ),
        );
        final api = buildApi(adapter);

        final state = await api.getState('o1');

        expect(state.hasPicking, isTrue);
        expect(state.pickingCompleted, isTrue);
        expect(state.hasPacking, isTrue);
        expect(state.packingCompleted, isFalse);
        expect(state.shipment, isNull);
      },
    );
  });
}
