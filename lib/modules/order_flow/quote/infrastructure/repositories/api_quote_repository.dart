import 'package:ecommerce_b2b/app/core/network/api_client.dart';
import 'package:ecommerce_b2b/app/core/network/json_read.dart';
import 'package:ecommerce_b2b/modules/order_flow/quote/model/enums/quote_status.dart';
import 'package:ecommerce_b2b/modules/order_flow/quote/model/quote.dart';
import 'package:ecommerce_b2b/modules/order_flow/quote/model/quote_item.dart';
import 'package:ecommerce_b2b/modules/order_flow/quote/model/repositories/quote_repository.dart';
import 'package:ecommerce_b2b/modules/shared_kernel/model/common/ids/product_id.dart';
import 'package:ecommerce_b2b/modules/shared_kernel/model/common/ids/quote_id.dart';
import 'package:ecommerce_b2b/modules/shared_kernel/model/finance/value_objects/money.dart';
import 'package:ecommerce_b2b/modules/shared_kernel/model/finance/value_objects/quantity.dart';

class ApiQuoteRepository implements QuoteRepository {
  final ApiClient _api;

  ApiQuoteRepository(this._api);

  @override
  Future<void> save(Quote quote) async {
    await _api.post('/api/quotes', data: _toJson(quote));
  }

  @override
  Future<Quote?> getById(QuoteId id) async {
    final data = await _api.get('/api/quotes/${id.value}');
    if (data is! Map) return null;
    return fromJson(Map<String, dynamic>.from(data));
  }

  @override
  Future<List<Quote>> getAll() async {
    final data = await _api.get('/api/quotes');
    return _mapList(data);
  }

  @override
  Future<List<Quote>> findByRepresentativeId(String representativeId) async {
    final data = await _api.get(
      '/api/quotes',
      query: {'representativeId': representativeId},
    );
    return _mapList(data);
  }

  List<Quote> _mapList(dynamic data) {
    if (data is! List) return const [];
    return data
        .whereType<Map>()
        .map((item) => fromJson(Map<String, dynamic>.from(item)))
        .toList();
  }

  Map<String, dynamic> _toJson(Quote quote) => {
    'id': quote.id.value,
    'companyId': quote.companyId,
    'items': quote.items
        .map(
          (item) => {
            'productId': item.productId.value,
            'quantity': item.quantity.value,
            'priceTableId': item.priceTableId,
          },
        )
        .toList(),
  };

  static Quote fromJson(Map<String, dynamic> json) => Quote(
    id: QuoteId(readString(json, 'id')),
    companyId: readNullableString(json, 'companyId'),
    representativeId: readNullableString(json, 'representativeId'),
    status: _statusFromApi(readString(json, 'status')),
    createdAt: readDate(json, 'createdAt'),
    shippingCost: Money.create(readDouble(json, 'shippingCost')).getOrThrow(),
    items: readMapList(json, 'items')
        .map(
          (item) => QuoteItem(
            productId: ProductId(readString(item, 'productId')),
            quantity: Quantity.create(readInt(item, 'quantity')).getOrThrow(),
            unitPrice: Money.create(readDouble(item, 'unitPrice')).getOrThrow(),
          ),
        )
        .toList(),
  );

  static QuoteStatus _statusFromApi(String value) =>
      switch (value.toLowerCase()) {
        'draft' => QuoteStatus.draft,
        'sent' => QuoteStatus.sent,
        'expired' => QuoteStatus.expired,
        'converted' => QuoteStatus.convertedToOrder,
        'cancelled' => QuoteStatus.cancelled,
        _ => QuoteStatus.draft,
      };
}
