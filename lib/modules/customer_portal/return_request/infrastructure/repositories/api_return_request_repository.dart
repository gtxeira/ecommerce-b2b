import 'package:ecommerce_b2b/app/core/network/api_client.dart';
import 'package:ecommerce_b2b/app/core/network/json_read.dart';
import 'package:ecommerce_b2b/modules/customer_portal/return_request/model/enums/rma_status.dart';
import 'package:ecommerce_b2b/modules/customer_portal/return_request/model/repositories/return_request_repository.dart';
import 'package:ecommerce_b2b/modules/customer_portal/return_request/model/return_request.dart';
import 'package:ecommerce_b2b/modules/customer_portal/return_request/model/return_request_item.dart';
import 'package:ecommerce_b2b/modules/shared_kernel/model/common/ids/company_id.dart';
import 'package:ecommerce_b2b/modules/shared_kernel/model/common/ids/product_id.dart';
import 'package:ecommerce_b2b/modules/shared_kernel/model/common/ids/rma_id.dart';
import 'package:ecommerce_b2b/modules/shared_kernel/model/finance/value_objects/quantity.dart';

class ApiReturnRequestRepository implements ReturnRequestRepository {
  final ApiClient _api;

  ApiReturnRequestRepository(this._api);

  @override
  Future<void> save(ReturnRequest request) async {
    await _api.post('/api/me/return-requests', data: _toJson(request));
  }

  @override
  Future<ReturnRequest?> getById(RmaId id) async {
    final all = await getAll();
    for (final rma in all) {
      if (rma.id == id) return rma;
    }
    return null;
  }

  @override
  Future<List<ReturnRequest>> getAll() async {
    final data = await _api.get('/api/me/return-requests');
    return _mapList(data);
  }

  @override
  Future<List<ReturnRequest>> findByCompanyId(CompanyId companyId) async {
    final data = await _api.get(
      '/api/me/return-requests',
      query: {'companyId': companyId.value},
    );
    return _mapList(data);
  }

  List<ReturnRequest> _mapList(dynamic data) {
    if (data is! List) return const [];
    return data
        .whereType<Map>()
        .map((item) => fromJson(Map<String, dynamic>.from(item)))
        .toList();
  }

  Map<String, dynamic> _toJson(ReturnRequest request) => {
    'orderId': request.orderId,
    'reason': request.reason,
    'items': request.items
        .map(
          (item) => {
            'productId': item.productId.value,
            'quantity': item.quantity.value,
            'problemDescription': item.problemDescription,
          },
        )
        .toList(),
  };

  static ReturnRequest fromJson(Map<String, dynamic> json) => ReturnRequest(
    id: RmaId(readString(json, 'id')),
    orderId: readString(json, 'orderId'),
    status: _statusFromApi(readString(json, 'status')),
    reason: readString(json, 'reason'),
    items: readMapList(json, 'items')
        .map(
          (item) => ReturnRequestItem(
            productId: ProductId(readString(item, 'productId')),
            quantity: Quantity.create(readInt(item, 'quantity')).getOrThrow(),
            problemDescription: readString(item, 'problemDescription'),
          ),
        )
        .toList(),
  );

  static RmaStatus _statusFromApi(String value) =>
      switch (value.toLowerCase()) {
        'approved' => RmaStatus.authorized,
        'rejected' => RmaStatus.rejected,
        'refunded' => RmaStatus.completed,
        _ => RmaStatus.pending,
      };
}
