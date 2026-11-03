import 'package:ecommerce_b2b/app/core/network/json_read.dart';
import 'package:ecommerce_b2b/modules/shared_kernel/model/address/enums/state.dart';
import 'package:ecommerce_b2b/modules/shared_kernel/model/finance/value_objects/money.dart';
import 'package:flutter/foundation.dart';

/// Faixa de desconto elegível para a UF da empresa.
@immutable
class PriceTier {
  final String productId;
  final String? productName;
  final String? productSku;

  /// Variante da regra. Nula quando a faixa vale para o produto inteiro.
  final String? variantId;
  final String? variantSku;
  final String? variantLabel;

  final String priceTableId;
  final String priceTableName;
  final String scopeType;
  final int minQuantity;
  final int maxQuantity;
  final String? state;

  /// Empresa dona da condição quando o escopo efetivo é `customerSpecific`.
  final String? companyId;

  final Money unitPrice;
  final Money referenceUnitPrice;
  final Money discountPerUnit;
  final double discountPercentage;

  const PriceTier({
    required this.productId,
    this.productName,
    this.productSku,
    this.variantId,
    this.variantSku,
    this.variantLabel,
    required this.priceTableId,
    required this.priceTableName,
    required this.scopeType,
    required this.minQuantity,
    required this.maxQuantity,
    this.state,
    this.companyId,
    required this.unitPrice,
    required this.referenceUnitPrice,
    required this.discountPerUnit,
    required this.discountPercentage,
  });

  factory PriceTier.fromJson(Map<String, dynamic> json) => PriceTier(
    productId: readString(json, 'productId'),
    productName: readNullableString(json, 'productName'),
    productSku: readNullableString(json, 'productSku'),
    variantId: readNullableString(json, 'variantId'),
    variantSku: readNullableString(json, 'variantSku'),
    variantLabel: readNullableString(json, 'variantLabel'),
    priceTableId: readString(json, 'priceTableId'),
    priceTableName: readString(json, 'priceTableName'),
    scopeType: readString(json, 'scopeType'),
    minQuantity: readInt(json, 'minQuantity'),
    maxQuantity: readInt(json, 'maxQuantity'),
    state: readNullableString(json, 'state'),
    companyId: readNullableString(json, 'companyId'),
    unitPrice: Money.create(readDouble(json, 'unitPrice')).getOrThrow(),
    referenceUnitPrice: Money.create(
      readDouble(json, 'referenceUnitPrice'),
    ).getOrThrow(),
    discountPerUnit: Money.create(
      readDouble(json, 'discountPerUnit'),
    ).getOrThrow(),
    discountPercentage: readDouble(json, 'discountPercentage'),
  );

  String get locationLabel {
    final currentState = state;
    if (currentState == null || currentState.isEmpty) return 'Nacional';
    return State.fromApiName(
      currentState,
    ).fold((_) => currentState, (value) => '${value.name} (${value.code})');
  }

  String get rangeLabel => maxQuantity >= 9999
      ? 'A partir de $minQuantity un.'
      : 'De $minQuantity a $maxQuantity un.';
}

/// Faixas que valem para uma variante: as específicas dela quando existem; senão
/// as de produto (que também se aplicam à variante, pela precedência da API).
List<PriceTier> applicableTiers(
  Iterable<PriceTier> tiers, {
  String? variantId,
}) {
  final productTiers = tiers.where((tier) => tier.variantId == null).toList();
  if (variantId == null) return productTiers;

  final variantTiers = tiers
      .where((tier) => tier.variantId == variantId)
      .toList();
  return variantTiers.isNotEmpty ? variantTiers : productTiers;
}
