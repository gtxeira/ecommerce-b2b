import 'package:ecommerce_b2b/modules/shared_kernel/domain/finance/value_objects/quantity.dart';
import 'package:ecommerce_b2b/modules/shared_kernel/domain/common/ids/product_id.dart';
import 'package:flutter/foundation.dart';

@immutable
class ReturnRequestItem {
  final ProductId productId;
  final Quantity quantity;
  final String problemDescription;

  const ReturnRequestItem({
    required this.productId,
    required this.quantity,
    required this.problemDescription,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ReturnRequestItem &&
          runtimeType == other.runtimeType &&
          productId == other.productId &&
          quantity == other.quantity &&
          problemDescription == other.problemDescription;

  @override
  int get hashCode => productId.hashCode ^ quantity.hashCode ^ problemDescription.hashCode;
}
