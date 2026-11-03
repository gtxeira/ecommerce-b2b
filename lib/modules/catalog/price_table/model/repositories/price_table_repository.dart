import 'package:ecommerce_b2b/modules/catalog/price_table/model/price_table.dart';
import 'package:ecommerce_b2b/modules/shared_kernel/model/common/ids/price_table_id.dart';

abstract class PriceTableRepository {
  Future<void> save(PriceTable priceTable);
  Future<PriceTable?> findById(PriceTableId id);
  Future<List<PriceTable>> findAll();
  Future<void> delete(PriceTableId id);
}
