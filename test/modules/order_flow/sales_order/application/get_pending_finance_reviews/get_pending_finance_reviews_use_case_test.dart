import 'package:ecommerce_b2b/modules/order_flow/domain/enums/credit_status.dart';
import 'package:ecommerce_b2b/modules/order_flow/domain/enums/order_status.dart';
import 'package:ecommerce_b2b/modules/order_flow/sales_order/application/get_pending_finance_reviews/get_pending_finance_reviews_use_case.dart';
import 'package:ecommerce_b2b/modules/order_flow/sales_order/domain/sales_order.dart';
import 'package:ecommerce_b2b/modules/order_flow/sales_order/infrastructure/api/finance_api.dart';
import 'package:ecommerce_b2b/modules/shared_kernel/domain/common/ids/order_id.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockFinanceApi extends Mock implements FinanceApi {}

void main() {
  group('GetPendingFinanceReviewsUseCase', () {
    late MockFinanceApi financeApi;
    late GetPendingFinanceReviewsUseCase useCase;

    setUp(() {
      financeApi = MockFinanceApi();
      useCase = GetPendingFinanceReviewsUseCase(financeApi);
    });

    test('should delegate the pending queue to the API', () async {
      final pending = SalesOrder(
        id: const OrderId('o1'),
        status: OrderStatus.pendingFinanceApproval,
        creditStatus: CreditStatus.pending,
        items: [],
      );
      when(() => financeApi.getPendingReviews()).thenAnswer((_) async => [pending]);

      final result = await useCase.execute();

      expect(result.single, pending);
      verify(() => financeApi.getPendingReviews()).called(1);
    });
  });
}
