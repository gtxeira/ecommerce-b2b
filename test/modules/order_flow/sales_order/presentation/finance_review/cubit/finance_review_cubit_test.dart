import 'package:ecommerce_b2b/modules/order_flow/model/enums/credit_status.dart';
import 'package:ecommerce_b2b/modules/order_flow/model/enums/order_status.dart';
import 'package:ecommerce_b2b/modules/order_flow/sales_order/application/get_pending_finance_reviews/get_pending_finance_reviews_use_case.dart';
import 'package:ecommerce_b2b/modules/order_flow/sales_order/application/process_finance_review/process_finance_review_use_case.dart';
import 'package:ecommerce_b2b/modules/order_flow/sales_order/model/finance_review.dart';
import 'package:ecommerce_b2b/modules/order_flow/sales_order/model/repositories/sales_order_repository.dart';
import 'package:ecommerce_b2b/modules/order_flow/sales_order/model/sales_order.dart';
import 'package:ecommerce_b2b/modules/order_flow/sales_order/presentation/finance_review/cubit/finance_review_cubit.dart';
import 'package:ecommerce_b2b/modules/shared_kernel/model/common/ids/order_id.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockGetPendingFinanceReviewsUseCase extends Mock
    implements GetPendingFinanceReviewsUseCase {}

class MockProcessFinanceReviewUseCase extends Mock
    implements ProcessFinanceReviewUseCase {}

class MockSalesOrderRepository extends Mock implements SalesOrderRepository {}

class SalesOrderFake extends Fake implements SalesOrder {}

class FinanceReviewFake extends Fake implements FinanceReview {}

void main() {
  setUpAll(() {
    registerFallbackValue(SalesOrderFake());
    registerFallbackValue(FinanceReviewFake());
  });

  group('FinanceReviewCubit', () {
    late MockGetPendingFinanceReviewsUseCase getPendingReviews;
    late MockProcessFinanceReviewUseCase processReview;
    late MockSalesOrderRepository orderRepository;
    late FinanceReviewCubit cubit;

    final order = SalesOrder(
      id: const OrderId('o1'),
      status: OrderStatus.pendingFinanceApproval,
      creditStatus: CreditStatus.pending,
      items: [],
    );

    setUp(() {
      getPendingReviews = MockGetPendingFinanceReviewsUseCase();
      processReview = MockProcessFinanceReviewUseCase();
      orderRepository = MockSalesOrderRepository();
      when(() => orderRepository.getAll()).thenAnswer((_) async => []);
      cubit = FinanceReviewCubit(
        getPendingReviews: getPendingReviews,
        processReview: processReview,
        orderRepository: orderRepository,
      );
    });

    tearDown(() => cubit.close());

    test('initial state should be FinanceReviewInitial', () {
      expect(cubit.state, isA<FinanceReviewInitial>());
    });

    test('loadPendingOrders should emit Loading then Loaded', () async {
      when(() => getPendingReviews.execute()).thenAnswer((_) async => [order]);

      final states = <FinanceReviewState>[];
      cubit.stream.listen(states.add);

      await cubit.loadPendingOrders();
      await Future<void>.delayed(Duration.zero);

      expect(states, [isA<FinanceReviewLoading>(), isA<FinanceReviewLoaded>()]);
      expect((states[1] as FinanceReviewLoaded).pendingOrders, [order]);
    });

    test(
      'loadPendingOrders should expose approved orders as recent releases',
      () async {
        final approved = SalesOrder(
          id: const OrderId('o2'),
          status: OrderStatus.delivered,
          creditStatus: CreditStatus.approved,
          items: [],
        );

        when(
          () => getPendingReviews.execute(),
        ).thenAnswer((_) async => [order]);
        when(
          () => orderRepository.getAll(),
        ).thenAnswer((_) async => [approved, order]);

        await cubit.loadPendingOrders();

        final loaded = cubit.state as FinanceReviewLoaded;
        expect(loaded.recentReleases, [approved]);
      },
    );

    test('loadPendingOrders should emit Failure on exception', () async {
      when(() => getPendingReviews.execute()).thenThrow(Exception('API error'));

      final states = <FinanceReviewState>[];
      cubit.stream.listen(states.add);

      await cubit.loadPendingOrders();
      await Future<void>.delayed(Duration.zero);

      expect(states, [
        isA<FinanceReviewLoading>(),
        isA<FinanceReviewFailure>(),
      ]);
    });

    test('approveOrder should send the review and reload the queue', () async {
      when(
        () => processReview.execute(
          order: any(named: 'order'),
          review: any(named: 'review'),
        ),
      ).thenAnswer((_) async => order);
      when(() => getPendingReviews.execute()).thenAnswer((_) async => []);

      await cubit.approveOrder(order, 'Limite ok');

      verify(
        () => processReview.execute(
          order: order,
          review: any(named: 'review'),
        ),
      ).called(1);
      verify(() => getPendingReviews.execute()).called(1);
    });

    test('rejectOrder should send the review and reload the queue', () async {
      when(
        () => processReview.execute(
          order: any(named: 'order'),
          review: any(named: 'review'),
        ),
      ).thenAnswer((_) async => order);
      when(() => getPendingReviews.execute()).thenAnswer((_) async => []);

      await cubit.rejectOrder(order, 'Crédito insuficiente');

      verify(
        () => processReview.execute(
          order: order,
          review: any(named: 'review'),
        ),
      ).called(1);
    });

    test('invoiceOrder should call the API and reload', () async {
      when(() => processReview.invoice(any())).thenAnswer((_) async => true);
      when(() => getPendingReviews.execute()).thenAnswer((_) async => []);

      await cubit.invoiceOrder(order);

      verify(() => processReview.invoice(order)).called(1);
    });
  });
}
