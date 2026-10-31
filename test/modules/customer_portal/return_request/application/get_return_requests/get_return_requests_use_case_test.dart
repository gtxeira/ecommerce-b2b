import 'package:ecommerce_b2b/app/core/network/api_exception.dart';
import 'package:ecommerce_b2b/modules/customer_portal/return_request/application/get_return_requests/get_return_requests_use_case.dart';
import 'package:ecommerce_b2b/modules/customer_portal/return_request/domain/enums/rma_status.dart';
import 'package:ecommerce_b2b/modules/customer_portal/return_request/domain/repositories/return_request_repository.dart';
import 'package:ecommerce_b2b/modules/customer_portal/return_request/domain/return_request.dart';
import 'package:ecommerce_b2b/modules/identity_access/domain/enums/user_role.dart';
import 'package:ecommerce_b2b/modules/identity_access/domain/user_session.dart';
import 'package:ecommerce_b2b/modules/shared_kernel/domain/auth/errors/auth_errors.dart';
import 'package:ecommerce_b2b/modules/shared_kernel/domain/common/ids/company_id.dart';
import 'package:ecommerce_b2b/modules/shared_kernel/domain/common/ids/rma_id.dart';
import 'package:ecommerce_b2b/modules/shared_kernel/domain/common/ids/user_id.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockReturnRequestRepository extends Mock implements ReturnRequestRepository {}

class CompanyIdFake extends Fake implements CompanyId {}

void main() {
  setUpAll(() => registerFallbackValue(CompanyIdFake()));

  group('GetReturnRequestsUseCase', () {
    late MockReturnRequestRepository repository;
    late GetReturnRequestsUseCase useCase;

    const companyId = CompanyId('c1');
    final session = UserSession(
      userId: const UserId('buyer1'),
      role: UserRole.buyer,
      companyId: companyId,
    );

    setUp(() {
      repository = MockReturnRequestRepository();
      useCase = GetReturnRequestsUseCase(repository);
    });

    test('should delegate the company filter to the API repository', () async {
      final rma = ReturnRequest(
        id: const RmaId('r1'),
        orderId: 'o1',
        status: RmaStatus.pending,
        reason: 'Defeito',
      );
      when(() => repository.findByCompanyId(companyId))
          .thenAnswer((_) async => [rma]);

      final result = await useCase.execute(companyId, session);

      expect(result.isSuccess, isTrue);
      expect(result.getOrThrow().single.id.value, 'r1');
      verify(() => repository.findByCompanyId(companyId)).called(1);
    });

    test('should translate a 403 from the API into UnauthorizedError', () async {
      when(() => repository.findByCompanyId(companyId)).thenThrow(
        const ApiException(
          statusCode: 403,
          code: 'FORBIDDEN',
          message: 'Você só pode acessar RMAs da sua empresa.',
        ),
      );

      final result = await useCase.execute(companyId, session);

      expect(result.isFailure, isTrue);
      expect(result.getFailureOrThrow(), isA<UnauthorizedError>());
    });
  });
}
