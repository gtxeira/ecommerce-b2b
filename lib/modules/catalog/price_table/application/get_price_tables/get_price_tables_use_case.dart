import 'package:ecommerce_b2b/modules/catalog/price_table/domain/price_table.dart';
import 'package:ecommerce_b2b/modules/catalog/price_table/domain/repositories/price_table_repository.dart';
import 'package:ecommerce_b2b/app/core/result/result.dart';

class GetPriceTablesUseCase {
  final PriceTableRepository _priceTableRepository;

  GetPriceTablesUseCase(this._priceTableRepository);

  Future<Result<List<PriceTable>, Exception>> execute() async {
    try {
      final tables = await _priceTableRepository.findAll();
      return Success(tables);
    } catch (e) {
      return Failure(Exception(e.toString()));
    }
  }
}
