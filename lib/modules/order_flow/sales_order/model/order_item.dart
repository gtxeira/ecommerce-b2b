import 'package:ecommerce_b2b/modules/shared_kernel/model/common/ids/product_id.dart';
import 'package:ecommerce_b2b/modules/shared_kernel/model/finance/value_objects/money.dart';
import 'package:ecommerce_b2b/modules/shared_kernel/model/finance/value_objects/quantity.dart';
import 'package:flutter/foundation.dart';

@immutable
class OrderItem {
  final ProductId productId;
  final Quantity quantity;
  final Money unitPriceSnapshot;

  const OrderItem({
    required this.productId,
    required this.quantity,
    required this.unitPriceSnapshot,
  });

  Money get subtotal => Money.create(
    unitPriceSnapshot.amount * quantity.value,
    currency: unitPriceSnapshot.currency,
  ).getOrThrow();

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is OrderItem &&
          runtimeType == other.runtimeType &&
          productId == other.productId &&
          quantity == other.quantity &&
          unitPriceSnapshot == other.unitPriceSnapshot;

  @override
  int get hashCode =>
      productId.hashCode ^ quantity.hashCode ^ unitPriceSnapshot.hashCode;
}
