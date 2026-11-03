import 'package:ecommerce_b2b/modules/shared_kernel/model/common/ids/representative_id.dart';
import 'package:flutter/foundation.dart';

@immutable
class SalesHierarchyLink {
  final RepresentativeId supervisorId;
  final RepresentativeId subordinateId;

  const SalesHierarchyLink({
    required this.supervisorId,
    required this.subordinateId,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SalesHierarchyLink &&
          runtimeType == other.runtimeType &&
          supervisorId == other.supervisorId &&
          subordinateId == other.subordinateId;

  @override
  int get hashCode => supervisorId.hashCode ^ subordinateId.hashCode;
}
