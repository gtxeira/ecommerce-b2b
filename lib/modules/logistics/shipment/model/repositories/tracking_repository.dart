import 'package:ecommerce_b2b/modules/logistics/shipment/model/shipment.dart';

/// Contrato para rastreamento de transportadora (RF17), permitindo múltiplas implementações (ou fontes de dados).
abstract class TrackingRepository {
  /// Atualiza (ou sincroniza) o status de rastreamento de uma remessa.
  Future<void> syncTracking(Shipment shipment);
}
