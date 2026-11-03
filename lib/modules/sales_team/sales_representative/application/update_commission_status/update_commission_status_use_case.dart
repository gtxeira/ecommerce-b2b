import 'package:ecommerce_b2b/app/core/errors/app_error.dart';
import 'package:ecommerce_b2b/app/core/network/api_exception.dart';
import 'package:ecommerce_b2b/app/core/result/result.dart';
import 'package:ecommerce_b2b/modules/sales_team/sales_representative/model/commission.dart';
import 'package:ecommerce_b2b/modules/sales_team/sales_representative/model/enums/commission_status.dart';
import 'package:ecommerce_b2b/modules/sales_team/sales_representative/model/repositories/sales_representative_repository.dart';

/// Altera o status de uma comissão (Pending -> Paid | Cancelled).
///
/// A autorização é da API (Finance/Admin; supervisor na própria árvore;
/// representante nas próprias). O use case só transporta o erro tipado do 403/404/409.
class UpdateCommissionStatusUseCase {
  final SalesRepresentativeRepository _representativeRepository;

  UpdateCommissionStatusUseCase(this._representativeRepository);

  Future<Result<Commission, AppError>> execute(
    int commissionId,
    CommissionStatus status,
  ) async {
    try {
      return Success(
        await _representativeRepository.updateCommissionStatus(
          commissionId: commissionId,
          status: status,
        ),
      );
    } on ApiException catch (error) {
      return Failure(error.toAppError());
    } catch (error) {
      return Failure(AppError(AppErrorCodes.networkError, error.toString()));
    }
  }
}
