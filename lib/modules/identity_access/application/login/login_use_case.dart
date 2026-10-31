import 'package:ecommerce_b2b/modules/identity_access/domain/repositories/auth_repository.dart';
import 'package:ecommerce_b2b/modules/identity_access/domain/user_session.dart';
import 'package:ecommerce_b2b/modules/shared_kernel/domain/contact/value_objects/email_address.dart';
import 'package:ecommerce_b2b/app/core/result/result.dart';
import 'package:ecommerce_b2b/app/core/errors/app_error.dart';

class LoginUseCase {
  final AuthRepository _authRepository;

  LoginUseCase(this._authRepository);

  Future<Result<UserSession, AppError>> execute(
    String email,
    String password,
  ) async {
    final trimmedEmail = email.trim();
    final emailResult = EmailAddress.create(trimmedEmail);

    if (emailResult.isFailure) {
      return Failure(
        const AppError(
          AppErrorCodes.invalidCredentials,
          'E-mail ou senha inválidos.',
        ),
      );
    }

    return await _authRepository.login(emailResult.getOrThrow(), password);
  }
}
