import 'package:ecommerce_b2b/modules/customer_management/company/model/company.dart';
import 'package:ecommerce_b2b/modules/customer_management/company/model/repositories/company_repository.dart';
import 'package:ecommerce_b2b/modules/shared_kernel/model/common/ids/company_id.dart';
import 'package:ecommerce_b2b/modules/order_flow/model/enums/credit_status.dart';
import 'package:ecommerce_b2b/modules/order_flow/model/enums/order_status.dart';
import 'package:ecommerce_b2b/modules/order_flow/sales_order/model/repositories/sales_order_repository.dart';
import 'package:ecommerce_b2b/modules/order_flow/sales_order/model/sales_order.dart';
import 'package:ecommerce_b2b/modules/order_flow/sales_order/presentation/cubit/order_list_cubit.dart';
import 'package:ecommerce_b2b/modules/shared_kernel/model/common/ids/order_id.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockSalesOrderRepository extends Mock implements SalesOrderRepository {}

class MockCompanyRepository extends Mock implements CompanyRepository {}

/// Só os campos lidos pelo cubit (id e nome fantasia) são implementados.
class FakeCompany extends Fake implements Company {
  FakeCompany(this.id, this.tradeName);

  @override
  final CompanyId id;

  @override
  final String tradeName;

  @override
  String get legalName => tradeName;
}

void main() {
  group('OrderListCubit', () {
    late MockSalesOrderRepository repository;
    late MockCompanyRepository companyRepository;
    late OrderListCubit cubit;

    SalesOrder order(
      String id,
      OrderStatus status, {
      String? companyId,
      DateTime? createdAt,
      DateTime? lastActivityAt,
    }) => SalesOrder(
      id: OrderId(id),
      companyId: companyId,
      status: status,
      creditStatus: CreditStatus.approved,
      items: const [],
      createdAt: createdAt,
      lastActivityAt: lastActivityAt,
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
      companyRepository = MockCompanyRepository();
      when(() => repository.getAll()).thenAnswer((_) async => orders);
      when(() => companyRepository.findAll()).thenAnswer((_) async => []);
      cubit = OrderListCubit(repository, companyRepository);
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
        companyRepository,
        initialFilter: OrderStatusGroup.closed,
      );
      addTearDown(closedCubit.close);

      await closedCubit.load();

      final state = closedCubit.state as OrderListLoaded;
      expect(state.filter, OrderStatusGroup.closed);
      expect(state.visibleOrders.every((o) => !o.status.isOpen), isTrue);
    });

    group('ordenação por data', () {
      test('encerrados: mais recente primeiro', () async {
        when(() => repository.getAll()).thenAnswer(
          (_) async => [
            order(
              'old',
              OrderStatus.delivered,
              createdAt: DateTime.utc(2026, 9, 20),
            ),
            order(
              'new',
              OrderStatus.cancelled,
              createdAt: DateTime.utc(2026, 9, 22),
            ),
          ],
        );

        await cubit.load();
        cubit.setFilter(OrderStatusGroup.closed);

        expect(
          (cubit.state as OrderListLoaded).visibleOrders.map((o) => o.id.value),
          ['new', 'old'],
        );
      });

      test('abertos: prioridade de atenção vence a data', () async {
        when(() => repository.getAll()).thenAnswer(
          (_) async => [
            order(
              'transit-newest',
              OrderStatus.inTransit,
              createdAt: DateTime.utc(2026, 9, 22),
            ),
            order(
              'blocked-oldest',
              OrderStatus.blockedByFinance,
              createdAt: DateTime.utc(2026, 9, 20),
            ),
          ],
        );

        await cubit.load();

        expect(
          (cubit.state as OrderListLoaded).visibleOrders.map((o) => o.id.value),
          ['blocked-oldest', 'transit-newest'],
        );
      });

      test('abertos: mesma prioridade desempata pela data', () async {
        when(() => repository.getAll()).thenAnswer(
          (_) async => [
            order(
              'older',
              OrderStatus.pickingPacking,
              createdAt: DateTime.utc(2026, 9, 20),
            ),
            order(
              'newer',
              OrderStatus.pickingPacking,
              createdAt: DateTime.utc(2026, 9, 22),
            ),
          ],
        );

        await cubit.load();

        expect(
          (cubit.state as OrderListLoaded).visibleOrders.map((o) => o.id.value),
          ['newer', 'older'],
        );
      });

      test('encerrados: última atividade vence a data de criação', () async {
        // Espelha o seed: criado há dias, entregue agora, aparece antes de um
        // pedido criado ontem e nunca tocado.
        when(() => repository.getAll()).thenAnswer(
          (_) async => [
            order(
              'created-long-ago-delivered-now',
              OrderStatus.delivered,
              createdAt: DateTime.utc(2026, 9, 1),
              lastActivityAt: DateTime.utc(2026, 9, 25),
            ),
            order(
              'created-yesterday',
              OrderStatus.cancelled,
              createdAt: DateTime.utc(2026, 9, 24),
            ),
          ],
        );

        await cubit.load();
        cubit.setFilter(OrderStatusGroup.closed);

        expect(
          (cubit.state as OrderListLoaded).visibleOrders.map((o) => o.id.value),
          ['created-long-ago-delivered-now', 'created-yesterday'],
        );
      });

      test('abertos: mesma prioridade desempata pela atividade', () async {
        when(() => repository.getAll()).thenAnswer(
          (_) async => [
            order(
              'older-activity',
              OrderStatus.pickingPacking,
              createdAt: DateTime.utc(2026, 9, 20),
              lastActivityAt: DateTime.utc(2026, 9, 21),
            ),
            order(
              'newer-activity',
              OrderStatus.pickingPacking,
              createdAt: DateTime.utc(2026, 9, 19),
              lastActivityAt: DateTime.utc(2026, 9, 22),
            ),
          ],
        );

        await cubit.load();

        expect(
          (cubit.state as OrderListLoaded).visibleOrders.map((o) => o.id.value),
          ['newer-activity', 'older-activity'],
        );
      });

      test('pedido sem data vai para o fim', () async {
        when(() => repository.getAll()).thenAnswer(
          (_) async => [
            order('no-date', OrderStatus.delivered),
            order(
              'dated',
              OrderStatus.cancelled,
              createdAt: DateTime.utc(2026, 9, 22),
            ),
          ],
        );

        await cubit.load();
        cubit.setFilter(OrderStatusGroup.closed);

        expect(
          (cubit.state as OrderListLoaded).visibleOrders.map((o) => o.id.value),
          ['dated', 'no-date'],
        );
      });
    });

    group('busca', () {
      late List<SalesOrder> searchableOrders;

      setUp(() {
        searchableOrders = [
          order('order-101', OrderStatus.inTransit, companyId: 'company-1'),
          order('order-202', OrderStatus.inTransit, companyId: 'company-2'),
        ];
        when(
          () => repository.getAll(),
        ).thenAnswer((_) async => searchableOrders);
        when(() => companyRepository.findAll()).thenAnswer(
          (_) async => [FakeCompany(const CompanyId('company-1'), 'ACME')],
        );
      });

      test('filtra por id do pedido', () async {
        await cubit.load();
        cubit.setQuery('order-202');

        expect(
          (cubit.state as OrderListLoaded).visibleOrders.map((o) => o.id.value),
          ['order-202'],
        );
      });

      test('aceita o id com #, como aparece na tela', () async {
        await cubit.load();
        cubit.setQuery('#order-202');

        expect(
          (cubit.state as OrderListLoaded).visibleOrders.map((o) => o.id.value),
          ['order-202'],
        );
      });

      test('filtra por nome fantasia vindo do pedido', () async {
        when(() => repository.getAll()).thenAnswer(
          (_) async => [
            SalesOrder(
              id: const OrderId('order-named'),
              companyId: 'c9',
              companyName: 'ACME',
              companyLegalName: 'ACME Ltda',
              status: OrderStatus.inTransit,
              creditStatus: CreditStatus.approved,
              items: const [],
            ),
          ],
        );

        await cubit.load();
        cubit.setQuery('acme ltda');

        expect(
          (cubit.state as OrderListLoaded).visibleOrders.map((o) => o.id.value),
          ['order-named'],
        );
      });

      test('filtra por companyId', () async {
        await cubit.load();
        cubit.setQuery('company-1');

        expect(
          (cubit.state as OrderListLoaded).visibleOrders.map((o) => o.id.value),
          ['order-101'],
        );
      });

      test('filtra por nome fantasia, ignorando caixa', () async {
        await cubit.load();
        cubit.setQuery('acme');

        expect(
          (cubit.state as OrderListLoaded).visibleOrders.map((o) => o.id.value),
          ['order-101'],
        );
      });

      test('combina busca e agrupamento', () async {
        when(() => repository.getAll()).thenAnswer(
          (_) async => [
            order('open-acme', OrderStatus.inTransit, companyId: 'company-1'),
            order('closed-acme', OrderStatus.delivered, companyId: 'company-1'),
          ],
        );

        await cubit.load();
        cubit.setFilter(OrderStatusGroup.closed);
        cubit.setQuery('acme');

        expect(
          (cubit.state as OrderListLoaded).visibleOrders.map((o) => o.id.value),
          ['closed-acme'],
        );
      });

      test('termo sem correspondência zera a lista', () async {
        await cubit.load();
        cubit.setQuery('inexistente');

        expect((cubit.state as OrderListLoaded).visibleOrders, isEmpty);
      });

      test('sem empresas a busca ainda funciona por id', () async {
        when(() => companyRepository.findAll()).thenThrow(Exception('403'));

        await cubit.load();
        cubit.setQuery('order-101');

        final state = cubit.state as OrderListLoaded;
        expect(state.companyNames, isEmpty);
        expect(state.visibleOrders.map((o) => o.id.value), ['order-101']);
      });

      test('props muda com a query', () async {
        await cubit.load();
        final first = (cubit.state as OrderListLoaded).props;

        cubit.setQuery('acme');

        expect((cubit.state as OrderListLoaded).props, isNot(first));
      });

      test('countFor ignora a busca', () async {
        await cubit.load();
        cubit.setQuery('inexistente');

        final state = cubit.state as OrderListLoaded;
        expect(state.countFor(OrderStatusGroup.open), 2);
      });
    });
  });
}
