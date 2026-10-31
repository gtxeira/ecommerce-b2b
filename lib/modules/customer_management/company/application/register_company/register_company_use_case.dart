import 'package:ecommerce_b2b/app/core/network/api_exception.dart';
import 'package:ecommerce_b2b/modules/customer_management/company/model/company.dart';
import 'package:ecommerce_b2b/modules/customer_management/company/model/customer_credit_account.dart';
import 'package:ecommerce_b2b/modules/customer_management/company/model/repositories/company_repository.dart';
import 'package:ecommerce_b2b/modules/customer_management/company/model/value_objects/cnpj.dart';
import 'package:ecommerce_b2b/modules/customer_management/company/model/value_objects/inscricao_estadual.dart';
import 'package:ecommerce_b2b/modules/identity_access/model/user_session.dart';
import 'package:ecommerce_b2b/app/core/errors/app_error.dart';
import 'package:ecommerce_b2b/modules/shared_kernel/model/address/enums/state.dart';
import 'package:ecommerce_b2b/modules/shared_kernel/model/address/value_objects/address.dart';
import 'package:ecommerce_b2b/modules/shared_kernel/model/common/ids/company_id.dart';
import 'package:ecommerce_b2b/modules/shared_kernel/model/contact/value_objects/email_address.dart';
import 'package:ecommerce_b2b/modules/shared_kernel/model/contact/value_objects/phone_number.dart';
import 'package:ecommerce_b2b/modules/shared_kernel/model/finance/value_objects/money.dart';
import 'package:ecommerce_b2b/app/core/result/result.dart';

class RegisterCompanyUseCase {
  final CompanyRepository _companyRepository;

  RegisterCompanyUseCase(this._companyRepository);

  Future<Result<Company, AppError>> execute({
    required UserSession currentSession,
    required String legalName,
    required String tradeName,
    required String cnpj,
    required String inscricaoEstadual,
    required String email,
    required String phone,
    required String billingStreet,
    required String billingNumber,
    String? billingComplement,
    required String billingNeighborhood,
    required String billingCity,
    required String billingState,
    required String billingZipCode,
    required String shippingStreet,
    required String shippingNumber,
    String? shippingComplement,
    required String shippingNeighborhood,
    required String shippingCity,
    required String shippingState,
    required String shippingZipCode,
    required double creditLimit,
  }) async {
    final cnpjResult = Cnpj.create(cnpj);
    if (cnpjResult.isFailure) return Failure(cnpjResult.getFailureOrThrow());

    final ieResult = InscricaoEstadual.create(inscricaoEstadual);
    if (ieResult.isFailure) return Failure(ieResult.getFailureOrThrow());

    final emailResult = EmailAddress.create(email);
    if (emailResult.isFailure) return Failure(emailResult.getFailureOrThrow());

    final phoneResult = PhoneNumber.create(phone);
    if (phoneResult.isFailure) return Failure(phoneResult.getFailureOrThrow());

    final billingAddressResult = Address.create(
      street: billingStreet,
      number: billingNumber,
      complement: billingComplement,
      neighborhood: billingNeighborhood,
      city: billingCity,
      state: billingState,
      zipCode: billingZipCode,
    );
    if (billingAddressResult.isFailure) {
      return Failure(billingAddressResult.getFailureOrThrow());
    }

    final shippingAddressResult = Address.create(
      street: shippingStreet,
      number: shippingNumber,
      complement: shippingComplement,
      neighborhood: shippingNeighborhood,
      city: shippingCity,
      state: shippingState,
      zipCode: shippingZipCode,
    );
    if (shippingAddressResult.isFailure) {
      return Failure(shippingAddressResult.getFailureOrThrow());
    }

    final stateResult = State.fromString(billingState);
    if (stateResult.isFailure) return Failure(stateResult.getFailureOrThrow());

    final creditLimitResult = Money.create(creditLimit);
    if (creditLimitResult.isFailure) {
      return Failure(creditLimitResult.getFailureOrThrow());
    }

    final companyId = CompanyId('c-${DateTime.now().millisecondsSinceEpoch}');
    final creditLimitObj = creditLimitResult.getOrThrow();

    final company = Company(
      id: companyId,
      legalName: legalName,
      tradeName: tradeName,
      cnpj: cnpjResult.getOrThrow(),
      inscricaoEstadual: ieResult.getOrThrow(),
      email: emailResult.getOrThrow(),
      phone: phoneResult.getOrThrow(),
      billingAddress: billingAddressResult.getOrThrow(),
      shippingAddress: shippingAddressResult.getOrThrow(),
      state: stateResult.getOrThrow(),
      creditLimit: creditLimitObj,
      authorizedBuyers: [],
      creditAccount: CustomerCreditAccount(
        preApprovedLimit: creditLimitObj,
        openBalance: Money.create(0).getOrThrow(),
        pendingOrdersBalance: Money.create(0).getOrThrow(),
      ),
    );

    try {
      await _companyRepository.save(company);
      return Success(company);
    } on ApiException catch (error) {
      return Failure(error.toAppError());
    } catch (error) {
      return Failure(AppError(AppErrorCodes.networkError, error.toString()));
    }
  }
}
