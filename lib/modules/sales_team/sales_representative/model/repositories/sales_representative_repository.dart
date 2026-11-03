import 'package:ecommerce_b2b/modules/sales_team/sales_representative/model/commission.dart';
import 'package:ecommerce_b2b/modules/sales_team/sales_representative/model/customer_assignment.dart';
import 'package:ecommerce_b2b/modules/sales_team/sales_representative/model/enums/commission_status.dart';
import 'package:ecommerce_b2b/modules/sales_team/sales_representative/model/sales_representative.dart';
import 'package:ecommerce_b2b/modules/shared_kernel/model/common/ids/representative_id.dart';

abstract class SalesRepresentativeRepository {
  Future<SalesRepresentative?> findById(RepresentativeId id);
  Future<List<SalesRepresentative>> findAll();

  /// Comissões do representante (GET /api/me/commissions).
  ///
  /// Com [teamScope], a API devolve o consolidado do supervisor e de todos os
  /// subordinados (inclui o próprio usuário).
  Future<List<Commission>> getCommissions({
    String? representativeId,
    bool teamScope = false,
  });

  /// Carteira do representante (GET /api/me/portfolio).
  Future<List<CustomerAssignment>> getPortfolio({
    String? representativeId,
    bool teamScope = false,
  });

  /// Altera o status de uma comissão (PATCH /api/me/commissions/{id}/status).
  ///
  /// A API só aceita `Pending -> Paid` e `Pending -> Cancelled`; estados finais
  /// respondem 409.
  Future<Commission> updateCommissionStatus({
    required int commissionId,
    required CommissionStatus status,
  });

  /// Comissões de todos os representantes (GET /api/commissions).
  ///
  /// Visão de backoffice: a API responde 403 para papéis que não sejam
  /// Finance/Admin.
  Future<List<Commission>> getAllCommissions();
}
