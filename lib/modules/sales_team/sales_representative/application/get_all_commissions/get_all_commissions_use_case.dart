import 'package:ecommerce_b2b/app/core/errors/app_error.dart';
import 'package:ecommerce_b2b/app/core/network/api_exception.dart';
import 'package:ecommerce_b2b/app/core/result/result.dart';
import 'package:ecommerce_b2b/modules/sales_team/sales_representative/model/commission.dart';
import 'package:ecommerce_b2b/modules/sales_team/sales_representative/model/repositories/sales_representative_repository.dart';

/// Comissões de todos os representantes (visão de backoffice).
///
/// A autorização é da API: Finance/Admin recebem a lista; os demais papéis
/// recebem 403.
class GetAllCommissionsUseCase {
  final SalesRepresentativeRepository _representativeRepository;

  GetAllCommissionsUseCase(this._representativeRepository);

  Future<Result<List<Commission>, AppError>> execute() async {
    try {
      return Success(await _representativeRepository.getAllCommissions());
    } on ApiException catch (error) {
      return Failure(error.toAppError());
    } catch (error) {
      return Failure(AppError(AppErrorCodes.networkError, error.toString()));
    }
  }
}
