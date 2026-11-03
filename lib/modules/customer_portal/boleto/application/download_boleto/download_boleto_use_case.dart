import 'package:ecommerce_b2b/modules/customer_portal/boleto/model/repositories/boleto_repository.dart';
import 'package:ecommerce_b2b/modules/customer_portal/boleto/model/value_objects/boleto_copy.dart';
import 'package:ecommerce_b2b/modules/shared_kernel/model/common/ids/order_id.dart';

/// Caso de Uso responsável por disponibilizar a segunda via do boleto (RF19).
class DownloadBoletoUseCase {
  final BoletoRepository _boletoRepository;

  DownloadBoletoUseCase(this._boletoRepository);

  /// Recupera os dados da segunda via do boleto.
  Future<BoletoCopy> execute(OrderId orderId) async {
    return await _boletoRepository.getBoletoByOrder(orderId);
  }
}
