import 'package:ecommerce_b2b/modules/order_flow/sales_order/model/sales_order.dart';

/// Compara dois pedidos pela última atividade (`lastActivityAt`, com fallback
/// para `createdAt`), do mais recente para o mais antigo. Pedidos sem data
/// (payload anterior aos campos) vão para o fim, para não aparecerem como "os
/// mais recentes".
int compareSalesOrdersByLastActivityDesc(SalesOrder a, SalesOrder b) {
  final aDate = a.activityAt;
  final bDate = b.activityAt;
  if (aDate == null && bDate == null) return 0;
  if (aDate == null) return 1;
  if (bDate == null) return -1;
  return bDate.compareTo(aDate);
}

/// Pedidos ordenados do mais recente para o mais antigo, opcionalmente
/// limitados (ex.: os 3 últimos do painel).
List<SalesOrder> mostRecentSalesOrders(
  Iterable<SalesOrder> orders, {
  int? limit,
}) {
  final sorted = orders.toList()..sort(compareSalesOrdersByLastActivityDesc);
  if (limit == null || sorted.length <= limit) return sorted;
  return sorted.take(limit).toList();
}
