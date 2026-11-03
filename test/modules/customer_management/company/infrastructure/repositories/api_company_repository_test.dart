import 'package:dio/dio.dart';
import 'package:ecommerce_b2b/app/core/network/api_client.dart';
import 'package:ecommerce_b2b/app/core/network/session_events.dart';
import 'package:ecommerce_b2b/app/core/network/token_store.dart';
import 'package:ecommerce_b2b/modules/customer_management/company/infrastructure/repositories/api_company_repository.dart';
import 'package:ecommerce_b2b/modules/shared_kernel/model/common/ids/company_id.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../../support/fake_http_adapter.dart';

void main() {
  late SessionEvents events;

  ApiCompanyRepository buildRepository(FakeHttpAdapter adapter) {
    final dio = Dio()..httpClientAdapter = adapter;
    final client = ApiClient(
      baseUrl: 'http://localhost:5143',
      dio: dio,
      refreshDio: dio,
      tokenStore: InMemoryTokenStore(),
      sessionEvents: events,
    );
    return ApiCompanyRepository(client);
  }

  setUp(() => events = SessionEvents());
  tearDown(() => events.dispose());

  Map<String, dynamic> companyJson() => {
    'id': 'c1',
    'legalName': 'Distribuidora ABC Ltda',
    'tradeName': 'ABC',
    'cnpj': '12345678000195',
    'inscricaoEstadual': '123456789',
    'email': 'contato@abc.com.br',
    'phone': '11999999999',
    'billingAddress': {
      'street': 'Av. Paulista',
      'number': '1000',
      'complement': null,
      'neighborhood': 'Bela Vista',
      'city': 'São Paulo',
      'state': 'SaoPaulo',
      'zipCode': '01310100',
    },
    'shippingAddress': {
      'street': 'Rua das Flores',
      'number': '250',
      'complement': 'Galpão 3',
      'neighborhood': 'Centro',
      'city': 'Campinas',
      'state': 'SaoPaulo',
      'zipCode': '13010000',
    },
    'state': 'SaoPaulo',
    'creditLimit': 50000,
    'openBalance': 1000,
    'pendingOrdersBalance': 2500,
    'availableLimit': 46500,
    'representativeId': 'rep-456',
    'authorizedBuyers': [
      {
        'id': 'b1',
        'fullName': 'Maria Compradora',
        'email': 'maria@abc.com.br',
        'phone': '11988888888',
        'positionTitle': 'Compras',
        'active': true,
      },
    ],
  };

  group('ApiCompanyRepository', () {
    test('should map company, addresses, buyers and credit balances', () async {
      final adapter = FakeHttpAdapter(
        (options) async => jsonResponse(successEnvelope([companyJson()])),
      );
      final repository = buildRepository(adapter);

      final companies = await repository.findAll();

      final company = companies.single;
      expect(company.id.value, 'c1');
      expect(company.cnpj.value, '12345678000195');
      expect(company.billingAddress.city.value, 'São Paulo');
      expect(company.creditAccount.openBalance.amount, 1000);
      expect(company.creditAccount.pendingOrdersBalance.amount, 2500);
      expect(company.authorizedBuyers.single.fullName, 'Maria Compradora');
    });

    test('should pass representativeId as query parameter', () async {
      RequestOptions? captured;
      final adapter = FakeHttpAdapter((options) async {
        captured = options;
        return jsonResponse(successEnvelope([companyJson()]));
      });
      final repository = buildRepository(adapter);

      await repository.findByRepresentativeId('rep-456');

      expect(captured!.queryParameters['representativeId'], 'rep-456');
    });

    test('should request team scope instead of representativeId', () async {
      RequestOptions? captured;
      final adapter = FakeHttpAdapter((options) async {
        captured = options;
        return jsonResponse(successEnvelope([companyJson()]));
      });
      final repository = buildRepository(adapter);

      await repository.findByRepresentativeId('rep-456', teamScope: true);

      expect(captured!.queryParameters['scope'], 'team');
      expect(
        captured!.queryParameters.containsKey('representativeId'),
        isFalse,
      );
    });

    test('should add a buyer and map the API response', () async {
      Map<String, dynamic>? body;
      final adapter = FakeHttpAdapter((options) async {
        body = Map<String, dynamic>.from(options.data as Map);
        return jsonResponse(
          successEnvelope({
            'id': 'b2',
            'fullName': body!['fullName'],
            'email': body!['email'],
            'phone': body!['phone'],
            'positionTitle': body!['positionTitle'],
            'active': true,
          }),
          statusCode: 201,
        );
      });
      final repository = buildRepository(adapter);

      final buyer = await repository.addAuthorizedBuyer(
        companyId: const CompanyId('c1'),
        fullName: 'João',
        email: 'joao@abc.com.br',
        phone: '11977777777',
        positionTitle: 'Analista',
        password: 'senha1234',
      );

      expect(body!['fullName'], 'João');
      expect(body!['password'], 'senha1234');
      expect(buyer.id.value, 'b2');
      expect(buyer.email.value, 'joao@abc.com.br');
    });
  });
}
