import 'package:ecommerce_b2b/app/core/network/json_read.dart';
import 'package:ecommerce_b2b/modules/shared_kernel/model/address/enums/state.dart';
import 'package:ecommerce_b2b/modules/shared_kernel/model/finance/value_objects/money.dart';
import 'package:flutter/foundation.dart';

/// Explicação congelada do desconto de um item de orçamento/pedido.
///
/// O preço unitário continua no item; aqui fica o "porque" (tabela, faixa e UF)
/// e o preço de catálogo usado como referência.
@immutable
class PricingExplanation {
  final Money referenceUnitPrice;
  final Money discountPerUnit;
  final Money discountTotal;
  final double discountPercentage;
  final String priceTableId;
  final String priceTableName;
  final String scopeType;
  final int minQuantity;
  final int maxQuantity;
  final String? state;

  const PricingExplanation({
    required this.referenceUnitPrice,
    required this.discountPerUnit,
    required this.discountTotal,
    required this.discountPercentage,
    required this.priceTableId,
    required this.priceTableName,
    required this.scopeType,
    required this.minQuantity,
    required this.maxQuantity,
    this.state,
  });

  factory PricingExplanation.fromJson(Map<String, dynamic> json) =>
      PricingExplanation(
        referenceUnitPrice: Money.create(
          readDouble(json, 'referenceUnitPrice'),
        ).getOrThrow(),
        discountPerUnit: Money.create(
          readDouble(json, 'discountPerUnit'),
        ).getOrThrow(),
        discountTotal: Money.create(
          readDouble(json, 'discountTotal'),
        ).getOrThrow(),
        discountPercentage: readDouble(json, 'discountPercentage'),
        priceTableId: readString(json, 'priceTableId'),
        priceTableName: readString(json, 'priceTableName'),
        scopeType: readString(json, 'scopeType'),
        minQuantity: readInt(json, 'minQuantity'),
        maxQuantity: readInt(json, 'maxQuantity'),
        state: readNullableString(json, 'state'),
      );

  /// "São Paulo (SP)"; regra sem UF é nacional.
  String get locationLabel {
    final currentState = state;
    if (currentState == null || currentState.isEmpty) return 'Nacional';
    return State.fromApiName(
      currentState,
    ).fold((_) => currentState, (value) => '${value.name} (${value.code})');
  }

  String get rangeLabel => '$minQuantity–$maxQuantity un.';
}
