import 'package:ecommerce_b2b/modules/identity_access/model/enums/user_role.dart';

class UserAccount {
  final String id;
  final String fullName;
  final String email;
  final UserRole role;
  final String? companyId;
  final String? companyName;
  final String? companyLegalName;
  final String? phone;
  final String? positionTitle;
  final bool active;

  const UserAccount({
    required this.id,
    required this.fullName,
    required this.email,
    required this.role,
    required this.companyId,
    this.companyName,
    this.companyLegalName,
    this.phone,
    this.positionTitle,
    required this.active,
  });
}
