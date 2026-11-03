import 'package:ecommerce_b2b/modules/customer_management/company/application/add_authorized_buyer/add_authorized_buyer_use_case.dart';
import 'package:ecommerce_b2b/modules/customer_management/company/application/get_companies/get_companies_use_case.dart';
import 'package:ecommerce_b2b/modules/customer_management/company/application/register_company/register_company_use_case.dart';
import '../fakes/fake_company_repository.dart';
import '../fakes/fake_sales_representative_repository.dart';
import 'package:ecommerce_b2b/modules/customer_management/company/presentation/cubit/company_management_cubit.dart';
import 'package:ecommerce_b2b/modules/identity_access/model/enums/user_role.dart';
import 'package:ecommerce_b2b/modules/identity_access/model/user_session.dart';
import 'package:ecommerce_b2b/modules/shared_kernel/model/common/ids/company_id.dart';
import 'package:ecommerce_b2b/modules/shared_kernel/model/common/ids/user_id.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late FakeCompanyRepository companyRepository;
  late FakeSalesRepresentativeRepository repRepository;
  late GetCompaniesUseCase getCompaniesUseCase;
  late RegisterCompanyUseCase registerCompanyUseCase;
  late AddAuthorizedBuyerUseCase addAuthorizedBuyerUseCase;
  late CompanyManagementCubit cubit;

  setUp(() {
    companyRepository = FakeCompanyRepository();
    repRepository = FakeSalesRepresentativeRepository();
    getCompaniesUseCase = GetCompaniesUseCase(companyRepository);
    registerCompanyUseCase = RegisterCompanyUseCase(companyRepository);
    addAuthorizedBuyerUseCase = AddAuthorizedBuyerUseCase(companyRepository);
    cubit = CompanyManagementCubit(
      getCompaniesUseCase: getCompaniesUseCase,
      registerCompanyUseCase: registerCompanyUseCase,
      addAuthorizedBuyerUseCase: addAuthorizedBuyerUseCase,
      representativeRepository: repRepository,
    );
  });

  tearDown(() {
    cubit.close();
  });

  group('CompanyManagementCubit', () {
    test('initial state should be CompanyManagementInitial', () {
      expect(cubit.state, isA<CompanyManagementInitial>());
    });

    test('loadCompanies should emit Loading and then Loaded', () async {
      final session = UserSession(
        userId: const UserId('finance-1'),
        role: UserRole.finance,
      );

      final states = <CompanyManagementState>[];
      cubit.stream.listen(states.add);

      await cubit.loadCompanies(session);
      await Future.delayed(Duration.zero);

      expect(states, [
        isA<CompanyManagementLoading>(),
        isA<CompanyManagementLoaded>(),
      ]);

      final loadedState = states[1] as CompanyManagementLoaded;
      expect(loadedState.companies.length, 2);
    });

    test('registerCompany should emit Loading, Success, and Loaded', () async {
      final session = UserSession(
        userId: const UserId('rep-456'),
        role: UserRole.representative,
      );

      final states = <CompanyManagementState>[];
      cubit.stream.listen(states.add);

      await cubit.registerCompany(
        currentSession: session,
        legalName: 'Test Legal Name S.A.',
        tradeName: 'Test Trade Name',
        cnpj: '12345678000195',
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
        creditLimit: 30000,
      );
      await Future.delayed(Duration.zero);

      expect(states, [
        isA<CompanyManagementLoading>(),
        isA<CompanyManagementSuccess>(),
        isA<CompanyManagementLoading>(),
        isA<CompanyManagementLoaded>(),
      ]);

      final loadedState = states[3] as CompanyManagementLoaded;
      expect(loadedState.companies.length, 3);
    });

    test(
      'addAuthorizedBuyer should emit Loading, Success, and Loaded',
      () async {
        final session = UserSession(
          userId: const UserId('rep-456'),
          role: UserRole.representative,
        );

        final states = <CompanyManagementState>[];
        cubit.stream.listen(states.add);

        await cubit.addAuthorizedBuyer(
          currentSession: session,
          companyId: const CompanyId('c1'),
          fullName: 'New Buyer',
          email: 'buyer@acme.com',
          phone: '11988888888',
          positionTitle: 'Buyer manager',
          password: 'senha1234',
        );
        await Future.delayed(Duration.zero);

        expect(states, [
          isA<CompanyManagementLoading>(),
          isA<CompanyManagementSuccess>(),
          isA<CompanyManagementLoading>(),
          isA<CompanyManagementLoaded>(),
        ]);
      },
    );
  });
}
