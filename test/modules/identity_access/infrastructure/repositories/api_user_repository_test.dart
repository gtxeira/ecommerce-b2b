import 'package:dio/dio.dart';
import 'package:ecommerce_b2b/app/core/network/api_client.dart';
import 'package:ecommerce_b2b/app/core/network/session_events.dart';
import 'package:ecommerce_b2b/app/core/network/token_store.dart';
import 'package:ecommerce_b2b/modules/identity_access/domain/enums/user_role.dart';
import 'package:ecommerce_b2b/modules/identity_access/infrastructure/repositories/api_user_repository.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../support/fake_http_adapter.dart';

void main() {
  late SessionEvents events;

  ApiUserRepository buildRepository(FakeHttpAdapter adapter) {
    final dio = Dio()..httpClientAdapter = adapter;
    final client = ApiClient(
      baseUrl: 'http://localhost:5143',
      dio: dio,
      refreshDio: dio,
      tokenStore: InMemoryTokenStore(),
      sessionEvents: events,
    );
    return ApiUserRepository(client);
  }

  Map<String, dynamic> userJson({
    String id = 'u1',
    String role = 'Buyer',
    String? companyId = 'c1',
    bool active = true,
  }) => {
    'id': id,
    'fullName': 'Usuário Teste',
    'email': 'user@test.com',
    'role': role,
    'companyId': companyId,
    'active': active,
  };

  setUp(() => events = SessionEvents());
  tearDown(() => events.dispose());

  group('ApiUserRepository', () {
    test('should send filters and map users', () async {
      RequestOptions? captured;
      final adapter = FakeHttpAdapter((options) async {
        captured = options;
        return jsonResponse(
          successEnvelope([
            userJson(id: 'u1'),
            userJson(id: 'u2', role: 'Admin', companyId: null),
          ]),
        );
      });
      final repository = buildRepository(adapter);

      final users = await repository.findAll(
        role: UserRole.admin,
        active: true,
        search: 'silva',
      );

      expect(captured!.queryParameters['role'], 'Admin');
      expect(captured!.queryParameters['active'], 'true');
      expect(captured!.queryParameters['search'], 'silva');
      expect(users, hasLength(2));
      expect(users[1].role, UserRole.admin);
      expect(users[1].companyId, isNull);
    });

    test('should create a user with roleAssignment-ready payload', () async {
      Map<String, dynamic>? body;
      final adapter = FakeHttpAdapter((options) async {
        body = Map<String, dynamic>.from(options.data as Map);
        return jsonResponse(successEnvelope(userJson()), statusCode: 201);
      });
      final repository = buildRepository(adapter);

      final user = await repository.create(
        fullName: 'Usuário Teste',
        email: 'user@test.com',
        password: 'senha1234',
        role: UserRole.buyer,
        companyId: 'c1',
      );

      expect(body!['role'], 'Buyer');
      expect(body!['companyId'], 'c1');
      expect(user.role, UserRole.buyer);
    });

    test('should update name/role/active via PATCH', () async {
      RequestOptions? captured;
      final adapter = FakeHttpAdapter((options) async {
        captured = options;
        return jsonResponse(
          successEnvelope(
            userJson(role: 'Finance', companyId: null, active: false),
          ),
        );
      });
      final repository = buildRepository(adapter);

      final user = await repository.update(
        id: 'u1',
        fullName: 'Novo Nome',
        role: UserRole.finance,
        active: false,
      );

      expect(captured!.method, 'PATCH');
      expect(captured!.path, '/api/users/u1');
      final body = captured!.data as Map;
      expect(body['fullName'], 'Novo Nome');
      expect(body['active'], false);
      expect(body['roleAssignment']['role'], 'Finance');
      expect(user.active, isFalse);
    });

    test('should reset the password', () async {
      RequestOptions? captured;
      final adapter = FakeHttpAdapter((options) async {
        captured = options;
        return jsonResponse(successEnvelope(userJson()));
      });
      final repository = buildRepository(adapter);

      await repository.resetPassword(id: 'u1', newPassword: 'novaSenha1');

      expect(captured!.path, '/api/users/u1/password');
      expect((captured!.data as Map)['newPassword'], 'novaSenha1');
    });
  });
}
