import 'package:ecommerce_b2b/modules/sales_team/sales_representative/model/commission.dart';
import 'package:ecommerce_b2b/modules/sales_team/sales_representative/model/customer_assignment.dart';
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
}
