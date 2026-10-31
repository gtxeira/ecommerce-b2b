import 'package:ecommerce_b2b/modules/shared_kernel/model/common/ids/order_id.dart';
import 'package:ecommerce_b2b/modules/shared_kernel/model/finance/value_objects/quantity.dart';
import 'package:flutter/foundation.dart';

@immutable
class StockReservation {
  final OrderId orderId;
  final Quantity quantity;

  const StockReservation({
    required this.orderId,
    required this.quantity,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is StockReservation &&
          runtimeType == other.runtimeType &&
          orderId == other.orderId &&
          quantity == other.quantity;

  @override
  int get hashCode => orderId.hashCode ^ quantity.hashCode;
}
