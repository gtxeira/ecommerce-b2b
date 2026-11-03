import 'package:ecommerce_b2b/modules/customer_portal/return_request/model/enums/rma_status.dart';
import 'package:ecommerce_b2b/modules/customer_portal/return_request/model/repositories/return_request_repository.dart';
import 'package:ecommerce_b2b/modules/customer_portal/return_request/model/return_request.dart';
import 'package:ecommerce_b2b/modules/customer_portal/return_request/model/return_request_item.dart';
import 'package:ecommerce_b2b/modules/order_flow/sales_order/model/sales_order.dart';
import 'package:ecommerce_b2b/modules/shared_kernel/model/common/ids/rma_id.dart';

/// Abertura de RMA (RF20). A API valida o status do pedido (Delivered/Invoiced)
/// e transiciona o pedido; o cliente apenas envia o comando.
class OpenReturnRequestUseCase {
  final ReturnRequestRepository _returnRequestRepository;

  OpenReturnRequestUseCase(this._returnRequestRepository);

  Future<ReturnRequest> execute({
    required RmaId rmaId,
    required SalesOrder order,
    required String reason,
    required List<ReturnRequestItem> items,
  }) async {
    final rma = ReturnRequest(
      id: rmaId,
      orderId: order.id.value,
      status: RmaStatus.pending,
      reason: reason,
      items: items,
    );

    await _returnRequestRepository.save(rma);
    return rma;
  }
}
