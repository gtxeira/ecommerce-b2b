import 'package:ecommerce_b2b/modules/catalog/price_table/application/get_price_tables/get_price_tables_use_case.dart';
import 'package:ecommerce_b2b/modules/catalog/price_table/application/save_price_table/save_price_table_use_case.dart';
import 'package:ecommerce_b2b/modules/catalog/price_table/model/price_table.dart';
import 'package:ecommerce_b2b/modules/catalog/price_table/presentation/cubit/price_table_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class PriceTableCubit extends Cubit<PriceTableState> {
  final GetPriceTablesUseCase _getPriceTablesUseCase;
  final SavePriceTableUseCase _savePriceTableUseCase;

  PriceTableCubit(this._getPriceTablesUseCase, this._savePriceTableUseCase)
    : super(PriceTableInitial());

  Future<void> loadTables() async {
    emit(PriceTableLoading());
    final result = await _getPriceTablesUseCase.execute();
    result.fold(
      (error) => emit(PriceTableError(error.toString())),
      (tables) => emit(PriceTableLoaded(tables)),
    );
  }

  Future<void> saveTable(PriceTable table) async {
    final result = await _savePriceTableUseCase.execute(table);
    result.fold(
      (error) => emit(PriceTableError(error.toString())),
      (_) => loadTables(),
    );
  }
}
