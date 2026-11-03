part of 'representative_dashboard_cubit.dart';

abstract class RepresentativeDashboardState extends Equatable {
  const RepresentativeDashboardState();

  @override
  List<Object?> get props => [];
}

class RepresentativeDashboardInitial extends RepresentativeDashboardState {}

class RepresentativeDashboardLoading extends RepresentativeDashboardState {}

/// Consolidado de um representante dentro do modo equipe.
class RepresentativePerformance extends Equatable {
  final RepresentativeId representativeId;
  final String name;
  final Money commissionTotal;
  final int clientsCount;
  final int quotesCount;
  final bool isSelf;

  const RepresentativePerformance({
    required this.representativeId,
    required this.name,
    required this.commissionTotal,
    required this.clientsCount,
    required this.quotesCount,
    required this.isSelf,
  });

  @override
  List<Object?> get props => [
    representativeId,
    name,
    commissionTotal,
    clientsCount,
    quotesCount,
    isSelf,
  ];
}

class RepresentativeDashboardLoaded extends RepresentativeDashboardState {
  final List<Commission> commissions;
  final List<CustomerAssignment> assignments;
  final List<Quote> recentQuotes;
  final List<SalesRepresentative> subordinates;
  final RepresentativeId selectedRepId;
  final String selectedRepName;
  final bool isTeamView;
  final List<RepresentativePerformance> performances;

  const RepresentativeDashboardLoaded({
    required this.commissions,
    required this.assignments,
    required this.recentQuotes,
    required this.subordinates,
    required this.selectedRepId,
    required this.selectedRepName,
    this.isTeamView = false,
    this.performances = const [],
  });

  /// Quantidade de empresas únicas na carteira. No consolidado a mesma empresa
  /// pode aparecer em mais de um representante.
  int get clientCount => assignments
      .map((assignment) => assignment.companyId.value)
      .toSet()
      .length;

  @override
  List<Object?> get props => [
    commissions,
    assignments,
    recentQuotes,
    subordinates,
    selectedRepId,
    selectedRepName,
    isTeamView,
    performances,
  ];
}

class RepresentativeDashboardFailure extends RepresentativeDashboardState {
  final String message;
  const RepresentativeDashboardFailure(this.message);

  @override
  List<Object?> get props => [message];
}
