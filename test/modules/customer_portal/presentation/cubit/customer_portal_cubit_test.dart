import 'package:ecommerce_b2b/modules/customer_portal/boleto/application/download_boleto/download_boleto_use_case.dart';
import 'package:ecommerce_b2b/modules/customer_portal/boleto/domain/value_objects/boleto_copy.dart';
import 'package:ecommerce_b2b/modules/customer_portal/presentation/cubit/customer_portal_cubit.dart';
import 'package:ecommerce_b2b/modules/customer_portal/purchase_history/application/get_purchase_history/get_purchase_history_use_case.dart';
import 'package:ecommerce_b2b/modules/customer_portal/return_request/application/get_return_requests/get_return_requests_use_case.dart';
import 'package:ecommerce_b2b/modules/customer_portal/return_request/application/open_return_request/open_return_request_use_case.dart';
import 'package:ecommerce_b2b/modules/customer_portal/return_request/domain/return_request.dart';
import 'package:ecommerce_b2b/modules/customer_portal/return_request/domain/return_request_item.dart';
import 'package:ecommerce_b2b/modules/customer_portal/return_request/domain/enums/rma_status.dart';
import 'package:ecommerce_b2b/modules/identity_access/domain/user_session.dart';
import 'package:ecommerce_b2b/modules/identity_access/domain/enums/user_role.dart';
import 'package:ecommerce_b2b/modules/order_flow/domain/enums/order_status.dart';
import 'package:ecommerce_b2b/modules/order_flow/domain/enums/credit_status.dart';
import 'package:ecommerce_b2b/modules/order_flow/sales_order/domain/sales_order.dart';
import 'package:ecommerce_b2b/modules/shared_kernel/domain/common/ids/company_id.dart';
import 'package:ecommerce_b2b/modules/shared_kernel/domain/common/ids/order_id.dart';
import 'package:ecommerce_b2b/modules/shared_kernel/domain/common/ids/rma_id.dart';
import 'package:ecommerce_b2b/modules/shared_kernel/domain/common/ids/user_id.dart';
import 'package:ecommerce_b2b/modules/shared_kernel/functional/result.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockGetPurchaseHistoryUseCase extends Mock implements GetPurchaseHistoryUseCase {}
class MockGetReturnRequestsUseCase extends Mock implements GetReturnRequestsUseCase {}
class MockDownloadBoletoUseCase extends Mock implements DownloadBoletoUseCase {}
class MockOpenReturnRequestUseCase extends Mock implements OpenReturnRequestUseCase {}

class SalesOrderFake extends Fake implements SalesOrder {}
class RmaIdFake extends Fake implements RmaId {}
class ReturnRequestItemFake extends Fake implements ReturnRequestItem {}

void main() {
  setUpAll(() {
    registerFallbackValue(SalesOrderFake());
    registerFallbackValue(RmaIdFake());
    registerFallbackValue(ReturnRequestItemFake());
  });

  group('CustomerPortalCubit', () {
    late MockGetPurchaseHistoryUseCase getPurchaseHistory;
    late MockGetReturnRequestsUseCase getReturnRequests;
    late MockDownloadBoletoUseCase downloadBoleto;
    late MockOpenReturnRequestUseCase openReturnRequest;
    late CustomerPortalCubit cubit;

    final companyId = const CompanyId('c1');
    final session = UserSession(
      userId: const UserId('b1'),
      role: UserRole.buyer,
      companyId: const CompanyId('c1'),
    );

    setUp(() {
      getPurchaseHistory = MockGetPurchaseHistoryUseCase();
      getReturnRequests = MockGetReturnRequestsUseCase();
      downloadBoleto = MockDownloadBoletoUseCase();
      openReturnRequest = MockOpenReturnRequestUseCase();

      cubit = CustomerPortalCubit(
        getPurchaseHistoryUseCase: getPurchaseHistory,
        getReturnRequestsUseCase: getReturnRequests,
        downloadBoletoUseCase: downloadBoleto,
        openReturnRequestUseCase: openReturnRequest,
      );
    });

    tearDown(() {
      cubit.close();
    });

    test('initial state should be CustomerPortalInitial', () {
      expect(cubit.state, isA<CustomerPortalInitial>());
    });

    test('loadPortalData should emit Loading and then Loaded on success', () async {
      final order = SalesOrder(
        id: const OrderId('o1'),
        companyId: 'c1',
        status: OrderStatus.delivered,
        creditStatus: CreditStatus.approved,
        items: [],
      );

      final rma = ReturnRequest(
        id: const RmaId('r1'),
        orderId: 'o1',
        status: RmaStatus.pending,
        reason: 'Defeito',
      );

      when(() => getPurchaseHistory.execute(companyId, session)).thenAnswer((_) async => Success([order]));
      when(() => getReturnRequests.execute(companyId, session)).thenAnswer((_) async => Success([rma]));

      final states = <CustomerPortalState>[];
      cubit.stream.listen(states.add);

      await cubit.loadPortalData(companyId: companyId, session: session);
      await Future.delayed(Duration.zero);

      expect(states, [
        isA<CustomerPortalLoading>(),
        isA<CustomerPortalLoaded>(),
      ]);

      final loaded = states[1] as CustomerPortalLoaded;
      expect(loaded.orders, [order]);
      expect(loaded.returnRequests, [rma]);
    });

    test('downloadBoleto should get boleto copy and update state', () async {
      final order = SalesOrder(
        id: const OrderId('o1'),
        companyId: 'c1',
        status: OrderStatus.delivered,
        creditStatus: CreditStatus.approved,
        items: [],
      );

      final boleto = BoletoCopy(barcode: '123', url: 'http://pdf');

      cubit.emit(CustomerPortalLoaded(orders: [order], returnRequests: []));

      when(() => downloadBoleto.execute(const OrderId('o1'))).thenAnswer((_) async => boleto);

      final states = <CustomerPortalState>[];
      cubit.stream.listen(states.add);

      await cubit.downloadBoleto(const OrderId('o1'));
      await Future.delayed(Duration.zero);

      expect(states.last, isA<CustomerPortalLoaded>());
      final loaded = states.last as CustomerPortalLoaded;
      expect(loaded.activeBoleto, boleto);
    });

    test('openRma should open return request, reload data and set success message', () async {
      final order = SalesOrder(
        id: const OrderId('o1'),
        companyId: 'c1',
        status: OrderStatus.delivered,
        creditStatus: CreditStatus.approved,
        items: [],
      );

      final mockRma = ReturnRequest(
        id: const RmaId('r1'),
        orderId: 'o1',
        status: RmaStatus.pending,
        reason: 'Broken',
      );

      cubit.emit(CustomerPortalLoaded(orders: [order], returnRequests: []));

      when(() => openReturnRequest.execute(
            rmaId: any(named: 'rmaId'),
            order: any(named: 'order'),
            reason: any(named: 'reason'),
            items: any(named: 'items'),
          )).thenAnswer((_) async => mockRma);

      when(() => getPurchaseHistory.execute(companyId, session)).thenAnswer((_) async => Success([order]));
      when(() => getReturnRequests.execute(companyId, session)).thenAnswer((_) async => Success([]));

      final states = <CustomerPortalState>[];
      cubit.stream.listen(states.add);

      await cubit.openRma(order: order, reason: 'Broken', companyId: companyId, session: session);
      await Future.delayed(Duration.zero);

      expect(states.last, isA<CustomerPortalLoaded>());
      final loaded = states.last as CustomerPortalLoaded;
      expect(loaded.successMessage, 'Solicitação de devolução (RMA) aberta com sucesso!');
    });
  });
}
