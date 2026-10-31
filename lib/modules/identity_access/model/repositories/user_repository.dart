import 'package:ecommerce_b2b/modules/identity_access/model/enums/user_role.dart';
import 'package:ecommerce_b2b/modules/identity_access/model/user_account.dart';

/// Gestão de usuários (exclusiva do papel Admin na API).
abstract class UserRepository {
  Future<List<UserAccount>> findAll({
    UserRole? role,
    String? companyId,
    bool? active,
    String? search,
  });

  Future<UserAccount> create({
    required String fullName,
    required String email,
    required String password,
    required UserRole role,
    String? companyId,
  });

  Future<UserAccount> update({
    required String id,
    required String fullName,
    required UserRole role,
    String? companyId,
    required bool active,
  });

  Future<void> resetPassword({required String id, required String newPassword});
}
