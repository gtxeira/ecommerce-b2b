import 'package:ecommerce_b2b/modules/identity_access/model/user_session.dart';
import 'package:ecommerce_b2b/modules/sales_team/sales_representative/model/commission.dart';

/// Quem pode alterar o status de uma comissão.
///
/// Finance/Admin operam qualquer comissão. O supervisor só opera as dos
/// subordinados: quem recebe a comissão não pode dar a própria como paga
/// (autoaprovação). Representante é somente leitura.
bool canManageCommissionStatus(UserSession session, Commission commission) {
  if (session.isFinance || session.isAdmin) return true;
  if (!session.isSupervisor) return false;

  final ownerId = commission.representativeId;
  if (ownerId == null || ownerId.isEmpty) return false;

  return ownerId != session.userId.value;
}
