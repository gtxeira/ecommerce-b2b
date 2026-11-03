import 'package:ecommerce_b2b/app/core/events/order_events.dart';
import 'package:ecommerce_b2b/modules/identity_access/model/enums/user_role.dart';
import 'package:ecommerce_b2b/modules/identity_access/model/user_session.dart';
import 'package:ecommerce_b2b/modules/order_flow/model/enums/credit_status.dart';
import 'package:ecommerce_b2b/modules/order_flow/model/enums/order_status.dart';
import 'package:ecommerce_b2b/modules/order_flow/quote/model/enums/quote_status.dart';
import 'package:ecommerce_b2b/modules/order_flow/quote/model/quote.dart';
import 'package:ecommerce_b2b/modules/order_flow/quote/model/repositories/quote_repository.dart';
import 'package:ecommerce_b2b/modules/order_flow/quote/presentation/cubit/quote_cubit.dart';
import 'package:ecommerce_b2b/modules/order_flow/quote/presentation/cubit/quote_state.dart';
import 'package:ecommerce_b2b/modules/order_flow/sales_order/model/sales_order.dart';
import 'package:ecommerce_b2b/modules/shared_kernel/model/common/ids/order_id.dart';
import 'package:ecommerce_b2b/modules/shared_kernel/model/common/ids/quote_id.dart';
import 'package:ecommerce_b2b/modules/shared_kernel/model/common/ids/user_id.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockQuoteRepository extends Mock implements QuoteRepository {}

void main() {
  late _MockQuoteRepository repository;
  late OrderEvents events;
  late QuoteCubit cubit;
  late UserSession session;
  late Quote quote;
  late SalesOrder order;

  setUp(() {
    repository = _MockQuoteRepository();
    events = OrderEvents();
    cubit = QuoteCubit(repository, events);
    session = UserSession(
      userId: const UserId('rep-456'),
      role: UserRole.representative,
    );
    quote = Quote(
      id: const QuoteId('q1'),
      companyId: 'c1',
      representativeId: 'rep-456',
      status: QuoteStatus.sent,
    );
    order = SalesOrder(
      id: const OrderId('o1'),
      companyId: 'c1',
      status: OrderStatus.pickingPacking,
      creditStatus: CreditStatus.approved,
      items: const [],
    );
  });

  tearDown(() async {
    await cubit.close();
    await events.dispose();
  });

  test('loadQuotes do Admin busca todos os orçamentos', () async {
    final admin = UserSession(
      userId: const UserId('admin-1'),
      role: UserRole.admin,
    );
    when(() => repository.getAll()).thenAnswer((_) async => [quote]);

    await cubit.loadQuotes(admin);

    expect((cubit.state as QuoteLoaded).quotes, [quote]);
    verify(() => repository.getAll()).called(1);
    verifyNever(() => repository.findByRepresentativeId(any()));
  });

  test('loadQuotes do representante continua na própria carteira', () async {
    when(
      () => repository.findByRepresentativeId('rep-456'),
    ).thenAnswer((_) async => [quote]);

    await cubit.loadQuotes(session);

    expect((cubit.state as QuoteLoaded).quotes, [quote]);
    verify(() => repository.findByRepresentativeId('rep-456')).called(1);
    verifyNever(() => repository.getAll());
  });

  test('convertQuote recarrega a lista e notifica OrderEvents', () async {
    when(
      () => repository.findByRepresentativeId('rep-456'),
    ).thenAnswer((_) async => [quote]);
    when(
      () => repository.convert(const QuoteId('q1'), companyId: 'c1'),
    ).thenAnswer((_) async => order);

    var notifications = 0;
    final subscription = events.onChanged.listen((_) => notifications++);

    final converted = await cubit.convertQuote(quote, session);

    expect(converted, same(order));
    expect(cubit.state, isA<QuoteLoaded>());
    await Future<void>.delayed(Duration.zero);
    expect(notifications, 1);
    verify(
      () => repository.convert(const QuoteId('q1'), companyId: 'c1'),
    ).called(1);
    await subscription.cancel();
  });

  test('convertQuote emite erro quando a API recusa', () async {
    when(
      () => repository.convert(const QuoteId('q1'), companyId: 'c1'),
    ).thenThrow(Exception('orçamento expirado'));

    await expectLater(
      () => cubit.convertQuote(quote, session),
      throwsA(isA<Exception>()),
    );

    expect(cubit.state, isA<QuoteError>());
  });
}
