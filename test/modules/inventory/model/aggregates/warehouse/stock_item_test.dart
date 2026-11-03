import 'package:ecommerce_b2b/modules/inventory/warehouse/model/stock_item.dart';
import 'package:ecommerce_b2b/modules/inventory/warehouse/model/stock_reservation.dart';
import 'package:ecommerce_b2b/modules/shared_kernel/model/finance/value_objects/quantity.dart';
import 'package:ecommerce_b2b/modules/shared_kernel/model/common/ids/order_id.dart';
import 'package:ecommerce_b2b/modules/shared_kernel/model/common/ids/product_id.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('StockItem', () {
    final productId = ProductId('p1');
    final qty10 = Quantity.create(10).getOrThrow();
    final qty2 = Quantity.create(2).getOrThrow();

    /// deve calcular a quantidade disponível corretamente
    test('should calculate available quantity correctly', () {
      final stockItem = StockItem(
        productId: productId,
        physicalQuantity: qty10,
        reservations: [
          StockReservation(orderId: OrderId('o1'), quantity: qty2),
        ],
      );

      expect(stockItem.reservedQuantity.value, 2);
      expect(stockItem.availableQuantity.value, 8);
    });

    /// deve adicionar reserva se houver estoque disponível
    test('should add reservation if stock is available', () {
      final stockItem = StockItem(
        productId: productId,
        physicalQuantity: qty10,
      );
      stockItem.addReservation(
        StockReservation(orderId: OrderId('o1'), quantity: qty2),
      );

      expect(stockItem.reservedQuantity.value, 2);
    });

    /// deve lançar StateError ao adicionar reserva que excede o estoque disponível
    test(
      'should throw StateError when adding reservation exceeding available stock',
      () {
        final stockItem = StockItem(
          productId: productId,
          physicalQuantity: qty2,
        );
        final qty5 = Quantity.create(5).getOrThrow();

        expect(
          () => stockItem.addReservation(
            StockReservation(orderId: OrderId('o1'), quantity: qty5),
          ),
          throwsStateError,
        );
      },
    );
  });
}
