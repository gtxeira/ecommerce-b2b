import 'package:ecommerce_b2b/modules/order_flow/sales_order/model/sales_order.dart';

/// Compara dois pedidos pela data de criação, do mais recente para o mais
/// antigo. Pedidos sem data (payload anterior ao campo `createdAt`) vão para o
/// fim, para não aparecerem como "os mais recentes".
int compareSalesOrdersByCreatedAtDesc(SalesOrder a, SalesOrder b) {
  final aDate = a.createdAt;
  final bDate = b.createdAt;
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
  final sorted = orders.toList()..sort(compareSalesOrdersByCreatedAtDesc);
  if (limit == null || sorted.length <= limit) return sorted;
  return sorted.take(limit).toList();
}
