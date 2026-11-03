import 'package:ecommerce_b2b/app/core/network/json_read.dart';
import 'package:ecommerce_b2b/modules/catalog/price_table/model/pricing_explanation.dart';
import 'package:ecommerce_b2b/modules/shared_kernel/model/address/enums/state.dart';
import 'package:ecommerce_b2b/modules/shared_kernel/model/finance/value_objects/money.dart';
import 'package:flutter/foundation.dart';

@immutable
class DiscountPreview {
  final Money perUnit;
  final Money total;
  final double percentage;

  const DiscountPreview({
    required this.perUnit,
    required this.total,
    required this.percentage,
  });

  factory DiscountPreview.fromJson(Map<String, dynamic> json) =>
      DiscountPreview(
        perUnit: Money.create(readDouble(json, 'perUnit')).getOrThrow(),
        total: Money.create(readDouble(json, 'total')).getOrThrow(),
        percentage: readDouble(json, 'percentage'),
      );
}

@immutable
class AppliedPriceRule {
  final String priceTableId;
  final String priceTableName;
  final String scopeType;
  final int minQuantity;
  final int maxQuantity;
  final String? state;

  const AppliedPriceRule({
    required this.priceTableId,
    required this.priceTableName,
    required this.scopeType,
    required this.minQuantity,
    required this.maxQuantity,
    this.state,
  });

  factory AppliedPriceRule.fromJson(Map<String, dynamic> json) =>
      AppliedPriceRule(
        priceTableId: readString(json, 'priceTableId'),
        priceTableName: readString(json, 'priceTableName'),
        scopeType: readString(json, 'scopeType'),
        minQuantity: readInt(json, 'minQuantity'),
        maxQuantity: readInt(json, 'maxQuantity'),
        state: readNullableString(json, 'state'),
      );

  String get locationLabel {
    final currentState = state;
    if (currentState == null || currentState.isEmpty) return 'Nacional';
    return State.fromApiName(
      currentState,
    ).fold((_) => currentState, (value) => '${value.name} (${value.code})');
  }

  String get rangeLabel => '$minQuantity–$maxQuantity un.';
}

@immutable
class NextPriceTier {
  final int minQuantity;
  final int maxQuantity;
  final Money unitPrice;
  final Money savingsPerUnit;
  final int unitsMissing;
  final String priceTableName;
  final String? state;

  const NextPriceTier({
    required this.minQuantity,
    required this.maxQuantity,
    required this.unitPrice,
    required this.savingsPerUnit,
    required this.unitsMissing,
    required this.priceTableName,
    this.state,
  });

  factory NextPriceTier.fromJson(Map<String, dynamic> json) => NextPriceTier(
    minQuantity: readInt(json, 'minQuantity'),
    maxQuantity: readInt(json, 'maxQuantity'),
    unitPrice: Money.create(readDouble(json, 'unitPrice')).getOrThrow(),
    savingsPerUnit: Money.create(
      readDouble(json, 'savingsPerUnit'),
    ).getOrThrow(),
    unitsMissing: readInt(json, 'unitsMissing'),
    priceTableName: readString(json, 'priceTableName'),
    state: readNullableString(json, 'state'),
  );

  String get locationLabel {
    final currentState = state;
    if (currentState == null || currentState.isEmpty) return 'Nacional';
    return State.fromApiName(
      currentState,
    ).fold((_) => currentState, (value) => '${value.name} (${value.code})');
  }
}

@immutable
class PricingPreview {
  final String productId;
  final int quantity;
  final Money unitPrice;
  final Money referenceUnitPrice;
  final Money subtotal;
  final DiscountPreview? discount;
  final AppliedPriceRule? appliedRule;
  final NextPriceTier? nextTier;

  const PricingPreview({
    required this.productId,
    required this.quantity,
    required this.unitPrice,
    required this.referenceUnitPrice,
    required this.subtotal,
    this.discount,
    this.appliedRule,
    this.nextTier,
  });

  factory PricingPreview.fromJson(Map<String, dynamic> json) => PricingPreview(
    productId: readString(json, 'productId'),
    quantity: readInt(json, 'quantity'),
    unitPrice: Money.create(readDouble(json, 'unitPrice')).getOrThrow(),
    referenceUnitPrice: Money.create(
      readDouble(json, 'referenceUnitPrice'),
    ).getOrThrow(),
    subtotal: Money.create(readDouble(json, 'subtotal')).getOrThrow(),
    discount: json['discount'] is Map
        ? DiscountPreview.fromJson(
            Map<String, dynamic>.from(json['discount'] as Map),
          )
        : null,
    appliedRule: json['appliedRule'] is Map
        ? AppliedPriceRule.fromJson(
            Map<String, dynamic>.from(json['appliedRule'] as Map),
          )
        : null,
    nextTier: json['nextTier'] is Map
        ? NextPriceTier.fromJson(
            Map<String, dynamic>.from(json['nextTier'] as Map),
          )
        : null,
  );

  /// Converte o preview no snapshot que a lista de itens do orçamento exibe
  /// antes de salvar. A API continua sendo a autoridade no momento do save.
  PricingExplanation? toExplanation() {
    final currentDiscount = discount;
    final rule = appliedRule;
    if (currentDiscount == null || rule == null) return null;

    return PricingExplanation(
      referenceUnitPrice: referenceUnitPrice,
      discountPerUnit: currentDiscount.perUnit,
      discountTotal: currentDiscount.total,
      discountPercentage: currentDiscount.percentage,
      priceTableId: rule.priceTableId,
      priceTableName: rule.priceTableName,
      scopeType: rule.scopeType,
      minQuantity: rule.minQuantity,
      maxQuantity: rule.maxQuantity,
      state: rule.state,
    );
  }
}
