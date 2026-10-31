import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';

/// Adaptador HTTP controlável para testes: evita rede e permite sequências
/// (ex.: 401 -> refresh -> 200).
class FakeHttpAdapter implements HttpClientAdapter {
  final Future<ResponseBody> Function(RequestOptions options) handler;
  final List<RequestOptions> requests = [];

  FakeHttpAdapter(this.handler);

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) {
    requests.add(options);
    return handler(options);
  }

  @override
  void close({bool force = false}) {}
}

ResponseBody jsonResponse(Object? body, {int statusCode = 200}) {
  return ResponseBody.fromString(
    jsonEncode(body),
    statusCode,
    headers: {
      Headers.contentTypeHeader: ['application/json'],
    },
  );
}

Map<String, dynamic> successEnvelope(Object? data) => {
  'data': data,
  'meta': {'timestamp': '2026-09-21T10:00:00.000+00:00'},
};

Map<String, dynamic> errorEnvelope({
  required String code,
  required String message,
  String? field,
}) => {
  'errors': [
    {
      'code': code,
      'message': message,
      'details': [
        if (field != null) {'field': field},
      ],
    },
  ],
  'meta': {'timestamp': '2026-09-21T10:00:00.000+00:00'},
};
