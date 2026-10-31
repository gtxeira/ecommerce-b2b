import 'package:ecommerce_b2b/app/core/errors/app_error.dart';
import 'package:ecommerce_b2b/app/core/network/api_exception.dart';
import 'package:ecommerce_b2b/modules/identity_access/model/enums/user_role.dart';
import 'package:ecommerce_b2b/modules/identity_access/model/user_session.dart';
import 'package:ecommerce_b2b/modules/sales_team/sales_representative/application/get_customers/get_customer_portfolio_use_case.dart';
import 'package:ecommerce_b2b/modules/sales_team/sales_representative/model/customer_assignment.dart';
import 'package:ecommerce_b2b/modules/sales_team/sales_representative/model/repositories/sales_representative_repository.dart';
import 'package:ecommerce_b2b/modules/shared_kernel/model/common/ids/company_id.dart';
import 'package:ecommerce_b2b/modules/shared_kernel/model/common/ids/representative_id.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockSalesRepresentativeRepository extends Mock
    implements SalesRepresentativeRepository {}

void main() {
  late MockSalesRepresentativeRepository repository;
  late GetCustomerPortfolioUseCase useCase;

  setUp(() {
    repository = MockSalesRepresentativeRepository();
    useCase = GetCustomerPortfolioUseCase(repository);
  });

  final repId = const RepresentativeId('rep-1');
  final session = UserSession(userId: repId, role: UserRole.representative);

  group('GetCustomerPortfolioUseCase', () {
    test('should request the portfolio from the API', () async {
      when(
        () => repository.getPortfolio(representativeId: 'rep-1'),
      ).thenAnswer((_) async => [const CustomerAssignment(CompanyId('c1'))]);

      final result = await useCase.execute(repId, session);

      expect(result.isSuccess, isTrue);
      expect(result.getOrThrow().single.companyId.value, 'c1');
    });

    test(
      'should translate a 403 from the API preserving the API code',
      () async {
        when(
          () => repository.getPortfolio(representativeId: 'rep-1'),
        ).thenThrow(
          const ApiException(
            statusCode: 403,
            code: 'FORBIDDEN',
            message: 'Sem permissão.',
          ),
        );

        final result = await useCase.execute(repId, session);

        expect(result.isFailure, isTrue);
        expect(result.getFailureOrThrow().code, AppErrorCodes.forbidden);
      },
    );
  });
}
