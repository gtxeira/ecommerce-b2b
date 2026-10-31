import 'package:ecommerce_b2b/modules/identity_access/domain/user_session.dart';
import 'package:ecommerce_b2b/modules/order_flow/quote/domain/quote.dart';
import 'package:ecommerce_b2b/modules/sales_team/sales_representative/application/get_commissions/get_representative_commissions_use_case.dart';
import 'package:ecommerce_b2b/modules/sales_team/sales_representative/application/get_customers/get_customer_portfolio_use_case.dart';
import 'package:ecommerce_b2b/modules/sales_team/sales_representative/application/get_quotes/get_recent_quotes_use_case.dart';
import 'package:ecommerce_b2b/modules/sales_team/sales_representative/domain/commission.dart';
import 'package:ecommerce_b2b/modules/sales_team/sales_representative/domain/customer_assignment.dart';
import 'package:ecommerce_b2b/modules/sales_team/sales_representative/domain/repositories/sales_representative_repository.dart';
import 'package:ecommerce_b2b/modules/sales_team/sales_representative/domain/sales_representative.dart';
import 'package:ecommerce_b2b/modules/shared_kernel/domain/common/ids/representative_id.dart';
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
  }) async {
    emit(RepresentativeDashboardLoading());

    try {
      final currentRepId = RepresentativeId(session.userId.value);
      final selectedRepId = targetRepId ?? currentRepId;

      // Load selected rep details
      final selectedRep = await _representativeRepository.findById(
        selectedRepId,
      );
      final selectedRepName = selectedRep?.fullName ?? 'Representante';

      // A API já devolve a equipe do supervisor em /api/me/team.
      List<SalesRepresentative> subordinates = [];
      if (session.isSupervisor) {
        final allReps = await _representativeRepository.findAll();
        subordinates = allReps
            .where((rep) => rep.id.value != session.userId.value)
            .toList();
      }

      final commissionsResult = await _getCommissionsUseCase.execute(
        selectedRepId,
        session,
      );
      final portfolioResult = await _getCustomerPortfolioUseCase.execute(
        selectedRepId,
        session,
      );
      final quotesResult = await _getRecentQuotesUseCase.execute(
        selectedRepId,
        session,
      );

      if (commissionsResult.isSuccess &&
          portfolioResult.isSuccess &&
          quotesResult.isSuccess) {
        emit(
          RepresentativeDashboardLoaded(
            commissions: commissionsResult.getOrThrow(),
            assignments: portfolioResult.getOrThrow(),
            recentQuotes: quotesResult.getOrThrow(),
            subordinates: subordinates,
            selectedRepId: selectedRepId,
            selectedRepName: selectedRepName,
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
}
