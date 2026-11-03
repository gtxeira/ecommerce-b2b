import 'package:ecommerce_b2b/app/core/events/order_events.dart';
import 'package:ecommerce_b2b/modules/order_flow/model/enums/credit_status.dart';
import 'package:ecommerce_b2b/modules/order_flow/model/enums/order_status.dart';
import 'package:ecommerce_b2b/modules/order_flow/sales_order/model/repositories/sales_order_repository.dart';
import 'package:ecommerce_b2b/modules/order_flow/sales_order/model/sales_order.dart';
import 'package:ecommerce_b2b/modules/order_flow/sales_order/presentation/cubit/open_orders_cubit.dart';
import 'package:ecommerce_b2b/modules/shared_kernel/model/common/ids/order_id.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockSalesOrderRepository extends Mock implements SalesOrderRepository {}

void main() {
  group('OpenOrdersCubit', () {
    late MockSalesOrderRepository repository;
    late OrderEvents events;
    late OpenOrdersCubit cubit;

    SalesOrder order(String id, OrderStatus status) => SalesOrder(
      id: OrderId(id),
      status: status,
      creditStatus: CreditStatus.approved,
      items: const [],
    );

    setUp(() {
      repository = MockSalesOrderRepository();
      events = OrderEvents();
      cubit = OpenOrdersCubit(repository, events);
    });

    tearDown(() async {
      await cubit.close();
      await events.dispose();
    });

    test('initial state conta zero', () {
      expect(cubit.state, isA<OpenOrdersInitial>());
      expect(cubit.state.count, 0);
    });

    test('conta apenas pedidos em aberto', () async {
      when(() => repository.getAll()).thenAnswer(
        (_) async => [
          order('o1', OrderStatus.pendingFinanceApproval),
          order('o2', OrderStatus.blockedByFinance),
          order('o3', OrderStatus.pickingPacking),
          order('o4', OrderStatus.inTransit),
          order('o5', OrderStatus.delivered),
          order('o6', OrderStatus.invoiced),
          order('o7', OrderStatus.cancelled),
          order('o8', OrderStatus.rma),
        ],
      );

      await cubit.load();

      expect(cubit.state, isA<OpenOrdersLoaded>());
      expect(cubit.state.count, 4);
    });

    test('falha preserva o último contador conhecido', () async {
      when(
        () => repository.getAll(),
      ).thenAnswer((_) async => [order('o1', OrderStatus.inTransit)]);
      await cubit.load();
      expect(cubit.state.count, 1);

      when(() => repository.getAll()).thenThrow(Exception('500'));
      await cubit.load();

      expect(cubit.state, isA<OpenOrdersFailure>());
      expect(cubit.state.count, 1);
    });

    test('recarrega quando OrderEvents avisa', () async {
      when(() => repository.getAll()).thenAnswer((_) async => []);
      await cubit.load();
      verify(() => repository.getAll()).called(1);

      events.notifyChanged();
      await pumpEventQueue();

      verify(() => repository.getAll()).called(1);
      verifyNoMoreInteractions(repository);
    });

    test('clear zera o contador', () async {
      when(
        () => repository.getAll(),
      ).thenAnswer((_) async => [order('o1', OrderStatus.inTransit)]);
      await cubit.load();
      expect(cubit.state.count, 1);

      cubit.clear();

      expect(cubit.state, isA<OpenOrdersInitial>());
      expect(cubit.state.count, 0);
    });
  });
}
