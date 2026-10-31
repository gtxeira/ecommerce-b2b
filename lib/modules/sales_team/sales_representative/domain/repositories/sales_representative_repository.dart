import 'package:ecommerce_b2b/modules/sales_team/sales_representative/domain/commission.dart';
import 'package:ecommerce_b2b/modules/sales_team/sales_representative/domain/customer_assignment.dart';
import 'package:ecommerce_b2b/modules/sales_team/sales_representative/domain/sales_representative.dart';
import 'package:ecommerce_b2b/modules/shared_kernel/domain/common/ids/representative_id.dart';

abstract class SalesRepresentativeRepository {
  Future<SalesRepresentative?> findById(RepresentativeId id);
  Future<List<SalesRepresentative>> findAll();

  /// Comissões do representante (GET /api/me/commissions).
  Future<List<Commission>> getCommissions({String? representativeId});

  /// Carteira do representante (GET /api/me/portfolio).
  Future<List<CustomerAssignment>> getPortfolio({String? representativeId});
}
