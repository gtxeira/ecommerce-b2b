import 'package:ecommerce_b2b/modules/order_flow/sales_order/infrastructure/api/finance_api.dart';
import 'package:ecommerce_b2b/modules/order_flow/sales_order/model/finance_summary.dart';

/// Resumo de crédito da carteira. A agregação e o escopo por papel são da API.
class GetFinanceSummaryUseCase {
  final FinanceApi _financeApi;

  GetFinanceSummaryUseCase(this._financeApi);

  Future<FinanceSummary> execute() => _financeApi.getSummary();
}
