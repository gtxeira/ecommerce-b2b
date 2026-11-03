import 'package:ecommerce_b2b/modules/catalog/price_table/model/pricing_explanation.dart';
import 'package:ecommerce_b2b/modules/shared_kernel/model/common/ids/product_id.dart';
import 'package:ecommerce_b2b/modules/shared_kernel/model/finance/value_objects/money.dart';
import 'package:ecommerce_b2b/modules/shared_kernel/model/finance/value_objects/quantity.dart';
import 'package:flutter/foundation.dart';

@immutable
class OrderItem {
  final ProductId productId;

  /// Nome/SKU resolvidos pela API na leitura. `null` em payload antigo ou
  /// quando o produto não existe mais; a UI cai no fallback por ID.
  final String? productName;
  final String? productSku;

  final Quantity quantity;
  final Money unitPriceSnapshot;

  /// Snapshot da regra que explicou o desconto. Nulo quando o preço de
  /// catálogo prevaleceu ou em pedidos antigos.
  final PricingExplanation? pricing;

  const OrderItem({
    required this.productId,
    this.productName,
    this.productSku,
    required this.quantity,
    required this.unitPriceSnapshot,
    this.pricing,
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
          productName == other.productName &&
          productSku == other.productSku &&
          quantity == other.quantity &&
          unitPriceSnapshot == other.unitPriceSnapshot &&
          pricing == other.pricing;

  @override
  int get hashCode =>
      productId.hashCode ^
      productName.hashCode ^
      productSku.hashCode ^
      quantity.hashCode ^
      unitPriceSnapshot.hashCode ^
      pricing.hashCode;
}
