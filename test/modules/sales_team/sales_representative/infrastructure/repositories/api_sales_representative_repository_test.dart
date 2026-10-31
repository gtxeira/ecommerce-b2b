import 'package:dio/dio.dart';
import 'package:ecommerce_b2b/app/core/network/api_client.dart';
import 'package:ecommerce_b2b/app/core/network/session_events.dart';
import 'package:ecommerce_b2b/app/core/network/token_store.dart';
import 'package:ecommerce_b2b/modules/sales_team/sales_representative/model/enums/commission_status.dart';
import 'package:ecommerce_b2b/modules/sales_team/sales_representative/infrastructure/repositories/api_sales_representative_repository.dart';
import 'package:ecommerce_b2b/modules/shared_kernel/model/common/ids/representative_id.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../../support/fake_http_adapter.dart';

void main() {
  late SessionEvents events;

  ApiSalesRepresentativeRepository buildRepository(FakeHttpAdapter adapter) {
    final dio = Dio()..httpClientAdapter = adapter;
    final client = ApiClient(
      baseUrl: 'http://localhost:5143',
      dio: dio,
      refreshDio: dio,
      tokenStore: InMemoryTokenStore(),
      sessionEvents: events,
    );
    return ApiSalesRepresentativeRepository(client);
  }

  setUp(() => events = SessionEvents());
  tearDown(() => events.dispose());

  group('ApiSalesRepresentativeRepository', () {
    test('should build the hierarchy from profile and team', () async {
      final adapter = FakeHttpAdapter((options) async {
        if (options.path == '/api/me/profile') {
          return jsonResponse(
            successEnvelope({
              'userId': 'rep-supervisor',
              'fullName': 'Supervisor',
              'email': 'supervisor@test.com',
              'role': 'Supervisor',
              'companyId': null,
              'commissionRate': 3,
              'supervisorId': null,
            }),
          );
        }
        return jsonResponse(
          successEnvelope([
            {
              'id': 'rep-456',
              'fullName': 'Representante',
              'email': 'rep@test.com',
            },
          ]),
        );
      });
      final repository = buildRepository(adapter);

      final all = await repository.findAll();

      expect(all, hasLength(2));
      expect(all.first.subordinateLinks.single.subordinateId.value, 'rep-456');
      expect(all.last.supervisorLink!.supervisorId.value, 'rep-supervisor');
    });

    test('should map commissions and portfolio', () async {
      final adapter = FakeHttpAdapter((options) async {
        if (options.path == '/api/me/commissions') {
          return jsonResponse(
            successEnvelope([
              {
                'baseAmount': 1000,
                'rate': 5,
                'amount': 50,
                'status': 'Approved',
                'orderId': 'o1',
              },
            ]),
          );
        }
        return jsonResponse(
          successEnvelope([
            {'companyId': 'c1'},
          ]),
        );
      });
      final repository = buildRepository(adapter);

      final commissions = await repository.getCommissions(
        representativeId: 'rep-456',
      );
      final portfolio = await repository.getPortfolio(
        representativeId: 'rep-456',
      );

      expect(commissions.single.status, CommissionStatus.approved);
      expect(commissions.single.orderId, 'o1');
      expect(portfolio.single.companyId.value, 'c1');
    });

    test('should find a representative by id', () async {
      final adapter = FakeHttpAdapter((options) async {
        if (options.path == '/api/me/profile') {
          return jsonResponse(
            successEnvelope({
              'userId': 'rep-456',
              'fullName': 'Representante',
              'email': 'rep@test.com',
              'role': 'Representative',
              'companyId': null,
              'commissionRate': 5,
              'supervisorId': null,
            }),
          );
        }
        return jsonResponse(
          errorEnvelope(code: 'FORBIDDEN', message: 'Sem equipe.'),
          statusCode: 403,
        );
      });
      final repository = buildRepository(adapter);

      final rep = await repository.findById(const RepresentativeId('rep-456'));

      expect(rep!.fullName, 'Representante');
      expect(rep.commissionRate.value, 5);
    });
  });
}
