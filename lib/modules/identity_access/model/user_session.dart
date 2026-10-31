import 'package:ecommerce_b2b/modules/identity_access/model/enums/user_role.dart';
import 'package:ecommerce_b2b/modules/shared_kernel/model/common/ids/company_id.dart';
import 'package:ecommerce_b2b/modules/shared_kernel/model/common/ids/user_id.dart';

class UserSession {
  final UserId userId;
  final UserRole role;
  final CompanyId? companyId; // Relevante apenas para UserRole.buyer

  UserSession({required this.userId, required this.role, this.companyId}) {
    if (role == UserRole.buyer && companyId == null) {
      throw ArgumentError(
        'O ID da empresa é obrigatório para o perfil de comprador.',
      );
    }
  }

  bool get isBuyer => role == UserRole.buyer;
  bool get isRepresentative =>
      role == UserRole.representative || role == UserRole.supervisor;
  bool get isFinance => role == UserRole.finance;
  bool get isSupervisor => role == UserRole.supervisor;
}
