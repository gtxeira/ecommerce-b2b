import 'package:ecommerce_b2b/app/core/network/api_client.dart';
import 'package:ecommerce_b2b/app/core/network/api_exception.dart';
import 'package:ecommerce_b2b/app/core/network/token_store.dart';
import 'package:ecommerce_b2b/modules/identity_access/domain/enums/user_role.dart';
import 'package:ecommerce_b2b/modules/identity_access/domain/repositories/auth_repository.dart';
import 'package:ecommerce_b2b/modules/identity_access/domain/user_session.dart';
import 'package:ecommerce_b2b/modules/shared_kernel/domain/auth/errors/auth_errors.dart';
import 'package:ecommerce_b2b/modules/shared_kernel/domain/common/ids/company_id.dart';
import 'package:ecommerce_b2b/modules/shared_kernel/domain/common/ids/user_id.dart';
import 'package:ecommerce_b2b/modules/shared_kernel/domain/contact/value_objects/email_address.dart';
import 'package:ecommerce_b2b/modules/shared_kernel/functional/result.dart';

/// Autenticação JWT contra a API.
///
/// O par de tokens fica no [TokenStore]; a sessão em memória é derivada do
/// `data.session` do login ou de `GET /api/auth/me`.
class ApiAuthRepository implements AuthRepository {
  final ApiClient _api;
  final TokenStore _tokenStore;

  ApiAuthRepository(this._api, this._tokenStore);

  @override
  Future<Result<UserSession, AuthError>> login(
    EmailAddress email,
    String password,
  ) async {
    try {
      final data = await _api.post(
        '/api/auth/login',
        data: {'email': email.value, 'password': password},
      );
      if (data is! Map) return Failure(InvalidCredentialsError());

      final map = Map<String, dynamic>.from(data);
      final tokens = AuthTokens.fromJson(map);
      if (tokens.accessToken.isEmpty || tokens.refreshToken.isEmpty) {
        return Failure(InvalidCredentialsError());
      }

      final session = _sessionFrom(map['session']);
      if (session == null) {
        return Failure(InvalidCredentialsError());
      }

      await _tokenStore.save(tokens);
      return Success(session);
    } on ApiException catch (error) {
      if (error.statusCode == 401) {
        return Failure(InvalidCredentialsError());
      }
      return Failure(UnauthorizedError(error.message));
    }
  }

  @override
  Future<UserSession?> getCurrentSession() async {
    final tokens = await _tokenStore.read();
    if (tokens == null) return null;

    try {
      final data = await _api.get('/api/auth/me');
      return _sessionFrom(data);
    } on ApiException catch (error) {
      if (error.statusCode == 401) {
        await _tokenStore.clear();
      }
      return null;
    }
  }

  @override
  Future<void> logout() async {
    try {
      await _api.post('/api/auth/logout');
    } on ApiException {
      // Sessão já inválida/API indisponível: a limpeza local vale de qualquer forma.
    } finally {
      await _tokenStore.clear();
    }
  }

  UserSession? _sessionFrom(dynamic value) {
    if (value is! Map) return null;
    final map = Map<String, dynamic>.from(value);
    final userId = map['userId'] as String?;
    final role = UserRole.fromApiName(map['role'] as String? ?? '');
    if (userId == null || userId.isEmpty || role == null) return null;

    final companyId = map['companyId'] as String?;
    if (role == UserRole.buyer && (companyId == null || companyId.isEmpty)) {
      return null;
    }

    return UserSession(
      userId: UserId(userId),
      role: role,
      companyId: companyId == null || companyId.isEmpty
          ? null
          : CompanyId(companyId),
    );
  }
}
