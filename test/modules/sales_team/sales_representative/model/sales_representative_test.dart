import 'package:ecommerce_b2b/modules/sales_team/sales_representative/model/commission.dart';
import 'package:ecommerce_b2b/modules/sales_team/sales_representative/model/customer_assignment.dart';
import 'package:ecommerce_b2b/modules/sales_team/sales_representative/model/enums/commission_status.dart';
import 'package:ecommerce_b2b/modules/sales_team/sales_representative/model/sales_representative.dart';
import 'package:ecommerce_b2b/modules/shared_kernel/model/common/ids/company_id.dart';
import 'package:ecommerce_b2b/modules/shared_kernel/model/common/ids/representative_id.dart';
import 'package:ecommerce_b2b/modules/shared_kernel/model/contact/value_objects/email_address.dart';
import 'package:ecommerce_b2b/modules/shared_kernel/model/finance/value_objects/money.dart';
import 'package:ecommerce_b2b/modules/shared_kernel/model/finance/value_objects/percentage.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('SalesRepresentative', () {
    late SalesRepresentative rep;
    final repId = const RepresentativeId('r1');

    setUp(() {
      rep = SalesRepresentative(
        id: repId,
        fullName: 'Sales Rep',
        email: EmailAddress.create('rep@test.com').getOrThrow(),
        commissionRate: Percentage.create(5).getOrThrow(),
      );
    });

    // Deve atribuir um cliente corretamente.
    test('should assign customer', () {
      final assignment = CustomerAssignment(const CompanyId('c1'));
      rep.assignCustomer(assignment);
      expect(rep.assignments.length, 1);
      expect(rep.assignments.first, assignment);
    });

    // Deve adicionar uma comissão corretamente.
    test('should add commission', () {
      final commission = Commission(
        baseAmount: Money.create(1000).getOrThrow(),
        rate: Percentage.create(5).getOrThrow(),
        amount: Money.create(50).getOrThrow(),
        status: CommissionStatus.pending,
      );
      rep.addCommission(commission);
      expect(rep.commissions.length, 1);
      expect(rep.commissions.first, commission);
    });

    // Deve definir um supervisor e adicionar um subordinado.
    test('should set supervisor and add subordinate', () {
      const supervisorId = RepresentativeId('s1');
      const subordinateId = RepresentativeId('sub1');

      rep.setSupervisor(supervisorId);
      rep.addSubordinate(subordinateId);

      expect(rep.supervisorLink?.supervisorId, supervisorId);
      expect(rep.subordinateLinks.length, 1);
      expect(rep.subordinateLinks.first.subordinateId, subordinateId);
    });
  });
}
