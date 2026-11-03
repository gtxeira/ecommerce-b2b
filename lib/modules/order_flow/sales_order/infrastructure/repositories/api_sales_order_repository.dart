import 'package:ecommerce_b2b/app/core/network/api_client.dart';
import 'package:ecommerce_b2b/app/core/network/json_read.dart';
import 'package:ecommerce_b2b/modules/order_flow/model/enums/credit_status.dart';
import 'package:ecommerce_b2b/modules/order_flow/model/enums/order_status.dart';
import 'package:ecommerce_b2b/modules/order_flow/sales_order/model/enums/finance_decision.dart';
import 'package:ecommerce_b2b/modules/order_flow/sales_order/model/finance_review.dart';
import 'package:ecommerce_b2b/modules/order_flow/sales_order/model/order_item.dart';
import 'package:ecommerce_b2b/modules/order_flow/sales_order/model/order_timeline_entry.dart';
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

  @override
  Future<List<OrderTimelineEntry>> getTimeline(OrderId id) async {
    final data = await _api.get('/api/orders/${id.value}/timeline');
    if (data is! List) return const [];
    return data
        .whereType<Map>()
        .map(
          (item) =>
              OrderTimelineEntry.fromJson(Map<String, dynamic>.from(item)),
        )
        .toList();
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
            decision: FinanceDecision.fromApi(decision),
            reviewerId: reviewer ?? '',
            reviewerName: readNullableString(json, 'financeReviewerName'),
            reviewerRole: readNullableString(json, 'financeReviewerRole'),
            reviewedAt: DateTime.now(),
            justification: justification ?? '',
          );

    return SalesOrder(
      id: OrderId(readString(json, 'id')),
      companyId: readNullableString(json, 'companyId'),
      companyName: readNullableString(json, 'companyName'),
      companyLegalName: readNullableString(json, 'companyLegalName'),
      status: OrderStatus.fromApi(readString(json, 'status')),
      creditStatus: CreditStatus.fromApi(readString(json, 'creditStatus')),
      items: readMapList(json, 'items')
          .map(
            (item) => OrderItem(
              productId: ProductId(readString(item, 'productId')),
              productName: readNullableString(item, 'productName'),
              productSku: readNullableString(item, 'productSku'),
              quantity: Quantity.create(readInt(item, 'quantity')).getOrThrow(),
              unitPriceSnapshot: Money.create(
                readDouble(item, 'unitPrice'),
              ).getOrThrow(),
            ),
          )
          .toList(),
      financeReview: financeReview,
      createdAt: readDate(json, 'createdAt'),
      lastActivityAt: readDate(json, 'lastActivityAt'),
      shippingCost: Money.create(readDouble(json, 'shippingCost')).getOrThrow(),
    );
  }
}
