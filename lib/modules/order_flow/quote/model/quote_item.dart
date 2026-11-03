import 'package:ecommerce_b2b/modules/catalog/price_table/model/pricing_explanation.dart';
import 'package:ecommerce_b2b/modules/shared_kernel/model/common/ids/product_id.dart';
import 'package:ecommerce_b2b/modules/shared_kernel/model/finance/value_objects/money.dart';
import 'package:ecommerce_b2b/modules/shared_kernel/model/finance/value_objects/quantity.dart';
import 'package:flutter/foundation.dart';

@immutable
class QuoteItem {
  final ProductId productId;

  /// Nome do produto, resolvido pela API na leitura. Nulo quando o produto não
  /// existe mais ou em payloads antigos.
  final String? productName;

  /// SKU do produto, resolvido pela API na leitura.
  final String? productSku;

  /// Variante escolhida. Nula em itens de nível de produto ou antigos.
  final String? variantId;

  /// SKU da variante, resolvido pela API na leitura.
  final String? variantSku;

  /// Cor/tamanho/voltagem da variante, resolvida pela API.
  final String? variantLabel;

  final Quantity quantity;
  final Money unitPrice;

  /// Tabela usada na precificação. Necessária para criar o orçamento na API.
  final String? priceTableId;

  /// Explicação do desconto no momento da cotação. Nula quando o preço de
  /// catálogo prevaleceu ou em orçamentos antigos.
  final PricingExplanation? pricing;

  const QuoteItem({
    required this.productId,
    this.productName,
    this.productSku,
    this.variantId,
    this.variantSku,
    this.variantLabel,
    required this.quantity,
    required this.unitPrice,
    this.priceTableId,
    this.pricing,
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
          productName == other.productName &&
          productSku == other.productSku &&
          variantId == other.variantId &&
          variantSku == other.variantSku &&
          variantLabel == other.variantLabel &&
          quantity == other.quantity &&
          unitPrice == other.unitPrice &&
          priceTableId == other.priceTableId &&
          pricing == other.pricing;

  @override
  int get hashCode =>
      productId.hashCode ^
      productName.hashCode ^
      productSku.hashCode ^
      variantId.hashCode ^
      variantSku.hashCode ^
      variantLabel.hashCode ^
      quantity.hashCode ^
      unitPrice.hashCode ^
      priceTableId.hashCode ^
      pricing.hashCode;
}
