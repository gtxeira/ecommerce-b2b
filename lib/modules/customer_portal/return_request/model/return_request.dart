import 'package:ecommerce_b2b/modules/shared_kernel/model/entity.dart';
import 'package:ecommerce_b2b/modules/shared_kernel/model/common/ids/rma_id.dart';
import 'package:ecommerce_b2b/modules/customer_portal/return_request/model/enums/rma_status.dart';
import 'package:ecommerce_b2b/modules/customer_portal/return_request/model/return_request_item.dart';

class ReturnRequest extends Entity<RmaId> {
  final String orderId;
  RmaStatus _status;
  final String reason;
  final List<ReturnRequestItem> _items;

  ReturnRequest({
    required RmaId id,
    required this.orderId,
    required this._status,
    required this.reason,
    List<ReturnRequestItem>? items,
  }) : _items = items ?? [],
       super(id);

  RmaStatus get status => _status;
  List<ReturnRequestItem> get items => List.unmodifiable(_items);

  void updateStatus(RmaStatus newStatus) {
    _status = newStatus;
  }

  void addItem(ReturnRequestItem item) {
    _items.add(item);
  }
}
