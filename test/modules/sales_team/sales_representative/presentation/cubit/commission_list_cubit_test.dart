import 'package:ecommerce_b2b/app/core/result/result.dart';
import 'package:ecommerce_b2b/modules/identity_access/model/enums/user_role.dart';
import 'package:ecommerce_b2b/modules/identity_access/model/user_session.dart';
import 'package:ecommerce_b2b/modules/sales_team/sales_representative/application/get_all_commissions/get_all_commissions_use_case.dart';
import 'package:ecommerce_b2b/modules/sales_team/sales_representative/application/get_commissions/get_representative_commissions_use_case.dart';
import 'package:ecommerce_b2b/modules/sales_team/sales_representative/application/update_commission_status/update_commission_status_use_case.dart';
import 'package:ecommerce_b2b/modules/sales_team/sales_representative/model/commission.dart';
import 'package:ecommerce_b2b/modules/sales_team/sales_representative/model/enums/commission_status.dart';
import 'package:ecommerce_b2b/modules/sales_team/sales_representative/model/repositories/sales_representative_repository.dart';
import 'package:ecommerce_b2b/modules/sales_team/sales_representative/model/sales_representative.dart';
import 'package:ecommerce_b2b/modules/sales_team/sales_representative/presentation/cubit/commission_list_cubit.dart';
import 'package:ecommerce_b2b/modules/shared_kernel/model/common/ids/representative_id.dart';
import 'package:ecommerce_b2b/modules/shared_kernel/model/common/ids/user_id.dart';
import 'package:ecommerce_b2b/modules/shared_kernel/model/contact/value_objects/email_address.dart';
import 'package:ecommerce_b2b/modules/shared_kernel/model/finance/value_objects/money.dart';
import 'package:ecommerce_b2b/modules/shared_kernel/model/finance/value_objects/percentage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockGetCommissions extends Mock
    implements GetRepresentativeCommissionsUseCase {}

class MockGetAllCommissions extends Mock implements GetAllCommissionsUseCase {}

class MockUpdateCommissionStatus extends Mock
    implements UpdateCommissionStatusUseCase {}

class MockSalesRepresentativeRepository extends Mock
    implements SalesRepresentativeRepository {}

void main() {
  setUpAll(() {
    registerFallbackValue(const RepresentativeId('rep-fallback'));
    registerFallbackValue(
      UserSession(
        userId: const UserId('fallback'),
        role: UserRole.representative,
      ),
    );
  });

  late MockGetCommissions getCommissions;
  late MockGetAllCommissions getAllCommissions;
  late MockUpdateCommissionStatus updateCommissionStatus;
  late MockSalesRepresentativeRepository repository;
  late CommissionListCubit cubit;

  Commission commission(String repId, {int id = 1}) => Commission(
    id: id,
    baseAmount: Money.create(1000).getOrThrow(),
    rate: Percentage.create(5).getOrThrow(),
    amount: Money.create(50).getOrThrow(),
    status: CommissionStatus.pending,
    representativeId: repId,
    representativeName: repId,
  );

  SalesRepresentative rep(String id) => SalesRepresentative(
    id: RepresentativeId(id),
    fullName: 'Rep $id',
    email: EmailAddress.create('$id@test.com').getOrThrow(),
    commissionRate: Percentage.create(5).getOrThrow(),
  );

  setUp(() {
    getCommissions = MockGetCommissions();
    getAllCommissions = MockGetAllCommissions();
    updateCommissionStatus = MockUpdateCommissionStatus();
    repository = MockSalesRepresentativeRepository();
    cubit = CommissionListCubit(
      getCommissionsUseCase: getCommissions,
      getAllCommissionsUseCase: getAllCommissions,
      representativeRepository: repository,
      updateCommissionStatusUseCase: updateCommissionStatus,
    );
  });

  test('admin carrega a visão global sem consultar a equipe', () async {
    when(() => getAllCommissions.execute()).thenAnswer(
      (_) async => Success([commission('rep-1'), commission('rep-2', id: 2)]),
    );
    final session = UserSession(
      userId: const UserId('admin-1'),
      role: UserRole.admin,
    );

    await cubit.load(session);

    final state = cubit.state as CommissionListLoaded;
    expect(state.commissions, hasLength(2));
    expect(state.subordinates, isEmpty);
    expect(state.selectedRepName, 'Todos os representantes');
    expect(state.isTeamView, isFalse);
    verify(() => getAllCommissions.execute()).called(1);
    verifyNever(() => repository.findAll());
    verifyNever(
      () => getCommissions.execute(
        any(),
        any(),
        teamScope: any(named: 'teamScope'),
      ),
    );
  });

  test('financeiro carrega a visão global', () async {
    when(
      () => getAllCommissions.execute(),
    ).thenAnswer((_) async => Success([commission('rep-1')]));
    final session = UserSession(
      userId: const UserId('fin-1'),
      role: UserRole.finance,
    );

    await cubit.load(session);

    expect(cubit.state, isA<CommissionListLoaded>());
    verify(() => getAllCommissions.execute()).called(1);
  });

  test('representante continua no escopo pessoal', () async {
    final selfId = const RepresentativeId('rep-1');
    final session = UserSession(
      userId: const UserId('rep-1'),
      role: UserRole.representative,
    );
    when(() => repository.findAll()).thenAnswer((_) async => [rep('rep-1')]);
    when(
      () => getCommissions.execute(selfId, session, teamScope: false),
    ).thenAnswer((_) async => Success([commission('rep-1')]));

    await cubit.load(session);

    final state = cubit.state as CommissionListLoaded;
    expect(state.commissions, hasLength(1));
    expect(state.selectedRepName, 'Rep rep-1');
    verifyNever(() => getAllCommissions.execute());
  });
}
