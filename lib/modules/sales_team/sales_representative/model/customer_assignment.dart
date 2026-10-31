import 'package:ecommerce_b2b/modules/shared_kernel/model/common/ids/company_id.dart';
import 'package:flutter/foundation.dart';

@immutable
class CustomerAssignment {
  final CompanyId companyId;

  const CustomerAssignment(this.companyId);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CustomerAssignment &&
          runtimeType == other.runtimeType &&
          companyId == other.companyId;

  @override
  int get hashCode => companyId.hashCode;
}
