import 'package:ecommerce_b2b/app/core/network/api_client.dart';
import 'package:ecommerce_b2b/modules/logistics/shipment/model/repositories/tracking_repository.dart';
import 'package:ecommerce_b2b/modules/logistics/shipment/model/shipment.dart';

/// Sincronização de rastreamento via API (operação de expedição).
class ApiTrackingRepository implements TrackingRepository {
  final ApiClient _api;

  ApiTrackingRepository(this._api);

  @override
  Future<void> syncTracking(Shipment shipment) async {
    await _api.post('/api/shipments/${shipment.id.value}/tracking/sync');
  }
}
