// ignore_for_file: prefer_initializing_formals
import 'package:ecommerce_b2b/modules/order_flow/model/enums/credit_status.dart';
import 'package:ecommerce_b2b/modules/order_flow/sales_order/application/get_pending_finance_reviews/get_pending_finance_reviews_use_case.dart';
import 'package:ecommerce_b2b/modules/order_flow/sales_order/application/process_finance_review/process_finance_review_use_case.dart';
import 'package:ecommerce_b2b/modules/order_flow/sales_order/model/enums/finance_decision.dart';
import 'package:ecommerce_b2b/modules/order_flow/sales_order/model/finance_review.dart';
import 'package:ecommerce_b2b/modules/order_flow/sales_order/model/repositories/sales_order_repository.dart';
import 'package:ecommerce_b2b/modules/order_flow/sales_order/model/sales_order.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';

part 'finance_review_state.dart';

class FinanceReviewCubit extends Cubit<FinanceReviewState> {
  final GetPendingFinanceReviewsUseCase _getPendingReviews;
  final ProcessFinanceReviewUseCase _processReview;
  final SalesOrderRepository _orderRepository;

  FinanceReviewCubit({
    required GetPendingFinanceReviewsUseCase getPendingReviews,
    required ProcessFinanceReviewUseCase processReview,
    required SalesOrderRepository orderRepository,
  }) : _getPendingReviews = getPendingReviews,
       _processReview = processReview,
       _orderRepository = orderRepository,
       super(FinanceReviewInitial());

  Future<void> loadPendingOrders() async {
    emit(FinanceReviewLoading());
    try {
      final orders = await _getPendingReviews.execute();
      emit(
        FinanceReviewLoaded(
          orders,
          recentReleases: await _loadRecentReleases(),
        ),
      );
    } catch (e) {
      emit(FinanceReviewFailure(e.toString()));
    }
  }

  /// Pedidos com crédito já aprovado, usados no histórico do painel financeiro.
  Future<List<SalesOrder>> _loadRecentReleases() async {
    try {
      final orders = await _orderRepository.getAll();
      return orders
          .where((order) => order.creditStatus == CreditStatus.approved)
          .take(3)
          .toList();
    } catch (_) {
      // O histórico é secundário: uma falha aqui não deve derrubar a fila de análise.
      return const [];
    }
  }

  Future<void> approveOrder(SalesOrder order, String reason) =>
      _review(order, FinanceDecision.approved, reason);

  Future<void> rejectOrder(SalesOrder order, String reason) =>
      _review(order, FinanceDecision.rejected, reason);

  Future<void> requestMoreInfo(SalesOrder order, String reason) =>
      _review(order, FinanceDecision.requestMoreInfo, reason);

  Future<void> invoiceOrder(SalesOrder order) async {
    try {
      await _processReview.invoice(order);
      await loadPendingOrders();
    } catch (e) {
      emit(FinanceReviewFailure(e.toString()));
    }
  }

  Future<void> _review(
    SalesOrder order,
    FinanceDecision decision,
    String reason,
  ) async {
    try {
      final review = FinanceReview(
        decision: decision,
        reviewerId: '',
        reviewedAt: DateTime.now(),
        justification: reason,
      );

      await _processReview.execute(order: order, review: review);
      await loadPendingOrders();
    } catch (e) {
      emit(FinanceReviewFailure(e.toString()));
    }
  }
}
