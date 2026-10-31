import 'package:ecommerce_b2b/modules/shared_kernel/model/common/ids/product_id.dart';
import 'package:ecommerce_b2b/modules/shared_kernel/model/finance/value_objects/money.dart';
import 'package:ecommerce_b2b/modules/shared_kernel/model/finance/value_objects/quantity.dart';
import 'package:flutter/foundation.dart';

@immutable
class QuoteItem {
  final ProductId productId;
  final Quantity quantity;
  final Money unitPrice;

  /// Tabela usada na precificação. Necessária para criar o orçamento na API.
  final String? priceTableId;

  const QuoteItem({
    required this.productId,
    required this.quantity,
    required this.unitPrice,
    this.priceTableId,
  });

  Money get subtotal => Money.create(
    unitPrice.amount * quantity.value,
    currency: unitPrice.currency,
  ).getOrThrow();

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is QuoteItem &&
          runtimeType == other.runtimeType &&
          productId == other.productId &&
          quantity == other.quantity &&
          unitPrice == other.unitPrice;

  @override
  int get hashCode =>
      productId.hashCode ^ quantity.hashCode ^ unitPrice.hashCode;
}
