import 'package:ecommerce_b2b/app/core/network/api_client.dart';
import 'package:ecommerce_b2b/app/core/network/json_read.dart';
import 'package:ecommerce_b2b/modules/customer_portal/boleto/model/repositories/boleto_repository.dart';
import 'package:ecommerce_b2b/modules/customer_portal/boleto/model/value_objects/boleto_copy.dart';
import 'package:ecommerce_b2b/modules/shared_kernel/model/common/ids/order_id.dart';

class ApiBoletoRepository implements BoletoRepository {
  final ApiClient _api;

  ApiBoletoRepository(this._api);

  @override
  Future<BoletoCopy> getBoletoByOrder(OrderId orderId) async {
    final data = await _api.get('/api/me/boletos/${orderId.value}');
    if (data is! Map) {
      throw StateError('Resposta inesperada ao consultar o boleto.');
    }
    final json = Map<String, dynamic>.from(data);
    return BoletoCopy(
      barcode: readString(json, 'barcode'),
      url: readString(json, 'url'),
    );
  }
}
