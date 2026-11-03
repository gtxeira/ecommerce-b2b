import 'package:ecommerce_b2b/modules/identity_access/model/user_session.dart';
import 'package:ecommerce_b2b/modules/order_flow/quote/model/quote.dart';
import 'package:ecommerce_b2b/modules/sales_team/sales_representative/application/get_commissions/get_representative_commissions_use_case.dart';
import 'package:ecommerce_b2b/modules/sales_team/sales_representative/application/get_customers/get_customer_portfolio_use_case.dart';
import 'package:ecommerce_b2b/modules/sales_team/sales_representative/application/get_quotes/get_recent_quotes_use_case.dart';
import 'package:ecommerce_b2b/modules/sales_team/sales_representative/model/commission.dart';
import 'package:ecommerce_b2b/modules/sales_team/sales_representative/model/customer_assignment.dart';
import 'package:ecommerce_b2b/modules/sales_team/sales_representative/model/repositories/sales_representative_repository.dart';
import 'package:ecommerce_b2b/modules/sales_team/sales_representative/model/sales_representative.dart';
import 'package:ecommerce_b2b/modules/shared_kernel/model/common/ids/representative_id.dart';
import 'package:ecommerce_b2b/modules/shared_kernel/model/finance/value_objects/money.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';

part 'representative_dashboard_state.dart';

class RepresentativeDashboardCubit extends Cubit<RepresentativeDashboardState> {
  final GetRepresentativeCommissionsUseCase _getCommissionsUseCase;
  final GetCustomerPortfolioUseCase _getCustomerPortfolioUseCase;
  final GetRecentQuotesUseCase _getRecentQuotesUseCase;
  final SalesRepresentativeRepository _representativeRepository;

  RepresentativeDashboardCubit({
    required this._getCommissionsUseCase,
    required this._getCustomerPortfolioUseCase,
    required this._getRecentQuotesUseCase,
    required this._representativeRepository,
  }) : super(RepresentativeDashboardInitial());

  Future<void> loadDashboard(
    UserSession session, {
    RepresentativeId? targetRepId,
    bool teamView = false,
  }) async {
    emit(RepresentativeDashboardLoading());

    try {
      final selfId = RepresentativeId(session.userId.value);
      final selectedRepId = targetRepId ?? selfId;

      // Uma unica leitura de /api/me/profile + /api/me/team abastece o nome do
      // alvo, a lista de representados e o resumo consolidado.
      final allReps = await _representativeRepository.findAll();
      final selectedRep = _findRep(allReps, selectedRepId);
      final subordinates = allReps
          .where((rep) => rep.id.value != selfId.value)
          .toList();
      final selectedRepName = teamView
          ? 'Toda a Equipe'
          : selectedRep?.fullName ?? 'Representante';

      final commissionsResult = await _getCommissionsUseCase.execute(
        selectedRepId,
        session,
        teamScope: teamView,
      );
      final portfolioResult = await _getCustomerPortfolioUseCase.execute(
        selectedRepId,
        session,
        teamScope: teamView,
      );
      final quotesResult = await _getRecentQuotesUseCase.execute(
        selectedRepId,
        session,
        teamScope: teamView,
      );

      if (commissionsResult.isSuccess &&
          portfolioResult.isSuccess &&
          quotesResult.isSuccess) {
        final commissions = commissionsResult.getOrThrow();
        final assignments = portfolioResult.getOrThrow();
        final quotes = quotesResult.getOrThrow();

        emit(
          RepresentativeDashboardLoaded(
            commissions: commissions,
            assignments: assignments,
            recentQuotes: quotes,
            subordinates: subordinates,
            selectedRepId: selectedRepId,
            selectedRepName: selectedRepName,
            isTeamView: teamView,
            performances: teamView
                ? _buildPerformances(
                    selfId: selfId,
                    representatives: allReps,
                    commissions: commissions,
                    assignments: assignments,
                    quotes: quotes,
                  )
                : const [],
          ),
        );
      } else {
        String errorMessage = 'Error loading dashboard';
        if (commissionsResult.isFailure) {
          errorMessage = commissionsResult.getFailureOrThrow().message;
        } else if (portfolioResult.isFailure) {
          errorMessage = portfolioResult.getFailureOrThrow().message;
        } else if (quotesResult.isFailure) {
          errorMessage = quotesResult.getFailureOrThrow().message;
        }

        emit(RepresentativeDashboardFailure(errorMessage));
      }
    } catch (error) {
      emit(RepresentativeDashboardFailure(error.toString()));
    }
  }

  SalesRepresentative? _findRep(
    List<SalesRepresentative> reps,
    RepresentativeId id,
  ) {
    for (final rep in reps) {
      if (rep.id == id) return rep;
    }
    return null;
  }

  List<RepresentativePerformance> _buildPerformances({
    required RepresentativeId selfId,
    required List<SalesRepresentative> representatives,
    required List<Commission> commissions,
    required List<CustomerAssignment> assignments,
    required List<Quote> quotes,
  }) {
    final repsById = <String, SalesRepresentative>{
      for (final rep in representatives) rep.id.value: rep,
    };

    final commissionTotals = <String, Money>{};
    final commissionValues = <String, List<Money>>{};
    for (final commission in commissions) {
      final id = commission.representativeId ?? selfId.value;
      commissionValues.putIfAbsent(id, () => []).add(commission.amount);
    }
    for (final entry in commissionValues.entries) {
      Money total = entry.value.first;
      for (var i = 1; i < entry.value.length; i++) {
        total = total + entry.value[i];
      }
      commissionTotals[entry.key] = total;
    }

    final clientsByRep = <String, Set<String>>{};
    for (final assignment in assignments) {
      final id = assignment.representativeId ?? selfId.value;
      clientsByRep
          .putIfAbsent(id, () => <String>{})
          .add(assignment.companyId.value);
    }

    final quotesByRep = <String, Set<String>>{};
    for (final quote in quotes) {
      final id = quote.representativeId ?? selfId.value;
      quotesByRep.putIfAbsent(id, () => <String>{}).add(quote.id.value);
    }

    final performances = <RepresentativePerformance>[];
    for (final rep in representatives) {
      performances.add(
        RepresentativePerformance(
          representativeId: rep.id,
          name: rep.fullName,
          commissionTotal:
              commissionTotals[rep.id.value] ?? Money.create(0).getOrThrow(),
          clientsCount: clientsByRep[rep.id.value]?.length ?? 0,
          quotesCount: quotesByRep[rep.id.value]?.length ?? 0,
          isSelf: rep.id.value == selfId.value,
        ),
      );
    }

    // Representantes que apareceram em uma comissão mas não vieram em
    // /api/me/team (payload antigo) ainda entram no resumo.
    for (final id in commissionTotals.keys) {
      if (performances.any((p) => p.representativeId.value == id)) continue;
      performances.add(
        RepresentativePerformance(
          representativeId: RepresentativeId(id),
          name: repsById[id]?.fullName ?? id,
          commissionTotal: commissionTotals[id]!,
          clientsCount: clientsByRep[id]?.length ?? 0,
          quotesCount: quotesByRep[id]?.length ?? 0,
          isSelf: id == selfId.value,
        ),
      );
    }

    performances.sort((a, b) {
      if (a.isSelf != b.isSelf) return a.isSelf ? -1 : 1;
      return a.name.compareTo(b.name);
    });
    return performances;
  }
}
