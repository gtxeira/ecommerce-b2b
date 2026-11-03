import 'package:ecommerce_b2b/app/core/events/order_events.dart';
import 'package:ecommerce_b2b/app/core/network/api_exception.dart';
import 'package:ecommerce_b2b/modules/order_flow/sales_order/application/get_finance_summary/get_finance_summary_use_case.dart';
import 'package:ecommerce_b2b/modules/order_flow/sales_order/model/finance_summary.dart';
import 'package:ecommerce_b2b/modules/order_flow/sales_order/presentation/finance_review/cubit/finance_summary_cubit.dart';
import 'package:ecommerce_b2b/modules/shared_kernel/model/finance/value_objects/money.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockGetFinanceSummaryUseCase extends Mock
    implements GetFinanceSummaryUseCase {}

void main() {
  group('FinanceSummaryCubit', () {
    late MockGetFinanceSummaryUseCase getSummary;
    late OrderEvents orderEvents;
    late FinanceSummaryCubit cubit;

    final summary = FinanceSummary(
      companyCount: 2,
      totalCreditLimit: Money.create(15000).getOrThrow(),
      totalOpenBalance: Money.create(1500).getOrThrow(),
      totalPendingOrdersBalance: Money.create(5000).getOrThrow(),
      totalExposure: Money.create(6500).getOrThrow(),
      availableLimit: Money.create(8500).getOrThrow(),
      utilizationPercentage: 43.33,
      companiesAtRisk: 1,
      companiesOverLimit: 0,
    );

    setUp(() {
      getSummary = MockGetFinanceSummaryUseCase();
      orderEvents = OrderEvents();
      cubit = FinanceSummaryCubit(getSummary, orderEvents);
    });

    tearDown(() async {
      await cubit.close();
      await orderEvents.dispose();
    });

    test('initial state should be FinanceSummaryInitial', () {
      expect(cubit.state, isA<FinanceSummaryInitial>());
    });

    test('load should emit Loading then Loaded', () async {
      when(() => getSummary.execute()).thenAnswer((_) async => summary);

      final states = <FinanceSummaryState>[];
      cubit.stream.listen(states.add);

      await cubit.load();
      await Future<void>.delayed(Duration.zero);

      expect(states, [
        isA<FinanceSummaryLoading>(),
        isA<FinanceSummaryLoaded>(),
      ]);
      expect((states[1] as FinanceSummaryLoaded).summary, summary);
    });

    test('load should emit Failure on API error', () async {
      when(() => getSummary.execute()).thenThrow(
        const ApiException(
          statusCode: 403,
          code: 'FORBIDDEN',
          message: 'Sem permissão.',
        ),
      );

      final states = <FinanceSummaryState>[];
      cubit.stream.listen(states.add);

      await cubit.load();
      await Future<void>.delayed(Duration.zero);

      expect(states, [
        isA<FinanceSummaryLoading>(),
        isA<FinanceSummaryFailure>(),
      ]);
      expect((states[1] as FinanceSummaryFailure).message, 'Sem permissão.');
    });

    test('should reload when OrderEvents notifies a change', () async {
      when(() => getSummary.execute()).thenAnswer((_) async => summary);

      await cubit.load();
      orderEvents.notifyChanged();
      await Future<void>.delayed(Duration.zero);

      verify(() => getSummary.execute()).called(2);
    });
  });
}
