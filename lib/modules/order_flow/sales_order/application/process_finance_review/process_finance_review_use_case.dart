import 'package:ecommerce_b2b/modules/order_flow/sales_order/model/finance_review.dart';
import 'package:ecommerce_b2b/modules/order_flow/sales_order/model/sales_order.dart';
import 'package:ecommerce_b2b/modules/order_flow/sales_order/infrastructure/api/finance_api.dart';

/// A análise financeira é uma operação da API: ela decide a transição, aloca
/// estoque e persiste. O cliente só envia a decisão.
class ProcessFinanceReviewUseCase {
  final FinanceApi _financeApi;

  ProcessFinanceReviewUseCase(this._financeApi);

  Future<SalesOrder> execute({
    required SalesOrder order,
    required FinanceReview review,
  }) {
    return _financeApi.processReview(
      orderId: order.id.value,
      decision: review.decision,
      justification: review.justification,
    );
  }

  Future<bool> invoice(SalesOrder order) async {
    final result = await _financeApi.invoice(order.id.value);
    return result.commissionGenerated;
  }
}
