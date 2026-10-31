import 'package:ecommerce_b2b/app/core/errors/app_error.dart';
import 'package:ecommerce_b2b/modules/customer_management/company/application/add_authorized_buyer/add_authorized_buyer_use_case.dart';
import 'package:ecommerce_b2b/modules/customer_management/company/application/get_companies/get_companies_use_case.dart';
import 'package:ecommerce_b2b/modules/customer_management/company/application/register_company/register_company_use_case.dart';
import 'package:ecommerce_b2b/modules/customer_management/company/model/company.dart';
import 'package:ecommerce_b2b/modules/identity_access/model/enums/user_role.dart';
import 'package:ecommerce_b2b/modules/identity_access/model/user_session.dart';
import 'package:ecommerce_b2b/modules/shared_kernel/model/common/ids/company_id.dart';
import 'package:ecommerce_b2b/modules/shared_kernel/model/common/ids/user_id.dart';
import 'package:ecommerce_b2b/app/core/result/result.dart';
import 'package:flutter_test/flutter_test.dart';

import '../fakes/fake_company_repository.dart';

void main() {
  late FakeCompanyRepository companyRepository;
  late GetCompaniesUseCase getCompaniesUseCase;
  late RegisterCompanyUseCase registerCompanyUseCase;
  late AddAuthorizedBuyerUseCase addAuthorizedBuyerUseCase;

  setUp(() {
    companyRepository = FakeCompanyRepository();
    getCompaniesUseCase = GetCompaniesUseCase(companyRepository);
    registerCompanyUseCase = RegisterCompanyUseCase(companyRepository);
    addAuthorizedBuyerUseCase = AddAuthorizedBuyerUseCase(companyRepository);
  });

  final representativeSession = UserSession(
    userId: const UserId('rep-456'),
    role: UserRole.representative,
  );

  group('GetCompaniesUseCase', () {
    test('should delegate the list to the repository', () async {
      final result = await getCompaniesUseCase.execute(representativeSession);

      expect(result.isSuccess, isTrue);
      expect(result.getOrThrow().length, 2);
    });

    test('should pass the target representative to the repository', () async {
      final result = await getCompaniesUseCase.execute(
        representativeSession,
        targetRepresentativeId: 'rep-456',
      );

      expect(result.isSuccess, isTrue);
      expect(result.getOrThrow().length, 2);
    });
  });

  group('RegisterCompanyUseCase', () {
    Future<Result<Company, AppError>> register(String cnpj) =>
        registerCompanyUseCase.execute(
          currentSession: representativeSession,
          legalName: 'Test Legal Name S.A.',
          tradeName: 'Test Trade Name',
          cnpj: cnpj,
          inscricaoEstadual: '123456789',
          email: 'test@company.com',
          phone: '11999999999',
          billingStreet: 'Test Street',
          billingNumber: '100',
          billingNeighborhood: 'Neighborhood',
          billingCity: 'São Paulo',
          billingState: 'SP',
          billingZipCode: '01000-000',
          shippingStreet: 'Test Street',
          shippingNumber: '100',
          shippingNeighborhood: 'Neighborhood',
          shippingCity: 'São Paulo',
          shippingState: 'SP',
          shippingZipCode: '01000-000',
          creditLimit: 25000,
        );

    test('should validate and send a valid company', () async {
      final result = await register('12345678000195');

      expect(result.isSuccess, isTrue);
      expect(result.getOrThrow().tradeName, 'Test Trade Name');
    });

    test('should reject an invalid CNPJ before calling the API', () async {
      final result = await register('11111111111111');

      expect(result.isFailure, isTrue);
      expect(result.getFailureOrThrow().code, AppErrorCodes.cnpjInvalid);
    });
  });

  group('AddAuthorizedBuyerUseCase', () {
    test('should add the buyer returned by the repository', () async {
      final result = await addAuthorizedBuyerUseCase.execute(
        currentSession: representativeSession,
        companyId: const CompanyId('c1'),
        fullName: 'New Buyer Name',
        email: 'buyer@acme.com',
        phone: '11988888888',
        positionTitle: 'Buyer Manager',
        password: 'senha1234',
      );

      expect(result.isSuccess, isTrue);
      expect(result.getOrThrow().authorizedBuyers.length, 2);
    });
  });
}
