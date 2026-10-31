import 'package:flutter/foundation.dart';

/// Configuração de acesso à API.
///
/// Em runtime de desenvolvimento:
/// - Web/desktop: `http://localhost:5143`
/// - Emulador Android: `http://10.0.2.2:5143`
///
/// Para dispositivo físico ou ambiente remoto, passe
/// `--dart-define=API_BASE_URL=http://host:porta`.
class ApiConfig {
  ApiConfig._();

  static const String _configured = String.fromEnvironment('API_BASE_URL');

  static String get baseUrl {
    if (_configured.isNotEmpty) return _configured;
    if (kIsWeb) return 'http://localhost:5143';
    if (defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2:5143';
    }
    return 'http://localhost:5143';
  }

  static const Duration connectTimeout = Duration(seconds: 15);
  static const Duration receiveTimeout = Duration(seconds: 30);
}
