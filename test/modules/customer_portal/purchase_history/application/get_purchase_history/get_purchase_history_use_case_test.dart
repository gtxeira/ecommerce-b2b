import 'package:ecommerce_b2b/app/core/network/api_exception.dart';
import 'package:ecommerce_b2b/modules/customer_portal/purchase_history/application/get_purchase_history/get_purchase_history_use_case.dart';
import 'package:ecommerce_b2b/modules/identity_access/domain/enums/user_role.dart';
import 'package:ecommerce_b2b/modules/identity_access/domain/user_session.dart';
import 'package:ecommerce_b2b/modules/order_flow/sales_order/domain/repositories/sales_order_repository.dart';
import 'package:ecommerce_b2b/modules/shared_kernel/domain/auth/errors/auth_errors.dart';
import 'package:ecommerce_b2b/modules/shared_kernel/domain/common/ids/company_id.dart';
import 'package:ecommerce_b2b/modules/shared_kernel/domain/common/ids/user_id.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockSalesOrderRepository extends Mock implements SalesOrderRepository {}

class CompanyIdFake extends Fake implements CompanyId {}

void main() {
  setUpAll(() => registerFallbackValue(CompanyIdFake()));

  group('GetPurchaseHistoryUseCase', () {
    late MockSalesOrderRepository repository;
    late GetPurchaseHistoryUseCase useCase;

    const companyId = CompanyId('my-company');
    final session = UserSession(
      userId: const UserId('user-1'),
      role: UserRole.buyer,
      companyId: companyId,
    );

    setUp(() {
      repository = MockSalesOrderRepository();
      useCase = GetPurchaseHistoryUseCase(repository);
    });

    test('should delegate to the API repository', () async {
      when(() => repository.findByCompanyId(companyId))
          .thenAnswer((_) async => []);

      final result = await useCase.execute(companyId, session);

      expect(result.isSuccess, isTrue);
      verify(() => repository.findByCompanyId(companyId)).called(1);
    });

    test('should translate a 403 from the API into UnauthorizedError', () async {
      when(() => repository.findByCompanyId(companyId)).thenThrow(
        const ApiException(
          statusCode: 403,
          code: 'FORBIDDEN',
          message: 'Você só pode ver a sua empresa.',
        ),
      );

      final result = await useCase.execute(companyId, session);

      expect(result.isFailure, isTrue);
      expect(result.getFailureOrThrow(), isA<UnauthorizedError>());
    });
  });
}
