part of 'commission_list_cubit.dart';

abstract class CommissionListState extends Equatable {
  const CommissionListState();

  @override
  List<Object?> get props => [];
}

class CommissionListInitial extends CommissionListState {}

class CommissionListLoading extends CommissionListState {}

class CommissionListLoaded extends CommissionListState {
  final List<Commission> commissions;
  final List<SalesRepresentative> subordinates;
  final RepresentativeId selectedRepId;
  final String selectedRepName;
  final bool isTeamView;

  const CommissionListLoaded({
    required this.commissions,
    required this.subordinates,
    required this.selectedRepId,
    required this.selectedRepName,
    required this.isTeamView,
  });

  @override
  List<Object?> get props => [
    commissions,
    subordinates,
    selectedRepId,
    selectedRepName,
    isTeamView,
  ];
}

class CommissionListFailure extends CommissionListState {
  final String message;

  const CommissionListFailure(this.message);

  @override
  List<Object?> get props => [message];
}
