import 'package:ecommerce_b2b/modules/customer_portal/boleto/application/download_boleto/download_boleto_use_case.dart';
import 'package:ecommerce_b2b/modules/customer_portal/boleto/model/value_objects/boleto_copy.dart';
import 'package:ecommerce_b2b/modules/customer_portal/purchase_history/application/get_purchase_history/get_purchase_history_use_case.dart';
import 'package:ecommerce_b2b/modules/customer_portal/return_request/application/get_return_requests/get_return_requests_use_case.dart';
import 'package:ecommerce_b2b/modules/customer_portal/return_request/application/open_return_request/open_return_request_use_case.dart';
import 'package:ecommerce_b2b/modules/customer_portal/return_request/model/return_request.dart';
import 'package:ecommerce_b2b/modules/customer_portal/return_request/model/return_request_item.dart';
import 'package:ecommerce_b2b/modules/identity_access/model/user_session.dart';
import 'package:ecommerce_b2b/modules/order_flow/sales_order/model/sales_order.dart';
import 'package:ecommerce_b2b/modules/shared_kernel/model/common/ids/company_id.dart';
import 'package:ecommerce_b2b/modules/shared_kernel/model/common/ids/order_id.dart';
import 'package:ecommerce_b2b/modules/shared_kernel/model/common/ids/rma_id.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';

part 'customer_portal_state.dart';

class CustomerPortalCubit extends Cubit<CustomerPortalState> {
  final GetPurchaseHistoryUseCase _getPurchaseHistory;
  final GetReturnRequestsUseCase _getReturnRequests;
  final DownloadBoletoUseCase _downloadBoleto;
  final OpenReturnRequestUseCase _openReturnRequest;

  CustomerPortalCubit({
    required GetPurchaseHistoryUseCase getPurchaseHistoryUseCase,
    required GetReturnRequestsUseCase getReturnRequestsUseCase,
    required DownloadBoletoUseCase downloadBoletoUseCase,
    required OpenReturnRequestUseCase openReturnRequestUseCase,
  }) : _getPurchaseHistory = getPurchaseHistoryUseCase,
       _getReturnRequests = getReturnRequestsUseCase,
       _downloadBoleto = downloadBoletoUseCase,
       _openReturnRequest = openReturnRequestUseCase,
       super(CustomerPortalInitial());

  /// Carrega todo o histórico de compras e as solicitações de RMA em paralelo.
  Future<void> loadPortalData({
    required CompanyId companyId,
    required UserSession session,
  }) async {
    emit(CustomerPortalLoading());
    try {
      final historyResult = await _getPurchaseHistory.execute(
        companyId,
        session,
      );
      final rmaResult = await _getReturnRequests.execute(companyId, session);

      if (historyResult.isSuccess && rmaResult.isSuccess) {
        final orders = historyResult.getOrThrow();

        // O rastreamento é sincronizado pela operação (API); o portal apenas lê
        // o estado atual do pedido.
        emit(
          CustomerPortalLoaded(
            orders: orders,
            returnRequests: rmaResult.getOrThrow(),
          ),
        );
      } else {
        final error = historyResult.isFailure
            ? historyResult.getFailureOrThrow()
            : rmaResult.getFailureOrThrow();
        emit(CustomerPortalFailure(error.message));
      }
    } catch (e) {
      emit(CustomerPortalFailure(e.toString()));
    }
  }

  /// Solicita a segunda via de boleto para o pedido.
  Future<void> downloadBoleto(OrderId orderId) async {
    final currentState = state;
    if (currentState is! CustomerPortalLoaded) return;

    try {
      final boleto = await _downloadBoleto.execute(orderId);
      emit(currentState.copyWith(activeBoleto: boleto));
    } catch (e) {
      emit(CustomerPortalFailure('Erro ao obter segunda via do boleto: $e'));
    }
  }

  /// Limpa o boleto ativo do estado.
  void clearActiveBoleto() {
    final currentState = state;
    if (currentState is CustomerPortalLoaded) {
      emit(currentState.copyWith(clearActiveBoleto: true));
    }
  }

  /// Limpa a mensagem de sucesso do estado.
  void clearSuccessMessage() {
    final currentState = state;
    if (currentState is CustomerPortalLoaded) {
      emit(currentState.copyWith(clearSuccessMessage: true));
    }
  }

  /// Abre um chamado de devolução/RMA para um pedido entregue.
  Future<void> openRma({
    required SalesOrder order,
    required String reason,
    required CompanyId companyId,
    required UserSession session,
  }) async {
    final currentState = state;
    if (currentState is! CustomerPortalLoaded) return;

    try {
      final rmaId = RmaId(const Uuid().v7());

      // Mapeia os itens do pedido completo para a devolução
      final List<ReturnRequestItem> rmaItems = order.items
          .map(
            (item) => ReturnRequestItem(
              productId: item.productId,
              quantity: item.quantity,
              problemDescription: reason,
            ),
          )
          .toList();

      await _openReturnRequest.execute(
        rmaId: rmaId,
        order: order,
        reason: reason,
        items: rmaItems,
      );

      // Recarrega todos os dados do portal
      final historyResult = await _getPurchaseHistory.execute(
        companyId,
        session,
      );
      final rmaResult = await _getReturnRequests.execute(companyId, session);

      if (historyResult.isSuccess && rmaResult.isSuccess) {
        emit(
          CustomerPortalLoaded(
            orders: historyResult.getOrThrow(),
            returnRequests: rmaResult.getOrThrow(),
            successMessage:
                'Solicitação de devolução (RMA) aberta com sucesso!',
          ),
        );
      } else {
        final error = historyResult.isFailure
            ? historyResult.getFailureOrThrow()
            : rmaResult.getFailureOrThrow();
        emit(CustomerPortalFailure(error.message));
      }
    } catch (e) {
      emit(CustomerPortalFailure('Erro ao abrir RMA: $e'));
    }
  }
}
