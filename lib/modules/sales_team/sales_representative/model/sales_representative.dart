import 'package:ecommerce_b2b/modules/shared_kernel/model/entity.dart';
import 'package:ecommerce_b2b/modules/shared_kernel/model/common/ids/representative_id.dart';
import 'package:ecommerce_b2b/modules/shared_kernel/model/contact/value_objects/email_address.dart';
import 'package:ecommerce_b2b/modules/shared_kernel/model/finance/value_objects/percentage.dart';
import 'package:ecommerce_b2b/modules/sales_team/sales_representative/model/commission.dart';
import 'package:ecommerce_b2b/modules/sales_team/sales_representative/model/customer_assignment.dart';
import 'package:ecommerce_b2b/modules/sales_team/sales_representative/model/sales_hierarchy_link.dart';

class SalesRepresentative extends Entity<RepresentativeId> {
  final String fullName;
  final EmailAddress email;
  final Percentage commissionRate;

  final List<CustomerAssignment> _assignments;
  final List<Commission> _commissions;
  SalesHierarchyLink? _supervisorLink;
  final List<SalesHierarchyLink> _subordinateLinks;

  SalesRepresentative({
    required RepresentativeId id,
    required this.fullName,
    required this.email,
    required this.commissionRate,
    List<CustomerAssignment>? assignments,
    List<Commission>? commissions,
    this._supervisorLink,
    List<SalesHierarchyLink>? subordinateLinks,
  })  : _assignments = assignments ?? [],
        _commissions = commissions ?? [],
        _subordinateLinks = subordinateLinks ?? [],
        super(id);

  List<CustomerAssignment> get assignments => List.unmodifiable(_assignments);
  List<Commission> get commissions => List.unmodifiable(_commissions);
  SalesHierarchyLink? get supervisorLink => _supervisorLink;
  List<SalesHierarchyLink> get subordinateLinks =>
      List.unmodifiable(_subordinateLinks);

  void assignCustomer(CustomerAssignment assignment) {
    if (!_assignments.contains(assignment)) {
      _assignments.add(assignment);
    }
  }

  void addCommission(Commission commission) {
    _commissions.add(commission);
  }

  void setSupervisor(RepresentativeId supervisorId) {
    _supervisorLink = SalesHierarchyLink(
      supervisorId: supervisorId,
      subordinateId: id,
    );
  }

  void addSubordinate(RepresentativeId subordinateId) {
    _subordinateLinks.add(SalesHierarchyLink(
      supervisorId: id,
      subordinateId: subordinateId,
    ));
  }
}
