import 'package:dio/dio.dart';
import 'package:ecommerce_b2b/app/core/network/api_client.dart';
import 'package:ecommerce_b2b/app/core/network/session_events.dart';
import 'package:ecommerce_b2b/app/core/network/token_store.dart';
import 'package:ecommerce_b2b/modules/customer_portal/return_request/domain/enums/rma_status.dart';
import 'package:ecommerce_b2b/modules/customer_portal/return_request/domain/return_request.dart';
import 'package:ecommerce_b2b/modules/customer_portal/return_request/infrastructure/repositories/api_return_request_repository.dart';
import 'package:ecommerce_b2b/modules/shared_kernel/domain/common/ids/company_id.dart';
import 'package:ecommerce_b2b/modules/shared_kernel/domain/common/ids/rma_id.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../../support/fake_http_adapter.dart';

void main() {
  late SessionEvents events;

  ApiReturnRequestRepository buildRepository(FakeHttpAdapter adapter) {
    final dio = Dio()..httpClientAdapter = adapter;
    final client = ApiClient(
      baseUrl: 'http://localhost:5143',
      dio: dio,
      refreshDio: dio,
      tokenStore: InMemoryTokenStore(),
      sessionEvents: events,
    );
    return ApiReturnRequestRepository(client);
  }

  Map<String, dynamic> rmaJson({String status = 'Approved'}) => {
    'id': 'r1',
    'orderId': 'o1',
    'status': status,
    'reason': 'Defeito',
    'items': [
      {'productId': 'p1', 'quantity': 1, 'problemDescription': 'Não liga'},
    ],
  };

  setUp(() => events = SessionEvents());
  tearDown(() => events.dispose());

  group('ApiReturnRequestRepository', () {
    test(
      'should map Approved to authorized and Refunded to completed',
      () async {
        final adapter = FakeHttpAdapter(
          (options) async =>
              jsonResponse(successEnvelope([rmaJson(status: 'Approved')])),
        );
        final repository = buildRepository(adapter);

        final list = await repository.findByCompanyId(const CompanyId('c1'));

        expect(list.single.status, RmaStatus.authorized);
        expect(list.single.items.single.problemDescription, 'Não liga');
      },
    );

    test('should POST the RMA payload', () async {
      Map<String, dynamic>? body;
      final adapter = FakeHttpAdapter((options) async {
        body = Map<String, dynamic>.from(options.data as Map);
        return jsonResponse(
          successEnvelope(rmaJson(status: 'Pending')),
          statusCode: 201,
        );
      });
      final repository = buildRepository(adapter);

      final rma = ReturnRequest(
        id: const RmaId('local-rma'),
        orderId: 'o1',
        status: RmaStatus.pending,
        reason: 'Defeito',
      );

      await repository.save(rma);

      expect(body!['orderId'], 'o1');
      expect(body!['reason'], 'Defeito');
      expect(body!['items'], isEmpty);
    });
  });
}
