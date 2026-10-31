// ignore_for_file: prefer_initializing_formals
import 'package:ecommerce_b2b/modules/order_flow/sales_order/application/get_pending_finance_reviews/get_pending_finance_reviews_use_case.dart';
import 'package:ecommerce_b2b/modules/order_flow/sales_order/application/process_finance_review/process_finance_review_use_case.dart';
import 'package:ecommerce_b2b/modules/order_flow/sales_order/model/enums/finance_decision.dart';
import 'package:ecommerce_b2b/modules/order_flow/sales_order/model/finance_review.dart';
import 'package:ecommerce_b2b/modules/order_flow/sales_order/model/sales_order.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';

part 'finance_review_state.dart';

class FinanceReviewCubit extends Cubit<FinanceReviewState> {
  final GetPendingFinanceReviewsUseCase _getPendingReviews;
  final ProcessFinanceReviewUseCase _processReview;

  FinanceReviewCubit({
    required GetPendingFinanceReviewsUseCase getPendingReviews,
    required ProcessFinanceReviewUseCase processReview,
  }) : _getPendingReviews = getPendingReviews,
       _processReview = processReview,
       super(FinanceReviewInitial());

  Future<void> loadPendingOrders() async {
    emit(FinanceReviewLoading());
    try {
      final orders = await _getPendingReviews.execute();
      emit(FinanceReviewLoaded(orders));
    } catch (e) {
      emit(FinanceReviewFailure(e.toString()));
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
