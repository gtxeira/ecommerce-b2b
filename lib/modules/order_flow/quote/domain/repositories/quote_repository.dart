import 'package:ecommerce_b2b/modules/order_flow/quote/domain/quote.dart';
import 'package:ecommerce_b2b/modules/shared_kernel/domain/common/ids/quote_id.dart';

abstract class QuoteRepository {
  Future<void> save(Quote quote);

  Future<Quote?> getById(QuoteId id);

  Future<List<Quote>> getAll();

  Future<List<Quote>> findByRepresentativeId(String representativeId);
}
