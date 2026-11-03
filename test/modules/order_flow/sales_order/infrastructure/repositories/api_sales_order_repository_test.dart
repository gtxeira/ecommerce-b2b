import 'package:dio/dio.dart';
import 'package:ecommerce_b2b/app/core/network/api_client.dart';
import 'package:ecommerce_b2b/app/core/network/session_events.dart';
import 'package:ecommerce_b2b/app/core/network/token_store.dart';
import 'package:ecommerce_b2b/modules/order_flow/model/enums/credit_status.dart';
import 'package:ecommerce_b2b/modules/order_flow/model/enums/order_status.dart';
import 'package:ecommerce_b2b/modules/order_flow/sales_order/model/enums/finance_decision.dart';
import 'package:ecommerce_b2b/modules/order_flow/sales_order/infrastructure/repositories/api_sales_order_repository.dart';
import 'package:ecommerce_b2b/modules/shared_kernel/model/common/ids/company_id.dart';
import 'package:ecommerce_b2b/modules/shared_kernel/model/common/ids/order_id.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../../support/fake_http_adapter.dart';

void main() {
  late SessionEvents events;

  ApiSalesOrderRepository buildRepository(FakeHttpAdapter adapter) {
    final dio = Dio()..httpClientAdapter = adapter;
    final client = ApiClient(
      baseUrl: 'http://localhost:5143',
      dio: dio,
      refreshDio: dio,
      tokenStore: InMemoryTokenStore(),
      sessionEvents: events,
    );
    return ApiSalesOrderRepository(client);
  }

  Map<String, dynamic> orderJson({
    String status = 'Invoiced',
    String creditStatus = 'Approved',
    String? decision = 'Approved',
  }) => {
    'id': 'o1',
    'createdAt': '2026-09-21T10:00:00.000+00:00',
    'companyId': 'c1',
    'status': status,
    'creditStatus': creditStatus,
    'itemsTotal': 100,
    'shippingCost': 22,
    'total': 122,
    'items': [
      {'productId': 'p1', 'quantity': 2, 'unitPrice': 50},
    ],
    'financeDecision': decision,
    'financeReviewerId': 'fin-1',
    'financeJustification': 'Limite ok',
  };

  setUp(() => events = SessionEvents());
  tearDown(() => events.dispose());

  group('ApiSalesOrderRepository', () {
    test('should map Invoiced status, freight and finance review', () async {
      final adapter = FakeHttpAdapter(
        (options) async => jsonResponse(successEnvelope(orderJson())),
      );
      final repository = buildRepository(adapter);

      final order = (await repository.getById(const OrderId('o1')))!;

      expect(order.status, OrderStatus.invoiced);
      expect(order.creditStatus, CreditStatus.approved);
      expect(order.shippingCost.amount, 22);
      expect(order.total.amount, 122);
      expect(order.items.single.quantity.value, 2);
      expect(order.financeReview!.decision, FinanceDecision.approved);
      expect(order.financeReview!.justification, 'Limite ok');
    });

    test('should query purchase history by company', () async {
      RequestOptions? captured;
      final adapter = FakeHttpAdapter((options) async {
        captured = options;
        return jsonResponse(successEnvelope([orderJson(status: 'Delivered')]));
      });
      final repository = buildRepository(adapter);

      final orders = await repository.findByCompanyId(const CompanyId('c1'));

      expect(captured!.path, '/api/me/purchase-history');
      expect(captured!.queryParameters['companyId'], 'c1');
      expect(orders.single.status, OrderStatus.delivered);
    });

    test('should query orders by status', () async {
      RequestOptions? captured;
      final adapter = FakeHttpAdapter((options) async {
        captured = options;
        return jsonResponse(
          successEnvelope([orderJson(status: 'PickingPacking')]),
        );
      });
      final repository = buildRepository(adapter);

      final orders = await repository.findByStatus('PickingPacking');

      expect(captured!.path, '/api/orders');
      expect(captured!.queryParameters['status'], 'PickingPacking');
      expect(orders.single.status, OrderStatus.pickingPacking);
    });

    test('should map createdAt and tolerate its absence', () async {
      final adapter = FakeHttpAdapter(
        (options) async => jsonResponse(successEnvelope(orderJson())),
      );
      final repository = buildRepository(adapter);

      final order = (await repository.getById(const OrderId('o1')))!;
      expect(order.createdAt, DateTime.utc(2026, 9, 21, 10));

      final legacy = orderJson()..remove('createdAt');
      final legacyAdapter = FakeHttpAdapter(
        (options) async => jsonResponse(successEnvelope(legacy)),
      );
      final legacyRepository = buildRepository(legacyAdapter);

      final legacyOrder = (await legacyRepository.getById(
        const OrderId('o1'),
      ))!;
      expect(legacyOrder.createdAt, isNull);
    });
  });
}
