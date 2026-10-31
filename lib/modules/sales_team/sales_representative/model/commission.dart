import 'package:ecommerce_b2b/modules/sales_team/sales_representative/model/enums/commission_status.dart';
import 'package:ecommerce_b2b/modules/shared_kernel/model/finance/value_objects/money.dart';
import 'package:ecommerce_b2b/modules/shared_kernel/model/finance/value_objects/percentage.dart';
import 'package:flutter/foundation.dart';

@immutable
class Commission {
  final Money baseAmount;
  final Percentage rate;
  final Money amount;
  final CommissionStatus status;

  /// Pedido que originou a comissão (nulo nas comissões históricas do seed).
  final String? orderId;

  const Commission({
    required this.baseAmount,
    required this.rate,
    required this.amount,
    required this.status,
    this.orderId,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Commission &&
          runtimeType == other.runtimeType &&
          baseAmount == other.baseAmount &&
          rate == other.rate &&
          amount == other.amount &&
          status == other.status &&
          orderId == other.orderId;

  @override
  int get hashCode =>
      baseAmount.hashCode ^
      rate.hashCode ^
      amount.hashCode ^
      status.hashCode ^
      orderId.hashCode;
}
