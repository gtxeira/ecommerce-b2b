import 'dart:async';

import 'package:ecommerce_b2b/app/core/events/order_events.dart';
import 'package:ecommerce_b2b/app/core/network/api_exception.dart';
import 'package:ecommerce_b2b/modules/order_flow/sales_order/application/get_finance_summary/get_finance_summary_use_case.dart';
import 'package:ecommerce_b2b/modules/order_flow/sales_order/model/finance_summary.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

part 'finance_summary_state.dart';

/// Indicadores agregados do topo do painel financeiro.
///
/// Separado do `FinanceReviewCubit` (fila de análise) para que uma falha no
/// resumo não derrube a fila, nem o contrário.
class FinanceSummaryCubit extends Cubit<FinanceSummaryState> {
  final GetFinanceSummaryUseCase _getSummary;
  final OrderEvents _orderEvents;

  StreamSubscription<void>? _subscription;

  FinanceSummaryCubit(this._getSummary, this._orderEvents)
    : super(FinanceSummaryInitial()) {
    // Aprovar/reprovar/faturar muda a exposição e o limite disponível.
    _subscription = _orderEvents.onChanged.listen((_) => load());
  }

  Future<void> load() async {
    if (state is FinanceSummaryLoading) return;

    emit(FinanceSummaryLoading());
    try {
      emit(FinanceSummaryLoaded(await _getSummary.execute()));
    } on ApiException catch (error) {
      emit(FinanceSummaryFailure(error.message));
    } catch (error) {
      emit(FinanceSummaryFailure(error.toString()));
    }
  }

  @override
  Future<void> close() async {
    await _subscription?.cancel();
    return super.close();
  }
}
