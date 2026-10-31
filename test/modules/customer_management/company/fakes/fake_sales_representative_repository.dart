import 'package:ecommerce_b2b/modules/sales_team/sales_representative/model/commission.dart';
import 'package:ecommerce_b2b/modules/sales_team/sales_representative/model/customer_assignment.dart';
import 'package:ecommerce_b2b/modules/sales_team/sales_representative/model/repositories/sales_representative_repository.dart';
import 'package:ecommerce_b2b/modules/sales_team/sales_representative/model/sales_representative.dart';
import 'package:ecommerce_b2b/modules/shared_kernel/model/common/ids/representative_id.dart';
import 'package:ecommerce_b2b/modules/shared_kernel/model/contact/value_objects/email_address.dart';
import 'package:ecommerce_b2b/modules/shared_kernel/model/finance/value_objects/percentage.dart';

class FakeSalesRepresentativeRepository
    implements SalesRepresentativeRepository {
  final List<SalesRepresentative> _reps = [];

  FakeSalesRepresentativeRepository() {
    _initializeMockData();
  }

  void _initializeMockData() {
    final supervisor = SalesRepresentative(
      id: const RepresentativeId('rep-supervisor'),
      fullName: 'Supervisor Mock',
      email: EmailAddress.create('supervisor@test.com').getOrThrow(),
      commissionRate: Percentage.create(3).getOrThrow(),
    );

    final rep456 = SalesRepresentative(
      id: const RepresentativeId('rep-456'),
      fullName: 'João Vendedor',
      email: EmailAddress.create('joao@empresa.com').getOrThrow(),
      commissionRate: Percentage.create(5).getOrThrow(),
    );

    supervisor.addSubordinate(rep456.id);
    rep456.setSupervisor(supervisor.id);

    _reps.addAll([supervisor, rep456]);
  }

  @override
  Future<SalesRepresentative?> findById(RepresentativeId id) async {
    try {
      return _reps.firstWhere((r) => r.id == id);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<List<SalesRepresentative>> findAll() async {
    return List.from(_reps);
  }

  /// Helper to add custom reps for specific test scenarios.
  void addRep(SalesRepresentative rep) {
    _reps.add(rep);
  }

  @override
  Future<List<Commission>> getCommissions({String? representativeId}) async {
    return _reps
        .where(
          (r) => representativeId == null || r.id.value == representativeId,
        )
        .expand((r) => r.commissions)
        .toList();
  }

  @override
  Future<List<CustomerAssignment>> getPortfolio({
    String? representativeId,
  }) async {
    return _reps
        .where(
          (r) => representativeId == null || r.id.value == representativeId,
        )
        .expand((r) => r.assignments)
        .toList();
  }
}
