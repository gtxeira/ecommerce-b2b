import 'package:ecommerce_b2b/modules/shared_kernel/model/common/ids/product_id.dart';
import 'package:ecommerce_b2b/modules/shared_kernel/model/common/ids/order_id.dart';
import 'package:ecommerce_b2b/modules/shared_kernel/model/finance/value_objects/quantity.dart';
import 'package:ecommerce_b2b/modules/inventory/warehouse/model/stock_reservation.dart';

class StockItem {
  final ProductId productId;
  Quantity _physicalQuantity;
  final List<StockReservation> _reservations;

  StockItem({
    required this.productId,
    required this._physicalQuantity,
    List<StockReservation>? reservations,
  })  : _reservations = reservations ?? [];

  Quantity get physicalQuantity => _physicalQuantity;
  
  Quantity get reservedQuantity {
    int total = 0;
    for (var res in _reservations) {
      total += res.quantity.value;
    }
    // We assume Quantity can be created from int since we already have that pattern
    return Quantity.create(total).getOrThrow();
  }

  Quantity get availableQuantity {
    return _physicalQuantity - reservedQuantity;
  }

  List<StockReservation> get reservations => List.unmodifiable(_reservations);

  void addReservation(StockReservation reservation) {
    if (availableQuantity.value < reservation.quantity.value) {
      throw StateError('Insufficient stock for reservation');
    }
    _reservations.add(reservation);
  }

  void removeReservation(OrderId orderId) {
    _reservations.removeWhere((res) => res.orderId == orderId);
  }

  void adjustPhysicalQuantity(Quantity newQuantity) {
    _physicalQuantity = newQuantity;
  }
}
