import 'package:ecommerce_b2b/app/core/network/api_client.dart';
import 'package:ecommerce_b2b/app/core/network/json_read.dart';
import 'package:ecommerce_b2b/modules/order_flow/sales_order/model/enums/finance_decision.dart';
import 'package:ecommerce_b2b/modules/order_flow/sales_order/model/finance_summary.dart';
import 'package:ecommerce_b2b/modules/order_flow/sales_order/model/sales_order.dart';
import 'package:ecommerce_b2b/modules/order_flow/sales_order/infrastructure/repositories/api_sales_order_repository.dart';

class InvoiceResult {
  final SalesOrder order;
  final bool commissionGenerated;

  const InvoiceResult({required this.order, required this.commissionGenerated});
}

/// Operações do departamento financeiro que não são um "repositório" de pedido.
class FinanceApi {
  final ApiClient _api;

  FinanceApi(this._api);

  Future<FinanceSummary> getSummary() async {
    final data = await _api.get('/api/finance/summary');
    if (data is! Map) {
      throw StateError('Resposta inesperada ao carregar o resumo financeiro.');
    }
    return FinanceSummary.fromJson(Map<String, dynamic>.from(data));
  }

  Future<List<SalesOrder>> getPendingReviews() async {
    final data = await _api.get('/api/orders/pending-finance-review');
    if (data is! List) return const [];
    return data
        .whereType<Map>()
        .map(
          (item) =>
              ApiSalesOrderRepository.fromJson(Map<String, dynamic>.from(item)),
        )
        .toList();
  }

  Future<SalesOrder> processReview({
    required String orderId,
    required FinanceDecision decision,
    String? justification,
  }) async {
    final data = await _api.post(
      '/api/orders/$orderId/finance-review',
      data: {
        'decision': _decisionToApi(decision),
        'justification': justification,
      },
    );
    if (data is! Map) {
      throw StateError(
        'Resposta inesperada ao registrar a análise financeira.',
      );
    }
    return ApiSalesOrderRepository.fromJson(Map<String, dynamic>.from(data));
  }

  Future<InvoiceResult> invoice(String orderId) async {
    final data = await _api.post('/api/orders/$orderId/invoice');
    if (data is! Map) {
      throw StateError('Resposta inesperada ao faturar o pedido.');
    }
    final json = Map<String, dynamic>.from(data);
    return InvoiceResult(
      order: ApiSalesOrderRepository.fromJson(readMap(json, 'order')),
      commissionGenerated: readBool(json, 'commissionGenerated'),
    );
  }

  String _decisionToApi(FinanceDecision decision) => switch (decision) {
    FinanceDecision.approved => 'Approved',
    FinanceDecision.rejected => 'Rejected',
    FinanceDecision.requestMoreInfo => 'RequestMoreInfo',
  };
}
