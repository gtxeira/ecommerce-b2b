import 'package:ecommerce_b2b/app/core/errors/app_error.dart';
import 'package:ecommerce_b2b/app/core/network/api_exception.dart';
import 'package:ecommerce_b2b/modules/identity_access/model/enums/user_role.dart';
import 'package:ecommerce_b2b/modules/identity_access/model/user_session.dart';
import 'package:ecommerce_b2b/modules/sales_team/sales_representative/application/get_commissions/get_representative_commissions_use_case.dart';
import 'package:ecommerce_b2b/modules/sales_team/sales_representative/model/commission.dart';
import 'package:ecommerce_b2b/modules/sales_team/sales_representative/model/enums/commission_status.dart';
import 'package:ecommerce_b2b/modules/sales_team/sales_representative/model/repositories/sales_representative_repository.dart';
import 'package:ecommerce_b2b/modules/shared_kernel/model/common/ids/representative_id.dart';
import 'package:ecommerce_b2b/modules/shared_kernel/model/finance/value_objects/money.dart';
import 'package:ecommerce_b2b/modules/shared_kernel/model/finance/value_objects/percentage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockSalesRepresentativeRepository extends Mock
    implements SalesRepresentativeRepository {}

void main() {
  late MockSalesRepresentativeRepository repository;
  late GetRepresentativeCommissionsUseCase useCase;

  setUp(() {
    repository = MockSalesRepresentativeRepository();
    useCase = GetRepresentativeCommissionsUseCase(repository);
  });

  final repId = const RepresentativeId('rep-1');
  final session = UserSession(userId: repId, role: UserRole.representative);

  group('GetRepresentativeCommissionsUseCase', () {
    test(
      'should request the target representative commissions from the API',
      () async {
        final commission = Commission(
          baseAmount: Money.create(1000).getOrThrow(),
          rate: Percentage.create(5).getOrThrow(),
          amount: Money.create(50).getOrThrow(),
          status: CommissionStatus.approved,
        );
        when(
          () => repository.getCommissions(representativeId: 'rep-1'),
        ).thenAnswer((_) async => [commission]);

        final result = await useCase.execute(repId, session);

        expect(result.isSuccess, isTrue);
        expect(result.getOrThrow().single.amount.amount, 50);
        verify(
          () => repository.getCommissions(representativeId: 'rep-1'),
        ).called(1);
      },
    );

    test(
      'should translate a 403 from the API preserving the API code',
      () async {
        when(
          () => repository.getCommissions(representativeId: 'rep-1'),
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
