// ignore_for_file: prefer_initializing_formals
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Par de tokens emitido por `/api/auth/login` e `/api/auth/refresh`.
class AuthTokens {
  final String accessToken;
  final String refreshToken;
  final DateTime? accessTokenExpiresAt;
  final DateTime? refreshTokenExpiresAt;

  const AuthTokens({
    required this.accessToken,
    required this.refreshToken,
    this.accessTokenExpiresAt,
    this.refreshTokenExpiresAt,
  });

  factory AuthTokens.fromJson(Map<String, dynamic> json) => AuthTokens(
    accessToken: json['accessToken'] as String? ?? '',
    refreshToken: json['refreshToken'] as String? ?? '',
    accessTokenExpiresAt: DateTime.tryParse(
      json['accessTokenExpiresAt'] as String? ?? '',
    ),
    refreshTokenExpiresAt: DateTime.tryParse(
      json['refreshTokenExpiresAt'] as String? ?? '',
    ),
  );

  Map<String, dynamic> toJson() => {
    'accessToken': accessToken,
    'refreshToken': refreshToken,
    'accessTokenExpiresAt': accessTokenExpiresAt?.toIso8601String(),
    'refreshTokenExpiresAt': refreshTokenExpiresAt?.toIso8601String(),
  };

  bool get isExpired {
    final expires = accessTokenExpiresAt;
    if (expires == null) return false;
    return DateTime.now().isAfter(
      expires.subtract(const Duration(seconds: 30)),
    );
  }
}

/// Persistência dos tokens. A implementação padrão usa secure storage com
/// fallback para shared_preferences (Web/ambientes sem keychain).
abstract class TokenStore {
  Future<AuthTokens?> read();
  Future<void> save(AuthTokens tokens);
  Future<void> clear();
}

class SecureTokenStore implements TokenStore {
  static const _key = 'ecommerce_b2b_tokens';

  final FlutterSecureStorage _secure;
  final bool _canUseSecureStorage;

  SecureTokenStore({
    FlutterSecureStorage secure = const FlutterSecureStorage(),
    bool? canUseSecureStorage,
  }) : _secure = secure,
       _canUseSecureStorage = canUseSecureStorage ?? !kIsWeb;

  @override
  Future<AuthTokens?> read() async {
    final raw = await _readRaw();
    if (raw == null || raw.isEmpty) return null;
    try {
      final json = jsonDecode(raw);
      if (json is! Map<String, dynamic>) return null;
      final tokens = AuthTokens.fromJson(json);
      if (tokens.accessToken.isEmpty || tokens.refreshToken.isEmpty) {
        return null;
      }
      return tokens;
    } on FormatException {
      await clear();
      return null;
    }
  }

  @override
  Future<void> save(AuthTokens tokens) async {
    final raw = jsonEncode(tokens.toJson());
    if (_canUseSecureStorage) {
      try {
        await _secure.write(key: _key, value: raw);
        return;
      } catch (_) {
        // Sem keychain (Web insegura, desktop sem libsecret): usa o fallback.
      }
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, raw);
  }

  @override
  Future<void> clear() async {
    if (_canUseSecureStorage) {
      try {
        await _secure.delete(key: _key);
      } catch (_) {
        // Ignora: o fallback pode ter sido o usado.
      }
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }

  Future<String?> _readRaw() async {
    if (_canUseSecureStorage) {
      try {
        final value = await _secure.read(key: _key);
        if (value != null) return value;
      } catch (_) {
        // Cai no fallback abaixo.
      }
    }

    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_key);
  }
}

/// Implementação em memória para testes.
class InMemoryTokenStore implements TokenStore {
  AuthTokens? _tokens;

  InMemoryTokenStore([this._tokens]);

  @override
  Future<AuthTokens?> read() async => _tokens;

  @override
  Future<void> save(AuthTokens tokens) async => _tokens = tokens;

  @override
  Future<void> clear() async => _tokens = null;
}
