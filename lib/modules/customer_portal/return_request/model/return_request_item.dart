import 'package:ecommerce_b2b/modules/shared_kernel/model/finance/value_objects/quantity.dart';
import 'package:ecommerce_b2b/modules/shared_kernel/model/common/ids/product_id.dart';
import 'package:flutter/foundation.dart';

@immutable
class ReturnRequestItem {
  final ProductId productId;
  final String? productName;
  final String? productSku;
  final Quantity quantity;
  final String problemDescription;

  const ReturnRequestItem({
    required this.productId,
    this.productName,
    this.productSku,
    required this.quantity,
    required this.problemDescription,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ReturnRequestItem &&
          runtimeType == other.runtimeType &&
          productId == other.productId &&
          productName == other.productName &&
          productSku == other.productSku &&
          quantity == other.quantity &&
          problemDescription == other.problemDescription;

  @override
  int get hashCode =>
      productId.hashCode ^
      productName.hashCode ^
      productSku.hashCode ^
      quantity.hashCode ^
      problemDescription.hashCode;
}
