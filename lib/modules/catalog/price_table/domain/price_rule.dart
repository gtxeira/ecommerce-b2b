import 'package:ecommerce_b2b/modules/shared_kernel/domain/address/enums/state.dart';
import 'package:ecommerce_b2b/modules/shared_kernel/domain/finance/value_objects/money.dart';
import 'package:ecommerce_b2b/modules/shared_kernel/domain/finance/value_objects/quantity.dart';
import 'package:ecommerce_b2b/modules/shared_kernel/domain/common/ids/product_id.dart';
import 'package:ecommerce_b2b/modules/shared_kernel/domain/common/ids/product_variant_id.dart';
import 'package:flutter/foundation.dart';

@immutable
class PriceRule {
  final ProductId productId;
  final ProductVariantId? variantId;
  final Quantity minQuantity;
  final Quantity maxQuantity;
  final State? state;
  final Money unitPrice;

  const PriceRule({
    required this.productId,
    this.variantId,
    required this.minQuantity,
    required this.maxQuantity,
    this.state,
    required this.unitPrice,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PriceRule &&
          runtimeType == other.runtimeType &&
          minQuantity == other.minQuantity &&
          maxQuantity == other.maxQuantity &&
          state == other.state &&
          unitPrice == other.unitPrice;

  @override
  int get hashCode =>
      minQuantity.hashCode ^
      maxQuantity.hashCode ^
      state.hashCode ^
      unitPrice.hashCode;
}
