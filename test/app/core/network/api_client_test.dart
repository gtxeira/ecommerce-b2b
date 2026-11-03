import 'package:dio/dio.dart';
import 'package:ecommerce_b2b/app/core/network/api_client.dart';
import 'package:ecommerce_b2b/app/core/network/api_exception.dart';
import 'package:ecommerce_b2b/app/core/network/session_events.dart';
import 'package:ecommerce_b2b/app/core/network/token_store.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/fake_http_adapter.dart';

void main() {
  late InMemoryTokenStore tokenStore;
  late SessionEvents sessionEvents;
  late Dio dio;
  late Dio refreshDio;

  ApiClient buildClient(
    FakeHttpAdapter adapter, {
    FakeHttpAdapter? refreshAdapter,
  }) {
    dio = Dio();
    dio.httpClientAdapter = adapter;
    refreshDio = Dio();
    refreshDio.httpClientAdapter = refreshAdapter ?? adapter;
    return ApiClient(
      baseUrl: 'http://localhost:5143',
      dio: dio,
      refreshDio: refreshDio,
      tokenStore: tokenStore,
      sessionEvents: sessionEvents,
    );
  }

  setUp(() {
    tokenStore = InMemoryTokenStore(
      const AuthTokens(accessToken: 'access-1', refreshToken: 'refresh-1'),
    );
    sessionEvents = SessionEvents();
  });

  tearDown(() async {
    await sessionEvents.dispose();
  });

  group('ApiClient', () {
    test('should attach the bearer and unwrap the success envelope', () async {
      final adapter = FakeHttpAdapter((options) async {
        expect(options.headers['Authorization'], 'Bearer access-1');
        return jsonResponse(
          successEnvelope([
            {'id': 'p1'},
          ]),
        );
      });
      final client = buildClient(adapter);

      final data = await client.get('/api/products');

      expect(data, isA<List<dynamic>>());
      expect((data as List).single['id'], 'p1');
    });

    test('should expose data and meta through getEnvelope', () async {
      final adapter = FakeHttpAdapter(
        (options) async => jsonResponse({
          'data': [
            {'id': 'p1'},
          ],
          'meta': {
            'timestamp': '2026-09-21T10:00:00.000+00:00',
            'pagination': {
              'page': 1,
              'pageSize': 20,
              'totalItems': 1,
              'totalPages': 1,
            },
          },
        }),
      );
      final client = buildClient(adapter);

      final envelope = await client.getEnvelope('/api/products');

      expect((envelope.data as List).single['id'], 'p1');
      expect(envelope.meta['pagination'], {
        'page': 1,
        'pageSize': 20,
        'totalItems': 1,
        'totalPages': 1,
      });
    });

    test('should throw ApiException with code and field on 4xx', () async {
      final adapter = FakeHttpAdapter(
        (options) async => jsonResponse(
          errorEnvelope(
            code: 'CNPJ_INVALID',
            message: 'O número do CNPJ é inválido.',
            field: 'cnpj',
          ),
          statusCode: 422,
        ),
      );
      final client = buildClient(adapter);

      final error = await client
          .post('/api/companies', data: {})
          .then<Object?>((_) => null)
          .catchError((Object e) => e);

      expect(error, isA<ApiException>());
      final exception = error as ApiException;
      expect(exception.statusCode, 422);
      expect(exception.code, 'CNPJ_INVALID');
      expect(exception.details.single.field, 'cnpj');
    });

    test('should refresh once on 401 and retry with the new token', () async {
      var productCalls = 0;
      final adapter = FakeHttpAdapter((options) async {
        if (options.path == '/api/products') {
          productCalls++;
          if (productCalls == 1) {
            return jsonResponse(
              errorEnvelope(
                code: 'SESSION_EXPIRED',
                message: 'Sessão expirada.',
              ),
              statusCode: 401,
            );
          }

          expect(options.headers['Authorization'], 'Bearer access-2');
          return jsonResponse(successEnvelope([]));
        }

        return jsonResponse(
          errorEnvelope(code: 'NOT_FOUND', message: 'x'),
          statusCode: 404,
        );
      });

      var refreshCalls = 0;
      final refreshAdapter = FakeHttpAdapter((options) async {
        refreshCalls++;
        expect(options.path, '/api/auth/refresh');
        return jsonResponse(
          successEnvelope({
            'accessToken': 'access-2',
            'refreshToken': 'refresh-2',
            'accessTokenExpiresAt': '2026-09-21T10:15:00Z',
            'refreshTokenExpiresAt': '2026-09-28T10:00:00Z',
            'session': {'userId': 'u1', 'role': 'Buyer', 'companyId': 'c1'},
          }),
        );
      });

      final client = buildClient(adapter, refreshAdapter: refreshAdapter);

      final data = await client.get('/api/products');

      expect(data, isEmpty);
      expect(productCalls, 2);
      expect(refreshCalls, 1);
      expect((await tokenStore.read())!.accessToken, 'access-2');
    });

    test(
      'should clear tokens and notify session expiry when refresh fails',
      () async {
        final adapter = FakeHttpAdapter(
          (options) async => jsonResponse(
            errorEnvelope(code: 'SESSION_EXPIRED', message: 'Sessão expirada.'),
            statusCode: 401,
          ),
        );
        final refreshAdapter = FakeHttpAdapter(
          (options) async => jsonResponse(
            errorEnvelope(code: 'SESSION_EXPIRED', message: 'Sessão expirada.'),
            statusCode: 401,
          ),
        );

        var expired = false;
        sessionEvents.onExpired.listen((_) => expired = true);

        final client = buildClient(adapter, refreshAdapter: refreshAdapter);

        await expectLater(
          client.get('/api/products'),
          throwsA(isA<ApiException>()),
        );
        await Future<void>.delayed(Duration.zero);

        expect(await tokenStore.read(), isNull);
        expect(expired, isTrue);
      },
    );

    test('should not refresh when the failing call is the login', () async {
      var refreshCalls = 0;
      final adapter = FakeHttpAdapter(
        (options) async => jsonResponse(
          errorEnvelope(
            code: 'INVALID_CREDENTIALS',
            message: 'E-mail ou senha inválidos.',
          ),
          statusCode: 401,
        ),
      );
      final refreshAdapter = FakeHttpAdapter((options) async {
        refreshCalls++;
        return jsonResponse(successEnvelope({}));
      });

      final client = buildClient(adapter, refreshAdapter: refreshAdapter);

      await expectLater(
        client.post('/api/auth/login', data: {'email': 'x', 'password': 'y'}),
        throwsA(isA<ApiException>()),
      );
      expect(refreshCalls, 0);
    });
  });
}
