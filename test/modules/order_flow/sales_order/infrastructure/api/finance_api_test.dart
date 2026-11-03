import 'package:dio/dio.dart';
import 'package:ecommerce_b2b/app/core/network/api_client.dart';
import 'package:ecommerce_b2b/app/core/network/session_events.dart';
import 'package:ecommerce_b2b/app/core/network/token_store.dart';
import 'package:ecommerce_b2b/modules/order_flow/model/enums/credit_status.dart';
import 'package:ecommerce_b2b/modules/order_flow/model/enums/order_status.dart';
import 'package:ecommerce_b2b/modules/order_flow/sales_order/model/enums/finance_decision.dart';
import 'package:ecommerce_b2b/modules/order_flow/sales_order/infrastructure/api/finance_api.dart';
import 'package:ecommerce_b2b/modules/shared_kernel/model/common/ids/order_id.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../../support/fake_http_adapter.dart';

void main() {
  late SessionEvents events;

  FinanceApi buildApi(FakeHttpAdapter adapter) {
    final dio = Dio()..httpClientAdapter = adapter;
    final client = ApiClient(
      baseUrl: 'http://localhost:5143',
      dio: dio,
      refreshDio: dio,
      tokenStore: InMemoryTokenStore(),
      sessionEvents: events,
    );
    return FinanceApi(client);
  }

  Map<String, dynamic> summaryJson() => {
    'companyCount': 2,
    'totalCreditLimit': 15000.0,
    'totalOpenBalance': 1500.0,
    'totalPendingOrdersBalance': 5000.0,
    'totalExposure': 6500.0,
    'availableLimit': 8500.0,
    'utilizationPercentage': 43.33,
    'companiesAtRisk': 1,
    'companiesOverLimit': 0,
  };

  Map<String, dynamic> orderJson() => {
    'id': 'o1',
    'companyId': 'c1',
    'status': 'PickingPacking',
    'creditStatus': 'Approved',
    'itemsTotal': 100,
    'shippingCost': 0,
    'total': 100,
    'items': [],
    'financeDecision': 'Approved',
    'financeReviewerId': 'fin-1',
    'financeJustification': 'Ok',
  };

  setUp(() => events = SessionEvents());
  tearDown(() => events.dispose());

  group('FinanceApi', () {
    test('should send decision and map the updated order', () async {
      Map<String, dynamic>? body;
      final adapter = FakeHttpAdapter((options) async {
        body = Map<String, dynamic>.from(options.data as Map);
        return jsonResponse(successEnvelope(orderJson()));
      });
      final api = buildApi(adapter);

      final order = await api.processReview(
        orderId: 'o1',
        decision: FinanceDecision.approved,
        justification: 'Ok',
      );

      expect(body!['decision'], 'Approved');
      expect(body!['justification'], 'Ok');
      expect(order.status, OrderStatus.pickingPacking);
    });

    test('should map invoice response and commission flag', () async {
      final adapter = FakeHttpAdapter(
        (options) async => jsonResponse(
          successEnvelope({'order': orderJson(), 'commissionGenerated': true}),
        ),
      );
      final api = buildApi(adapter);

      final result = await api.invoice('o1');

      expect(result.commissionGenerated, isTrue);
      expect(result.order.id, const OrderId('o1'));
    });

    test('should load the finance summary', () async {
      final adapter = FakeHttpAdapter(
        (options) async => jsonResponse(successEnvelope(summaryJson())),
      );
      final api = buildApi(adapter);

      final summary = await api.getSummary();

      expect(summary.companyCount, 2);
      expect(summary.totalExposure.amount, 6500);
      expect(summary.utilizationPercentage, 43.33);
      expect(summary.companiesAtRisk, 1);
      expect(adapter.requests.single.path, '/api/finance/summary');
    });

    test('should load the pending finance queue', () async {
      final adapter = FakeHttpAdapter(
        (options) async => jsonResponse(successEnvelope([orderJson()])),
      );
      final api = buildApi(adapter);

      final pending = await api.getPendingReviews();

      expect(pending.single.creditStatus, CreditStatus.approved);
    });
  });
}
