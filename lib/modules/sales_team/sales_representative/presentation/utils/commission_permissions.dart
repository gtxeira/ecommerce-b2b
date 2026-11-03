import 'package:ecommerce_b2b/modules/identity_access/model/user_session.dart';
import 'package:ecommerce_b2b/modules/sales_team/sales_representative/model/commission.dart';
import 'package:ecommerce_b2b/modules/sales_team/sales_representative/model/enums/commission_status.dart';

/// Ações de status que a sessão pode executar nesta comissão.
///
/// - Finance/Admin: `Paid` e `Cancelled` em qualquer comissão.
/// - Supervisor: somente `Cancelled`, e apenas nas comissões dos subordinados.
///   Marcar como paga é exclusivo do backoffice financeiro.
/// - Representante: somente leitura.
Set<CommissionStatus> allowedCommissionStatusActions(
  UserSession session,
  Commission commission,
) {
  if (session.isFinance || session.isAdmin) {
    return const {CommissionStatus.paid, CommissionStatus.cancelled};
  }

  if (!session.isSupervisor) return const {};

  final ownerId = commission.representativeId;
  if (ownerId == null || ownerId.isEmpty || ownerId == session.userId.value) {
    return const {};
  }

  return const {CommissionStatus.cancelled};
}
