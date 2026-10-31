import 'package:ecommerce_b2b/modules/order_flow/sales_order/model/enums/finance_decision.dart';
import 'package:flutter/foundation.dart';

@immutable
class FinanceReview {
  final FinanceDecision decision;
  final String reviewerId;
  final DateTime reviewedAt;
  final String justification;

  const FinanceReview({
    required this.decision,
    required this.reviewerId,
    required this.reviewedAt,
    required this.justification,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FinanceReview &&
          runtimeType == other.runtimeType &&
          decision == other.decision &&
          reviewerId == other.reviewerId &&
          reviewedAt == other.reviewedAt &&
          justification == other.justification;

  @override
  int get hashCode =>
      decision.hashCode ^
      reviewerId.hashCode ^
      reviewedAt.hashCode ^
      justification.hashCode;
}
