import 'package:dio/dio.dart';
import 'package:ecommerce_b2b/app/core/network/api_client.dart';
import 'package:ecommerce_b2b/app/core/network/session_events.dart';
import 'package:ecommerce_b2b/app/core/network/token_store.dart';
import 'package:ecommerce_b2b/modules/identity_access/domain/enums/user_role.dart';
import 'package:ecommerce_b2b/modules/identity_access/infrastructure/repositories/api_auth_repository.dart';
import 'package:ecommerce_b2b/modules/shared_kernel/domain/contact/value_objects/email_address.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../support/fake_http_adapter.dart';

void main() {
  late InMemoryTokenStore tokenStore;
  late SessionEvents sessionEvents;

  ApiAuthRepository buildRepository(FakeHttpAdapter adapter) {
    final dio = Dio()..httpClientAdapter = adapter;
    final refreshDio = Dio()..httpClientAdapter = adapter;
    final client = ApiClient(
      baseUrl: 'http://localhost:5143',
      dio: dio,
      refreshDio: refreshDio,
      tokenStore: tokenStore,
      sessionEvents: sessionEvents,
    );
    return ApiAuthRepository(client, tokenStore);
  }

  final email = EmailAddress.create('rep@test.com').getOrThrow();

  setUp(() {
    tokenStore = InMemoryTokenStore();
    sessionEvents = SessionEvents();
  });

  tearDown(() async {
    await sessionEvents.dispose();
  });

  group('ApiAuthRepository', () {
    test('should map login response and persist tokens', () async {
      final adapter = FakeHttpAdapter((options) async {
        expect(options.path, '/api/auth/login');
        return jsonResponse(
          successEnvelope({
            'accessToken': 'access',
            'refreshToken': 'refresh',
            'accessTokenExpiresAt': '2026-09-21T10:15:00Z',
            'refreshTokenExpiresAt': '2026-09-28T10:00:00Z',
            'session': {
              'userId': 'rep-456',
              'role': 'Representative',
              'companyId': null,
            },
          }),
        );
      });
      final repository = buildRepository(adapter);

      final result = await repository.login(email, 'password123');

      expect(result.isSuccess, isTrue);
      final session = result.getOrThrow();
      expect(session.userId.value, 'rep-456');
      expect(session.role, UserRole.representative);
      expect(session.companyId, isNull);
      expect((await tokenStore.read())!.refreshToken, 'refresh');
    });

    test('should map admin role', () async {
      final adapter = FakeHttpAdapter(
        (options) async => jsonResponse(
          successEnvelope({
            'accessToken': 'access',
            'refreshToken': 'refresh',
            'session': {
              'userId': 'admin-001',
              'role': 'Admin',
              'companyId': null,
            },
          }),
        ),
      );
      final repository = buildRepository(adapter);

      final result = await repository.login(email, 'password123');

      expect(result.getOrThrow().role, UserRole.admin);
    });

    test('should return InvalidCredentialsError on 401', () async {
      final adapter = FakeHttpAdapter(
        (options) async => jsonResponse(
          errorEnvelope(
            code: 'INVALID_CREDENTIALS',
            message: 'E-mail ou senha inválidos.',
          ),
          statusCode: 401,
        ),
      );
      final repository = buildRepository(adapter);

      final result = await repository.login(email, 'errada');

      expect(result.isFailure, isTrue);
      expect(result.getFailureOrThrow().message, 'E-mail ou senha inválidos.');
      expect(await tokenStore.read(), isNull);
    });

    test('should restore the session from /api/auth/me', () async {
      await tokenStore.save(
        const AuthTokens(accessToken: 'access', refreshToken: 'refresh'),
      );
      final adapter = FakeHttpAdapter((options) async {
        expect(options.path, '/api/auth/me');
        return jsonResponse(
          successEnvelope({
            'userId': 'buyer-1',
            'role': 'Buyer',
            'companyId': 'c1',
          }),
        );
      });
      final repository = buildRepository(adapter);

      final session = await repository.getCurrentSession();

      expect(session, isNotNull);
      expect(session!.role, UserRole.buyer);
      expect(session.companyId!.value, 'c1');
    });

    test('should return null without persisted tokens', () async {
      final repository = buildRepository(
        FakeHttpAdapter((options) async {
          fail('não deveria chamar a API sem tokens');
        }),
      );

      expect(await repository.getCurrentSession(), isNull);
    });

    test('should clear tokens on logout even when the API fails', () async {
      await tokenStore.save(
        const AuthTokens(accessToken: 'access', refreshToken: 'refresh'),
      );
      final adapter = FakeHttpAdapter(
        (options) async => jsonResponse(
          errorEnvelope(code: 'UNAUTHORIZED', message: 'Sessão inválida.'),
          statusCode: 401,
        ),
      );
      final repository = buildRepository(adapter);

      await repository.logout();

      expect(await tokenStore.read(), isNull);
    });
  });
}
