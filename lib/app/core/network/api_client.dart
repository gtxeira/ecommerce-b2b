// ignore_for_file: prefer_initializing_formals
import 'package:dio/dio.dart';

import 'package:ecommerce_b2b/app/core/network/api_config.dart';
import 'package:ecommerce_b2b/app/core/network/api_exception.dart';
import 'package:ecommerce_b2b/app/core/network/session_events.dart';
import 'package:ecommerce_b2b/app/core/network/token_store.dart';

/// Envelope de sucesso já desembrulhado: o `data` e o `meta` da resposta.
typedef ApiEnvelope = ({dynamic data, Map<String, dynamic> meta});

/// Cliente HTTP único da aplicação.
///
/// Responsabilidades:
/// - anexar o Bearer em toda requisição;
/// - desembrulhar o envelope `{ data, meta }`;
/// - traduzir `{ errors, meta }` para [ApiException];
/// - renovar o access token uma única vez em caso de 401, inclusive com
///   requisições concorrentes.
class ApiClient {
  final Dio _dio;
  final Dio _refreshDio;
  final TokenStore _tokenStore;
  final SessionEvents _sessionEvents;

  Future<bool>? _refreshing;

  ApiClient({
    String? baseUrl,
    Dio? dio,
    Dio? refreshDio,
    required TokenStore tokenStore,
    required SessionEvents sessionEvents,
  }) : _tokenStore = tokenStore,
       _sessionEvents = sessionEvents,
       _dio = dio ?? Dio(),
       _refreshDio = refreshDio ?? Dio() {
    final options = BaseOptions(
      baseUrl: baseUrl ?? ApiConfig.baseUrl,
      connectTimeout: ApiConfig.connectTimeout,
      receiveTimeout: ApiConfig.receiveTimeout,
      contentType: 'application/json',
      responseType: ResponseType.json,
    );

    _dio.options = options;
    _refreshDio.options = options;
  }

  Future<dynamic> get(String path, {Map<String, dynamic>? query}) =>
      _request('GET', path, query: query);

  /// GET que preserva o envelope: devolve `data` e o `meta` (ex.: `meta.pagination`).
  /// Usado pelas listagens paginadas, que precisam do total de páginas além dos itens.
  Future<ApiEnvelope> getEnvelope(String path, {Map<String, dynamic>? query}) =>
      _requestEnvelope('GET', path, query: query);

  Future<dynamic> post(
    String path, {
    Object? data,
    Map<String, dynamic>? query,
  }) => _request('POST', path, data: data, query: query);

  Future<dynamic> patch(
    String path, {
    Object? data,
    Map<String, dynamic>? query,
  }) => _request('PATCH', path, data: data, query: query);

  Future<dynamic> delete(
    String path, {
    Object? data,
    Map<String, dynamic>? query,
  }) => _request('DELETE', path, data: data, query: query);

  Future<dynamic> _request(
    String method,
    String path, {
    Object? data,
    Map<String, dynamic>? query,
    bool retried = false,
  }) async {
    final envelope = await _requestEnvelope(
      method,
      path,
      data: data,
      query: query,
      retried: retried,
    );
    return envelope.data;
  }

  Future<ApiEnvelope> _requestEnvelope(
    String method,
    String path, {
    Object? data,
    Map<String, dynamic>? query,
    bool retried = false,
  }) async {
    final tokens = await _tokenStore.read();

    try {
      final response = await _dio.request<dynamic>(
        path,
        data: data,
        queryParameters: query,
        options: Options(
          method: method,
          headers: {
            if (tokens != null && tokens.accessToken.isNotEmpty)
              'Authorization': 'Bearer ${tokens.accessToken}',
          },
        ),
      );
      return _unwrapEnvelope(response);
    } on DioException catch (error) {
      final status = error.response?.statusCode;
      if (status == 401 && !retried && !_isAuthPath(path)) {
        final refreshed = await _refresh();
        if (refreshed) {
          return _requestEnvelope(
            method,
            path,
            data: data,
            query: query,
            retried: true,
          );
        }
      }
      throw ApiException.fromDio(error);
    } on ApiException {
      rethrow;
    } catch (error) {
      throw ApiException.network(error);
    }
  }

  Future<bool> _refresh() async {
    final current = _refreshing;
    if (current != null) return current;

    final future = _performRefresh();
    _refreshing = future;
    try {
      return await future;
    } finally {
      _refreshing = null;
    }
  }

  Future<bool> _performRefresh() async {
    final tokens = await _tokenStore.read();
    if (tokens == null || tokens.refreshToken.isEmpty) {
      await _tokenStore.clear();
      _sessionEvents.notifyExpired();
      return false;
    }

    try {
      final response = await _refreshDio.post<dynamic>(
        '/api/auth/refresh',
        data: {'refreshToken': tokens.refreshToken},
      );
      final data = _unwrap(response);
      if (data is! Map) return false;

      await _tokenStore.save(
        AuthTokens.fromJson(Map<String, dynamic>.from(data)),
      );
      return true;
    } on DioException {
      await _tokenStore.clear();
      _sessionEvents.notifyExpired();
      return false;
    } catch (_) {
      await _tokenStore.clear();
      _sessionEvents.notifyExpired();
      return false;
    }
  }

  ApiEnvelope _unwrapEnvelope(Response<dynamic> response) {
    if (response.statusCode == 204) {
      return (data: null, meta: const <String, dynamic>{});
    }

    final body = response.data;
    if (body is Map) {
      final meta = body['meta'];
      return (
        data: body.containsKey('data') ? body['data'] : body,
        meta: meta is Map
            ? Map<String, dynamic>.from(meta)
            : const <String, dynamic>{},
      );
    }

    return (data: body, meta: const <String, dynamic>{});
  }

  dynamic _unwrap(Response<dynamic> response) {
    if (response.statusCode == 204) return null;
    final body = response.data;
    if (body is Map && body.containsKey('data')) {
      return body['data'];
    }
    return body;
  }

  bool _isAuthPath(String path) =>
      path.endsWith('/api/auth/login') || path.endsWith('/api/auth/refresh');
}
