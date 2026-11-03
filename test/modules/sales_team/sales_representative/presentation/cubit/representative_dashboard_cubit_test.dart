import 'package:ecommerce_b2b/app/core/result/result.dart';
import 'package:ecommerce_b2b/modules/identity_access/model/enums/user_role.dart';
import 'package:ecommerce_b2b/modules/identity_access/model/user_session.dart';
import 'package:ecommerce_b2b/modules/sales_team/sales_representative/application/get_commissions/get_representative_commissions_use_case.dart';
import 'package:ecommerce_b2b/modules/sales_team/sales_representative/application/get_customers/get_customer_portfolio_use_case.dart';
import 'package:ecommerce_b2b/modules/sales_team/sales_representative/application/get_quotes/get_recent_quotes_use_case.dart';
import 'package:ecommerce_b2b/modules/sales_team/sales_representative/model/commission.dart';
import 'package:ecommerce_b2b/modules/sales_team/sales_representative/model/customer_assignment.dart';
import 'package:ecommerce_b2b/modules/sales_team/sales_representative/model/enums/commission_status.dart';
import 'package:ecommerce_b2b/modules/sales_team/sales_representative/model/repositories/sales_representative_repository.dart';
import 'package:ecommerce_b2b/modules/sales_team/sales_representative/model/sales_representative.dart';
import 'package:ecommerce_b2b/modules/sales_team/sales_representative/presentation/cubit/representative_dashboard_cubit.dart';
import 'package:ecommerce_b2b/modules/shared_kernel/model/common/ids/company_id.dart';
import 'package:ecommerce_b2b/modules/shared_kernel/model/common/ids/representative_id.dart';
import 'package:ecommerce_b2b/modules/shared_kernel/model/contact/value_objects/email_address.dart';
import 'package:ecommerce_b2b/modules/shared_kernel/model/finance/value_objects/money.dart';
import 'package:ecommerce_b2b/modules/shared_kernel/model/finance/value_objects/percentage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockGetCommissions extends Mock
    implements GetRepresentativeCommissionsUseCase {}

class MockGetPortfolio extends Mock implements GetCustomerPortfolioUseCase {}

class MockGetQuotes extends Mock implements GetRecentQuotesUseCase {}

class MockSalesRepresentativeRepository extends Mock
    implements SalesRepresentativeRepository {}

void main() {
  late MockGetCommissions getCommissions;
  late MockGetPortfolio getPortfolio;
  late MockGetQuotes getQuotes;
  late MockSalesRepresentativeRepository repository;
  late RepresentativeDashboardCubit cubit;

  final selfId = const RepresentativeId('sup-1');
  final session = UserSession(
    userId: selfId,
    role: UserRole.supervisor,
    fullName: 'Supervisor',
  );

  SalesRepresentative rep(String id, String name) => SalesRepresentative(
    id: RepresentativeId(id),
    fullName: name,
    email: EmailAddress.create('$id@test.com').getOrThrow(),
    commissionRate: Percentage.create(5).getOrThrow(),
  );

  Commission commission(String repId, double amount) => Commission(
    baseAmount: Money.create(1000).getOrThrow(),
    rate: Percentage.create(5).getOrThrow(),
    amount: Money.create(amount).getOrThrow(),
    status: CommissionStatus.pending,
    representativeId: repId,
    representativeName: repId,
  );

  setUp(() {
    getCommissions = MockGetCommissions();
    getPortfolio = MockGetPortfolio();
    getQuotes = MockGetQuotes();
    repository = MockSalesRepresentativeRepository();
    cubit = RepresentativeDashboardCubit(
      getCommissionsUseCase: getCommissions,
      getCustomerPortfolioUseCase: getPortfolio,
      getRecentQuotesUseCase: getQuotes,
      representativeRepository: repository,
    );

    when(() => repository.findAll()).thenAnswer(
      (_) async => [rep('sup-1', 'Supervisor'), rep('rep-1', 'Representante')],
    );
    when(
      () => getCommissions.execute(selfId, session, teamScope: true),
    ).thenAnswer(
      (_) async => Success([commission('sup-1', 10), commission('rep-1', 25)]),
    );
    when(
      () => getPortfolio.execute(selfId, session, teamScope: true),
    ).thenAnswer(
      (_) async => Success([
        const CustomerAssignment(
          CompanyId('c1'),
          representativeId: 'sup-1',
          representativeName: 'Supervisor',
        ),
        const CustomerAssignment(
          CompanyId('c2'),
          representativeId: 'rep-1',
          representativeName: 'Representante',
        ),
        const CustomerAssignment(
          CompanyId('c2'),
          representativeId: 'rep-1',
          representativeName: 'Representante',
        ),
      ]),
    );
    when(
      () => getQuotes.execute(selfId, session, teamScope: true),
    ).thenAnswer((_) async => Success(const []));
  });

  test('team mode aggregates commissions and unique clients per rep', () async {
    await cubit.loadDashboard(session, teamView: true);

    final state = cubit.state;
    expect(state, isA<RepresentativeDashboardLoaded>());
    final loaded = state as RepresentativeDashboardLoaded;
    expect(loaded.isTeamView, isTrue);
    expect(loaded.clientCount, 2);
    expect(loaded.performances, hasLength(2));

    final supervisor = loaded.performances.firstWhere((p) => p.isSelf);
    final subordinate = loaded.performances.firstWhere((p) => !p.isSelf);
    expect(supervisor.commissionTotal.amount, 10);
    expect(supervisor.clientsCount, 1);
    expect(subordinate.commissionTotal.amount, 25);
    expect(subordinate.clientsCount, 1);
  });
}
