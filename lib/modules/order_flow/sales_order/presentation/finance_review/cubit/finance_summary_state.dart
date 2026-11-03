part of 'finance_summary_cubit.dart';

abstract class FinanceSummaryState extends Equatable {
  const FinanceSummaryState();

  @override
  List<Object?> get props => [];
}

class FinanceSummaryInitial extends FinanceSummaryState {}

class FinanceSummaryLoading extends FinanceSummaryState {}

class FinanceSummaryLoaded extends FinanceSummaryState {
  final FinanceSummary summary;

  const FinanceSummaryLoaded(this.summary);

  @override
  List<Object?> get props => [summary];
}

class FinanceSummaryFailure extends FinanceSummaryState {
  final String message;

  const FinanceSummaryFailure(this.message);

  @override
  List<Object?> get props => [message];
}
