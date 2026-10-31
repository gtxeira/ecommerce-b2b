import 'package:dio/dio.dart';

/// Detalhe de campo devolvido pela API em `errors[].details[]`.
class ApiErrorDetail {
  final String? field;

  const ApiErrorDetail({this.field});

  factory ApiErrorDetail.fromJson(Map<String, dynamic> json) =>
      ApiErrorDetail(field: json['field'] as String?);
}

/// Erro HTTP da API já traduzido do envelope `{ errors: [...], meta: ... }`.
///
/// O `code` é o contrato estável; a `message` é para exibição.
class ApiException implements Exception {
  final int statusCode;
  final String code;
  final String message;
  final List<ApiErrorDetail> details;

  const ApiException({
    required this.statusCode,
    required this.code,
    required this.message,
    this.details = const [],
  });

  bool get isUnauthorized => statusCode == 401;
  bool get isForbidden => statusCode == 403;
  bool get isNotFound => statusCode == 404;
  bool get isConflict => statusCode == 409;
  bool get isValidation => statusCode == 422;

  /// Constrói a partir do corpo padrão de erro da API. Quando o corpo não segue o
  /// envelope (ex.: proxy/rede), preserva o status e usa uma mensagem genérica.
  factory ApiException.fromDio(DioException error) {
    final response = error.response;
    final status = response?.statusCode ?? 0;
    final body = response?.data;

    if (body is Map<String, dynamic>) {
      final errors = body['errors'];
      if (errors is List && errors.isNotEmpty && errors.first is Map) {
        final first = Map<String, dynamic>.from(errors.first as Map);
        final details =
            (first['details'] as List?)
                ?.whereType<Map>()
                .map(
                  (d) => ApiErrorDetail.fromJson(Map<String, dynamic>.from(d)),
                )
                .toList() ??
            const <ApiErrorDetail>[];
        return ApiException(
          statusCode: status,
          code: (first['code'] as String?) ?? 'UNKNOWN',
          message: (first['message'] as String?) ?? _fallbackMessage(status),
          details: details,
        );
      }
    }

    return ApiException(
      statusCode: status,
      code: _fallbackCode(status),
      message: _fallbackMessage(status),
    );
  }

  factory ApiException.network(Object error) => ApiException(
    statusCode: 0,
    code: 'NETWORK_ERROR',
    message:
        'Não foi possível conectar à API. Verifique sua conexão e tente novamente.',
  );

  static String _fallbackCode(int status) => switch (status) {
    401 => 'UNAUTHORIZED',
    403 => 'FORBIDDEN',
    404 => 'RESOURCE_NOT_FOUND',
    409 => 'BUSINESS_RULE_VIOLATION',
    422 => 'VALIDATION_ERROR',
    _ => 'UNKNOWN',
  };

  static String _fallbackMessage(int status) => switch (status) {
    401 => 'Sessão expirada. Faça login novamente.',
    403 => 'Você não tem permissão para esta operação.',
    404 => 'Recurso não encontrado.',
    409 => 'A operação viola uma regra de negócio.',
    422 => 'Dados inválidos. Revise os campos e tente novamente.',
    _ => 'Falha ao comunicar com a API.',
  };

  @override
  String toString() => message;
}
