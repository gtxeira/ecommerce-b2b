import 'package:ecommerce_b2b/modules/order_flow/model/enums/credit_status.dart';
import 'package:ecommerce_b2b/modules/order_flow/model/enums/order_status.dart';
import 'package:ecommerce_b2b/modules/order_flow/sales_order/model/repositories/sales_order_repository.dart';
import 'package:ecommerce_b2b/modules/order_flow/sales_order/model/sales_order.dart';
import 'package:ecommerce_b2b/modules/order_flow/sales_order/presentation/cubit/order_list_cubit.dart';
import 'package:ecommerce_b2b/modules/shared_kernel/model/common/ids/order_id.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockSalesOrderRepository extends Mock implements SalesOrderRepository {}

void main() {
  group('OrderListCubit', () {
    late MockSalesOrderRepository repository;
    late OrderListCubit cubit;

    SalesOrder order(String id, OrderStatus status) => SalesOrder(
      id: OrderId(id),
      status: status,
      creditStatus: CreditStatus.approved,
      items: const [],
    );

    final orders = [
      order('o1', OrderStatus.inTransit),
      order('o2', OrderStatus.pendingFinanceApproval),
      order('o3', OrderStatus.delivered),
      order('o4', OrderStatus.blockedByFinance),
      order('o5', OrderStatus.cancelled),
    ];

    setUp(() {
      repository = MockSalesOrderRepository();
      when(() => repository.getAll()).thenAnswer((_) async => orders);
      cubit = OrderListCubit(repository);
    });

    tearDown(() => cubit.close());

    test('initial state should be OrderListInitial', () {
      expect(cubit.state, isA<OrderListInitial>());
    });

    test('load emite Loaded com todos os pedidos', () async {
      await cubit.load();

      expect(cubit.state, isA<OrderListLoaded>());
      final state = cubit.state as OrderListLoaded;
      expect(state.allOrders, hasLength(orders.length));
    });

    test('load propaga falha do repositório', () async {
      when(() => repository.getAll()).thenThrow(Exception('boom'));

      await cubit.load();

      expect(cubit.state, isA<OrderListFailure>());
      expect((cubit.state as OrderListFailure).message, contains('boom'));
    });

    test(
      'visibleOrders padrão traz só abertos ordenados por atenção',
      () async {
        await cubit.load();

        final visible = (cubit.state as OrderListLoaded).visibleOrders;

        expect(visible.map((o) => o.status), [
          OrderStatus.blockedByFinance,
          OrderStatus.pendingFinanceApproval,
          OrderStatus.inTransit,
        ]);
      },
    );

    test('setFilter(closed) traz só encerrados', () async {
      await cubit.load();
      cubit.setFilter(OrderStatusGroup.closed);

      final state = cubit.state as OrderListLoaded;
      expect(state.filter, OrderStatusGroup.closed);
      expect(state.visibleOrders.map((o) => o.status), [
        OrderStatus.delivered,
        OrderStatus.cancelled,
      ]);
    });

    test('setFilter mantém o filtro no próximo load', () async {
      await cubit.load();
      cubit.setFilter(OrderStatusGroup.closed);

      await cubit.load();

      expect((cubit.state as OrderListLoaded).filter, OrderStatusGroup.closed);
    });

    test('countFor conta os dois agrupamentos', () async {
      await cubit.load();
      final state = cubit.state as OrderListLoaded;

      expect(state.countFor(OrderStatusGroup.open), 3);
      expect(state.countFor(OrderStatusGroup.closed), 2);
    });

    test('initialFilter define o agrupamento antes do load', () async {
      final closedCubit = OrderListCubit(
        repository,
        initialFilter: OrderStatusGroup.closed,
      );
      addTearDown(closedCubit.close);

      await closedCubit.load();

      final state = closedCubit.state as OrderListLoaded;
      expect(state.filter, OrderStatusGroup.closed);
      expect(state.visibleOrders.every((o) => !o.status.isOpen), isTrue);
    });
  });
}
