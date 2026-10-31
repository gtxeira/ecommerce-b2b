import 'package:ecommerce_b2b/app/core/network/api_exception.dart';
import 'package:ecommerce_b2b/modules/identity_access/domain/user_session.dart';
import 'package:ecommerce_b2b/modules/sales_team/sales_representative/domain/commission.dart';
import 'package:ecommerce_b2b/modules/sales_team/sales_representative/domain/repositories/sales_representative_repository.dart';
import 'package:ecommerce_b2b/modules/shared_kernel/domain/auth/errors/auth_errors.dart';
import 'package:ecommerce_b2b/modules/shared_kernel/domain/common/ids/representative_id.dart';
import 'package:ecommerce_b2b/modules/shared_kernel/functional/result.dart';

/// Comissões do representante (RN2/RN9). A hierarquia é validada na API.
class GetRepresentativeCommissionsUseCase {
  final SalesRepresentativeRepository _representativeRepository;

  GetRepresentativeCommissionsUseCase(this._representativeRepository);

  Future<Result<List<Commission>, AuthError>> execute(
    RepresentativeId targetRepId,
    UserSession currentSession,
  ) async {
    try {
      return Success(await _representativeRepository.getCommissions(
        representativeId: targetRepId.value,
      ));
    } on ApiException catch (error) {
      return Failure(UnauthorizedError(error.message));
    } catch (error) {
      return Failure(UnauthorizedError(error.toString()));
    }
  }
}
