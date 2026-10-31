import 'package:ecommerce_b2b/app/core/network/api_exception.dart';
import 'package:ecommerce_b2b/modules/customer_management/company/domain/company.dart';
import 'package:ecommerce_b2b/modules/customer_management/company/domain/repositories/company_repository.dart';
import 'package:ecommerce_b2b/modules/identity_access/domain/user_session.dart';
import 'package:ecommerce_b2b/app/core/errors/app_error.dart';
import 'package:ecommerce_b2b/modules/shared_kernel/domain/common/ids/company_id.dart';
import 'package:ecommerce_b2b/modules/shared_kernel/domain/contact/value_objects/email_address.dart';
import 'package:ecommerce_b2b/modules/shared_kernel/domain/contact/value_objects/phone_number.dart';
import 'package:ecommerce_b2b/app/core/result/result.dart';

class AddAuthorizedBuyerUseCase {
  final CompanyRepository _companyRepository;

  AddAuthorizedBuyerUseCase(this._companyRepository);

  Future<Result<Company, AppError>> execute({
    required UserSession currentSession,
    required CompanyId companyId,
    required String fullName,
    required String email,
    required String phone,
    required String positionTitle,
  }) async {
    final company = await _companyRepository.findById(companyId);
    if (company == null) {
      return Failure(
        const AppError(
          AppErrorCodes.companyNotFound,
          'Empresa não encontrada.',
        ),
      );
    }

    final emailResult = EmailAddress.create(email);
    if (emailResult.isFailure) return Failure(emailResult.getFailureOrThrow());

    final phoneResult = PhoneNumber.create(phone);
    if (phoneResult.isFailure) return Failure(phoneResult.getFailureOrThrow());

    try {
      // A API é a dona do cadastro: devolve o comprador já com o id gerado.
      final buyer = await _companyRepository.addAuthorizedBuyer(
        companyId: companyId,
        fullName: fullName,
        email: emailResult.getOrThrow().value,
        phone: phoneResult.getOrThrow().value,
        positionTitle: positionTitle,
      );

      company.addAuthorizedBuyer(buyer);
      return Success(company);
    } on ApiException catch (error) {
      return Failure(error.toAppError());
    } catch (error) {
      return Failure(AppError(AppErrorCodes.networkError, error.toString()));
    }
  }
}
