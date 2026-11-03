import 'package:ecommerce_b2b/app/core/routes/order_routes.dart';
import 'package:ecommerce_b2b/modules/order_flow/model/enums/order_status.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('OrderRoutes', () {
    test('list aponta para /orders', () {
      expect(OrderRoutes.list, '/orders');
    });

    test('detailPattern declara o path parameter', () {
      expect(OrderRoutes.detailPattern, '/orders/:id');
    });

    test('detail monta a rota com o id', () {
      expect(OrderRoutes.detail('order-101'), '/orders/order-101');
    });

    test('detail escapa ids com caracteres especiais', () {
      expect(OrderRoutes.detail('a/b c'), '/orders/a%2Fb%20c');
    });

    test('listWithGroup monta a query do agrupamento', () {
      expect(
        OrderRoutes.listWithGroup(OrderStatusGroup.closed),
        '/orders?group=closed',
      );
      expect(
        OrderRoutes.listWithGroup(OrderStatusGroup.open),
        '/orders?group=open',
      );
    });
  });
}
