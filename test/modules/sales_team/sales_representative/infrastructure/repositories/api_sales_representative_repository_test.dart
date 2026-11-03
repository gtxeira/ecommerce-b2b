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
                'commissionId': 12,
                'baseAmount': 1000,
                'rate': 5,
                'amount': 50,
                'status': 'Paid',
                'orderId': 'o1',
                'createdAt': '2026-11-03T14:30:00Z',
                'representativeId': 'rep-456',
                'representativeName': 'Representante Mock',
              },
            ]),
          );
        }
        return jsonResponse(
          successEnvelope([
            {
              'companyId': 'c1',
              'representativeId': 'rep-456',
              'representativeName': 'Representante Mock',
            },
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

      expect(commissions.single.status, CommissionStatus.paid);
      expect(commissions.single.id, 12);
      expect(commissions.single.orderId, 'o1');
      expect(commissions.single.createdAt, DateTime.utc(2026, 11, 3, 14, 30));
      expect(commissions.single.representativeId, 'rep-456');
      expect(commissions.single.representativeName, 'Representante Mock');
      expect(portfolio.single.companyId.value, 'c1');
      expect(portfolio.single.representativeId, 'rep-456');
      expect(portfolio.single.representativeName, 'Representante Mock');
    });

    test(
      'should request the team scope instead of a representative id',
      () async {
        Map<String, dynamic>? commissionQuery;
        Map<String, dynamic>? portfolioQuery;
        final adapter = FakeHttpAdapter((options) async {
          if (options.path == '/api/me/commissions') {
            commissionQuery = options.queryParameters;
            return jsonResponse(successEnvelope(const []));
          }
          portfolioQuery = options.queryParameters;
          return jsonResponse(successEnvelope(const []));
        });
        final repository = buildRepository(adapter);

        await repository.getCommissions(
          representativeId: 'rep-1',
          teamScope: true,
        );
        await repository.getPortfolio(
          representativeId: 'rep-1',
          teamScope: true,
        );

        expect(commissionQuery, {'scope': 'team'});
        expect(portfolioQuery, {'scope': 'team'});
      },
    );

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

    test('should patch the commission status and map the response', () async {
      RequestOptions? captured;
      final adapter = FakeHttpAdapter((options) async {
        captured = options;
        return jsonResponse(
          successEnvelope({
            'commissionId': 12,
            'baseAmount': 1000,
            'rate': 5,
            'amount': 50,
            'status': 'Paid',
            'orderId': 'o1',
            'createdAt': '2026-11-03T14:30:00Z',
            'representativeId': 'rep-456',
            'representativeName': 'Representante Mock',
          }),
        );
      });
      final repository = buildRepository(adapter);

      final updated = await repository.updateCommissionStatus(
        commissionId: 12,
        status: CommissionStatus.paid,
      );

      expect(captured!.method, 'PATCH');
      expect(captured!.path, '/api/me/commissions/12/status');
      expect((captured!.data as Map)['status'], 'Paid');
      expect(updated.id, 12);
      expect(updated.status, CommissionStatus.paid);
    });
  });
}
