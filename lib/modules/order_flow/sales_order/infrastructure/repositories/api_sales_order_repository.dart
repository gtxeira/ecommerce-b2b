import 'package:ecommerce_b2b/app/core/network/api_client.dart';
import 'package:ecommerce_b2b/app/core/network/json_read.dart';
import 'package:ecommerce_b2b/modules/order_flow/model/enums/credit_status.dart';
import 'package:ecommerce_b2b/modules/order_flow/model/enums/order_status.dart';
import 'package:ecommerce_b2b/modules/order_flow/sales_order/model/enums/finance_decision.dart';
import 'package:ecommerce_b2b/modules/order_flow/sales_order/model/finance_review.dart';
import 'package:ecommerce_b2b/modules/order_flow/sales_order/model/order_item.dart';
import 'package:ecommerce_b2b/modules/order_flow/sales_order/model/repositories/sales_order_repository.dart';
import 'package:ecommerce_b2b/modules/order_flow/sales_order/model/sales_order.dart';
import 'package:ecommerce_b2b/modules/shared_kernel/model/common/ids/company_id.dart';
import 'package:ecommerce_b2b/modules/shared_kernel/model/common/ids/order_id.dart';
import 'package:ecommerce_b2b/modules/shared_kernel/model/common/ids/product_id.dart';
import 'package:ecommerce_b2b/modules/shared_kernel/model/finance/value_objects/money.dart';
import 'package:ecommerce_b2b/modules/shared_kernel/model/finance/value_objects/quantity.dart';

class ApiSalesOrderRepository implements SalesOrderRepository {
  final ApiClient _api;

  ApiSalesOrderRepository(this._api);

  @override
  Future<void> save(SalesOrder order) async {
    // Escritas de pedido são operações próprias da API (finance-review/invoice/
    // expedição). O contrato genérico antigo não é usado pelo fluxo migrado.
    throw UnsupportedError('A API não aceita salvar um pedido genérico.');
  }

  @override
  Future<SalesOrder?> getById(OrderId id) async {
    final data = await _api.get('/api/orders/${id.value}');
    if (data is! Map) return null;
    return fromJson(Map<String, dynamic>.from(data));
  }

  @override
  Future<List<SalesOrder>> getAll() async {
    final data = await _api.get('/api/orders');
    return _mapList(data);
  }

  @override
  Future<List<SalesOrder>> findByCompanyId(CompanyId companyId) async {
    final data = await _api.get(
      '/api/me/purchase-history',
      query: {'companyId': companyId.value},
    );
    return _mapList(data);
  }

  @override
  Future<List<SalesOrder>> findByStatus(String status) async {
    final data = await _api.get('/api/orders', query: {'status': status});
    return _mapList(data);
  }

  List<SalesOrder> _mapList(dynamic data) {
    if (data is! List) return const [];
    return data
        .whereType<Map>()
        .map((item) => fromJson(Map<String, dynamic>.from(item)))
        .toList();
  }

  static SalesOrder fromJson(Map<String, dynamic> json) {
    final decision = readNullableString(json, 'financeDecision');
    final reviewer = readNullableString(json, 'financeReviewerId');
    final justification = readNullableString(json, 'financeJustification');

    final financeReview = decision == null
        ? null
        : FinanceReview(
            decision: _decisionFromApi(decision),
            reviewerId: reviewer ?? '',
            reviewedAt: DateTime.now(),
            justification: justification ?? '',
          );

    return SalesOrder(
      id: OrderId(readString(json, 'id')),
      companyId: readNullableString(json, 'companyId'),
      status: _statusFromApi(readString(json, 'status')),
      creditStatus: _creditFromApi(readString(json, 'creditStatus')),
      items: readMapList(json, 'items')
          .map(
            (item) => OrderItem(
              productId: ProductId(readString(item, 'productId')),
              quantity: Quantity.create(readInt(item, 'quantity')).getOrThrow(),
              unitPriceSnapshot: Money.create(
                readDouble(item, 'unitPrice'),
              ).getOrThrow(),
            ),
          )
          .toList(),
      financeReview: financeReview,
      createdAt: readDate(json, 'createdAt'),
      shippingCost: Money.create(readDouble(json, 'shippingCost')).getOrThrow(),
    );
  }

  static OrderStatus _statusFromApi(String value) =>
      switch (value.toLowerCase()) {
        'pendingfinanceapproval' => OrderStatus.pendingFinanceApproval,
        'blockedbyfinance' => OrderStatus.blockedByFinance,
        'pickingpacking' => OrderStatus.pickingPacking,
        'intransit' => OrderStatus.inTransit,
        'delivered' => OrderStatus.delivered,
        'cancelled' => OrderStatus.cancelled,
        'rma' => OrderStatus.rma,
        'invoiced' => OrderStatus.invoiced,
        _ => OrderStatus.pendingFinanceApproval,
      };

  static CreditStatus _creditFromApi(String value) =>
      switch (value.toLowerCase()) {
        'approved' => CreditStatus.approved,
        'rejected' => CreditStatus.rejected,
        'blocked' => CreditStatus.blocked,
        _ => CreditStatus.pending,
      };

  static FinanceDecision _decisionFromApi(String value) =>
      switch (value.toLowerCase()) {
        'approved' => FinanceDecision.approved,
        'rejected' => FinanceDecision.rejected,
        _ => FinanceDecision.requestMoreInfo,
      };
}
