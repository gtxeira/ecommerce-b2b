import 'package:ecommerce_b2b/modules/order_flow/sales_order/model/order_item.dart';
import 'package:ecommerce_b2b/modules/shared_kernel/model/finance/value_objects/quantity.dart';
import 'package:ecommerce_b2b/modules/shared_kernel/model/common/ids/product_id.dart';
import 'package:ecommerce_b2b/modules/shared_kernel/model/finance/value_objects/money.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('OrderItem', () {
    /// deve calcular o subtotal corretamente
    test('should calculate subtotal correctly', () {
      final unitPrice = Money.create(10.0).getOrThrow();
      final quantity = Quantity.create(5).getOrThrow();
      final item = OrderItem(
        productId: ProductId('p1'),
        quantity: quantity,
        unitPriceSnapshot: unitPrice,
      );

      expect(item.subtotal.amount, 50.0);
    });
  });
}
