// ignore_for_file: prefer_initializing_formals
import 'package:ecommerce_b2b/modules/shared_kernel/model/entity.dart';
import 'package:ecommerce_b2b/modules/shared_kernel/model/common/ids/quote_id.dart';
import 'package:ecommerce_b2b/modules/shared_kernel/model/finance/value_objects/money.dart';
import 'package:ecommerce_b2b/modules/order_flow/quote/model/enums/quote_status.dart';
import 'package:ecommerce_b2b/modules/order_flow/quote/model/quote_item.dart';

class Quote extends Entity<QuoteId> {
  final String? companyId;
  final String? representativeId;
  QuoteStatus _status;
  final List<QuoteItem> _items;
  final Money _shippingCost;

  Quote({
    required QuoteId id,
    this.companyId,
    this.representativeId,
    required QuoteStatus status,
    List<QuoteItem>? items,
    Money? shippingCost,
  }) : _status = status,
       _items = items ?? [],
       _shippingCost = shippingCost ?? Money.create(0).getOrThrow(),
       super(id);

  QuoteStatus get status => _status;
  List<QuoteItem> get items => List.unmodifiable(_items);
  Money get shippingCost => _shippingCost;

  Money get total {
    if (_items.isEmpty) {
      return _shippingCost;
    }

    Money sum = Money.create(
      0,
      currency: _items.first.unitPrice.currency,
    ).getOrThrow();
    for (var item in _items) {
      sum = sum + item.subtotal;
    }
    return sum + _shippingCost;
  }

  void addItem(QuoteItem item) {
    if (_status != QuoteStatus.draft) {
      throw StateError('Cannot add items to a non-draft quote');
    }
    _items.add(item);
  }

  void updateStatus(QuoteStatus newStatus) {
    _status = newStatus;
  }
}
