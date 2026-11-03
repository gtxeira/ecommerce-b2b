import 'package:ecommerce_b2b/modules/shared_kernel/model/common/ids/company_id.dart';
import 'package:flutter/foundation.dart';

@immutable
class CustomerAssignment {
  final CompanyId companyId;

  /// Representante dono desta carteira. A API devolve no modo pessoal e no
  /// consolidado da equipe.
  final String? representativeId;
  final String? representativeName;

  const CustomerAssignment(
    this.companyId, {
    this.representativeId,
    this.representativeName,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CustomerAssignment &&
          runtimeType == other.runtimeType &&
          companyId == other.companyId &&
          representativeId == other.representativeId &&
          representativeName == other.representativeName;

  @override
  int get hashCode =>
      companyId.hashCode ^
      representativeId.hashCode ^
      representativeName.hashCode;
}
