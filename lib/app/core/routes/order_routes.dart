import 'package:ecommerce_b2b/modules/order_flow/model/enums/order_status.dart';

/// Rotas do fluxo de pedidos que não são módulos da sidebar: a listagem por
/// situação (abertos/encerrados) e o detalhe de um pedido.
///
/// Os caminhos ficam fora de [AppPage] de propósito — [AppPage] alimenta a
/// sidebar e os cards da home, e pedidos são alcançados a partir delas.
class OrderRoutes {
  const OrderRoutes._();

  /// Listagem de pedidos. Aceita `?group=open|closed`.
  static const String list = '/orders';

  /// Padrão registrado no GoRouter, com o id como path parameter.
  static const String detailPattern = '/orders/:id';

  /// Rota do detalhe de um pedido.
  static String detail(String orderId) =>
      '$list/${Uri.encodeComponent(orderId)}';

  /// Rota da listagem já aberta em um agrupamento.
  static String listWithGroup(OrderStatusGroup group) =>
      '$list?group=${group.name}';
}
