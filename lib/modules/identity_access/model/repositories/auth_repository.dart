import 'package:ecommerce_b2b/modules/identity_access/model/user_session.dart';
import 'package:ecommerce_b2b/modules/shared_kernel/model/contact/value_objects/email_address.dart';
import 'package:ecommerce_b2b/app/core/result/result.dart';
import 'package:ecommerce_b2b/app/core/errors/app_error.dart';

abstract class AuthRepository {
  Future<Result<UserSession, AppError>> login(
    EmailAddress email,
    String password,
  );
  Future<UserSession?> getCurrentSession();
  Future<void> logout();
}
