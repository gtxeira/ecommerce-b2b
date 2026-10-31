import 'package:ecommerce_b2b/modules/order_flow/sales_order/domain/sales_order.dart';
import 'package:ecommerce_b2b/modules/order_flow/sales_order/infrastructure/api/finance_api.dart';

class GetPendingFinanceReviewsUseCase {
  final FinanceApi _financeApi;

  GetPendingFinanceReviewsUseCase(this._financeApi);

  Future<List<SalesOrder>> execute() => _financeApi.getPendingReviews();
}
