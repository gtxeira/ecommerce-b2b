import 'package:ecommerce_b2b/app/core/network/api_exception.dart';
import 'package:ecommerce_b2b/modules/customer_management/company/domain/company.dart';
import 'package:ecommerce_b2b/modules/customer_management/company/domain/repositories/company_repository.dart';
import 'package:ecommerce_b2b/modules/identity_access/domain/user_session.dart';
import 'package:ecommerce_b2b/app/core/errors/app_error.dart';
import 'package:ecommerce_b2b/app/core/result/result.dart';

/// Empresas acessíveis à sessão. O recorte de papel/carteira é da API.
class GetCompaniesUseCase {
  final CompanyRepository _companyRepository;

  GetCompaniesUseCase(this._companyRepository);

  Future<Result<List<Company>, AppError>> execute(
    UserSession currentSession, {
    String? targetRepresentativeId,
  }) async {
    try {
      final companies = targetRepresentativeId != null
          ? await _companyRepository.findByRepresentativeId(
              targetRepresentativeId,
            )
          : await _companyRepository.findAll();
      return Success(companies);
    } on ApiException catch (error) {
      return Failure(error.toAppError());
    } catch (error) {
      return Failure(AppError(AppErrorCodes.networkError, error.toString()));
    }
  }
}
