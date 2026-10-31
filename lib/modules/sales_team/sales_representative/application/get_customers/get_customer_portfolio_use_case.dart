import 'package:ecommerce_b2b/app/core/network/api_exception.dart';
import 'package:ecommerce_b2b/modules/identity_access/model/user_session.dart';
import 'package:ecommerce_b2b/modules/sales_team/sales_representative/model/customer_assignment.dart';
import 'package:ecommerce_b2b/modules/sales_team/sales_representative/model/repositories/sales_representative_repository.dart';
import 'package:ecommerce_b2b/app/core/errors/app_error.dart';
import 'package:ecommerce_b2b/modules/shared_kernel/model/common/ids/representative_id.dart';
import 'package:ecommerce_b2b/app/core/result/result.dart';

/// Carteira do representante (RN1/RN9). A hierarquia é validada na API.
class GetCustomerPortfolioUseCase {
  final SalesRepresentativeRepository _representativeRepository;

  GetCustomerPortfolioUseCase(this._representativeRepository);

  Future<Result<List<CustomerAssignment>, AppError>> execute(
    RepresentativeId targetRepId,
    UserSession currentSession,
  ) async {
    try {
      return Success(
        await _representativeRepository.getPortfolio(
          representativeId: targetRepId.value,
        ),
      );
    } on ApiException catch (error) {
      return Failure(error.toAppError());
    } catch (error) {
      return Failure(AppError(AppErrorCodes.networkError, error.toString()));
    }
  }
}
