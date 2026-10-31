import 'package:ecommerce_b2b/app/core/network/api_exception.dart';
import 'package:ecommerce_b2b/modules/customer_portal/return_request/domain/repositories/return_request_repository.dart';
import 'package:ecommerce_b2b/modules/customer_portal/return_request/domain/return_request.dart';
import 'package:ecommerce_b2b/modules/identity_access/domain/user_session.dart';
import 'package:ecommerce_b2b/app/core/errors/app_error.dart';
import 'package:ecommerce_b2b/modules/shared_kernel/domain/common/ids/company_id.dart';
import 'package:ecommerce_b2b/app/core/result/result.dart';

/// RMAs da empresa (RF21). A API resolve o dono e a hierarquia.
class GetReturnRequestsUseCase {
  final ReturnRequestRepository _returnRequestRepository;

  GetReturnRequestsUseCase(this._returnRequestRepository);

  Future<Result<List<ReturnRequest>, AppError>> execute(
    CompanyId companyId,
    UserSession currentSession,
  ) async {
    try {
      return Success(await _returnRequestRepository.findByCompanyId(companyId));
    } on ApiException catch (error) {
      return Failure(error.toAppError());
    } catch (error) {
      return Failure(AppError(AppErrorCodes.networkError, error.toString()));
    }
  }
}
