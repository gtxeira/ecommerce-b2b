import 'package:ecommerce_b2b/modules/order_flow/quote/model/quote.dart';
import 'package:ecommerce_b2b/modules/order_flow/sales_order/model/sales_order.dart';
import 'package:ecommerce_b2b/modules/shared_kernel/model/common/ids/quote_id.dart';

abstract class QuoteRepository {
  Future<void> save(Quote quote);

  Future<Quote?> getById(QuoteId id);

  Future<List<Quote>> getAll();

  Future<List<Quote>> findByRepresentativeId(
    String representativeId, {
    bool teamScope = false,
  });

  /// Orçamentos da empresa. O comprador só recebe a própria empresa (a API
  /// restringe); Admin/financeiro usam para filtro.
  Future<List<Quote>> findByCompanyId(String companyId);

  /// Converte o orçamento em pedido e devolve o pedido criado.
  Future<SalesOrder> convert(QuoteId id, {String? companyId});
}
