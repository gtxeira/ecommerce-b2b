import 'package:ecommerce_b2b/modules/identity_access/model/user_session.dart';
import 'package:ecommerce_b2b/modules/sales_team/sales_representative/application/get_commissions/get_representative_commissions_use_case.dart';
import 'package:ecommerce_b2b/modules/sales_team/sales_representative/model/commission.dart';
import 'package:ecommerce_b2b/modules/sales_team/sales_representative/model/repositories/sales_representative_repository.dart';
import 'package:ecommerce_b2b/modules/sales_team/sales_representative/model/sales_representative.dart';
import 'package:ecommerce_b2b/modules/shared_kernel/model/common/ids/representative_id.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';

part 'commission_list_state.dart';

class CommissionListCubit extends Cubit<CommissionListState> {
  final GetRepresentativeCommissionsUseCase _getCommissionsUseCase;
  final SalesRepresentativeRepository _representativeRepository;

  CommissionListCubit({
    required this._getCommissionsUseCase,
    required this._representativeRepository,
  }) : super(CommissionListInitial());

  Future<void> load(
    UserSession session, {
    RepresentativeId? targetRepId,
    bool teamView = false,
  }) async {
    emit(CommissionListLoading());

    try {
      final selfId = RepresentativeId(session.userId.value);
      final selectedRepId = targetRepId ?? selfId;
      final allReps = await _representativeRepository.findAll();
      final subordinates = allReps
          .where((rep) => rep.id.value != selfId.value)
          .toList();
      final selectedRepName = teamView
          ? 'Toda a Equipe'
          : _nameOf(allReps, selectedRepId);

      final result = await _getCommissionsUseCase.execute(
        selectedRepId,
        session,
        teamScope: teamView,
      );

      result.fold(
        (error) => emit(CommissionListFailure(error.message)),
        (commissions) => emit(
          CommissionListLoaded(
            commissions: commissions,
            subordinates: subordinates,
            selectedRepId: selectedRepId,
            selectedRepName: selectedRepName,
            isTeamView: teamView,
          ),
        ),
      );
    } catch (error) {
      emit(CommissionListFailure(error.toString()));
    }
  }

  String _nameOf(List<SalesRepresentative> reps, RepresentativeId id) {
    for (final rep in reps) {
      if (rep.id == id) return rep.fullName;
    }
    return 'Representante';
  }
}
