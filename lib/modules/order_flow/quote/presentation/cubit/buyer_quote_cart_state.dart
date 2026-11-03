import 'package:ecommerce_b2b/modules/catalog/price_table/model/pricing_preview.dart';
import 'package:ecommerce_b2b/modules/order_flow/quote/model/quote_item.dart';
import 'package:ecommerce_b2b/modules/shared_kernel/model/common/ids/product_id.dart';
import 'package:ecommerce_b2b/modules/shared_kernel/model/finance/value_objects/money.dart';
import 'package:ecommerce_b2b/modules/shared_kernel/model/finance/value_objects/quantity.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';

/// Linha do carrinho de orçamento do comprador.
///
/// Guarda o necessário para exibir e para montar o [QuoteItem] no envio. O
/// preço é o preview da API no momento em que o item entrou; a API reprecifica
/// tudo no POST, então o valor aqui é apresentação, não a autoridade.
@immutable
class BuyerQuoteCartItem extends Equatable {
  final ProductId productId;

  /// Variante escolhida. Nula para produtos sem variação.
  final String? variantId;

  final String productName;
  final String? productSku;
  final String? variantSku;
  final String? variantLabel;

  final int quantity;

  /// Nulo quando o produto não tem faixa de desconto: a API usa o preço de
  /// catálogo (ou da variante).
  final String? priceTableId;

  final PricingPreview preview;

  const BuyerQuoteCartItem({
    required this.productId,
    this.variantId,
    required this.productName,
    this.productSku,
    this.variantSku,
    this.variantLabel,
    required this.quantity,
    this.priceTableId,
    required this.preview,
  });

  /// Identidade da linha: o mesmo produto com variantes diferentes são linhas
  /// distintas no orçamento.
  String get lineKey => '${productId.value}::${variantId ?? ''}';

  Money get subtotal => preview.subtotal;

  QuoteItem toQuoteItem() => QuoteItem(
    productId: productId,
    productName: productName,
    productSku: productSku,
    variantId: variantId,
    variantSku: variantSku,
    variantLabel: variantLabel,
    quantity: Quantity.create(quantity).getOrThrow(),
    unitPrice: preview.unitPrice,
    priceTableId: priceTableId,
    pricing: preview.toExplanation(),
  );

  @override
  List<Object?> get props => [
    productId,
    variantId,
    productName,
    productSku,
    variantSku,
    variantLabel,
    quantity,
    priceTableId,
    preview,
  ];
}

/// Itens que o comprador selecionou no catálogo antes de enviar o orçamento.
@immutable
class BuyerQuoteCartState extends Equatable {
  final List<BuyerQuoteCartItem> items;

  const BuyerQuoteCartState({this.items = const []});

  bool get isEmpty => items.isEmpty;

  bool get isNotEmpty => items.isNotEmpty;

  /// Quantidade total de unidades, usada no rótulo do FAB.
  int get itemCount => items.fold(0, (sum, item) => sum + item.quantity);

  Money get total {
    if (items.isEmpty) return Money.create(0).getOrThrow();
    var cents = 0;
    for (final item in items) {
      cents += item.subtotal.amountInCents;
    }
    return Money.create(
      cents / 100,
      currency: items.first.subtotal.currency,
    ).getOrThrow();
  }

  BuyerQuoteCartItem? itemFor(ProductId productId, {String? variantId}) {
    for (final item in items) {
      if (item.productId == productId && item.variantId == variantId) {
        return item;
      }
    }
    return null;
  }

  @override
  List<Object?> get props => [items];
}
