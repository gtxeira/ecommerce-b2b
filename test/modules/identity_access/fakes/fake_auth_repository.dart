import 'package:ecommerce_b2b/app/core/errors/app_error.dart';
import 'package:ecommerce_b2b/modules/identity_access/model/enums/user_role.dart';
import 'package:ecommerce_b2b/modules/identity_access/model/repositories/auth_repository.dart';
import 'package:ecommerce_b2b/modules/identity_access/model/user_session.dart';
import 'package:ecommerce_b2b/modules/shared_kernel/model/common/ids/company_id.dart';
import 'package:ecommerce_b2b/modules/shared_kernel/model/common/ids/user_id.dart';
import 'package:ecommerce_b2b/modules/shared_kernel/model/contact/value_objects/email_address.dart';
import 'package:ecommerce_b2b/app/core/result/result.dart';

class FakeAuthRepository implements AuthRepository {
  UserSession? _currentSession;
  late final Map<String, _FakeUserRecord> _users = {
    'buyer@test.com': _FakeUserRecord(
      userId: const UserId('buyer-001'),
      role: UserRole.buyer,
      companyId: CompanyId('c1'),
      password: 'password123',
    ),
    'rep@test.com': _FakeUserRecord(
      userId: const UserId('rep-456'),
      role: UserRole.representative,
      password: 'password123',
    ),
    'supervisor@test.com': _FakeUserRecord(
      userId: const UserId('rep-supervisor'),
      role: UserRole.supervisor,
      password: 'password123',
    ),
    'finance@test.com': _FakeUserRecord(
      userId: const UserId('finance-001'),
      role: UserRole.finance,
      password: 'password123',
    ),
    'admin@test.com': _FakeUserRecord(
      userId: const UserId('admin-001'),
      role: UserRole.admin,
      password: 'password123',
    ),
  };

  @override
  Future<Result<UserSession, AppError>> login(
    EmailAddress email,
    String password,
  ) async {
    final user = _users[email.value];
    if (user == null || user.password != password) {
      return Failure(
        const AppError(
          AppErrorCodes.invalidCredentials,
          'E-mail ou senha inválidos.',
        ),
      );
    }

    _currentSession = UserSession(
      userId: user.userId,
      role: user.role,
      companyId: user.companyId,
    );

    return Success(_currentSession!);
  }

  @override
  Future<UserSession?> getCurrentSession() async => _currentSession;

  @override
  Future<void> logout() async => _currentSession = null;
}

class _FakeUserRecord {
  final UserId userId;
  final UserRole role;
  final CompanyId? companyId;
  final String password;

  _FakeUserRecord({
    required this.userId,
    required this.role,
    this.companyId,
    required this.password,
  });
}
