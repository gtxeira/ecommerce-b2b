import 'package:ecommerce_b2b/modules/customer_portal/boleto/model/value_objects/boleto_copy.dart';
import 'package:ecommerce_b2b/modules/shared_kernel/model/common/ids/order_id.dart';

/// Interface de repositório para serviços relacionados a boletos.
abstract class BoletoRepository {
  /// Gera ou recupera a segunda via de um boleto para um pedido específico (RF19).
  Future<BoletoCopy> getBoletoByOrder(OrderId orderId);
}
