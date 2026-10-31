import 'package:ecommerce_b2b/modules/shared_kernel/model/entity.dart';
import 'package:ecommerce_b2b/modules/shared_kernel/model/common/ids/shipment_id.dart';
import 'package:ecommerce_b2b/modules/shared_kernel/model/logistics/value_objects/tracking_code.dart';
import 'package:ecommerce_b2b/modules/logistics/shipment/model/enums/shipment_status.dart';
import 'package:ecommerce_b2b/modules/logistics/shipment/model/shipping_label.dart';
import 'package:ecommerce_b2b/modules/logistics/shipment/model/tracking_event.dart';

/// Raiz do Agregado que representa uma Remessa/Envio.
class Shipment extends Entity<ShipmentId> {
  final String orderId;

  /// Código de rastreamento da transportadora.
  final TrackingCode trackingCode;
  ShipmentStatus _status;

  /// Etiqueta de envio associada.
  final ShippingLabel shippingLabel;
  final List<TrackingEvent> _trackingEvents;

  /// Construtor da Remessa.
  Shipment({
    required ShipmentId id,
    required this.orderId,
    required this.trackingCode,
    required this._status,
    required this.shippingLabel,
    List<TrackingEvent>? trackingEvents,
  }) : _trackingEvents = trackingEvents ?? [],
       super(id);

  /// Status atual do envio.
  ShipmentStatus get status => _status;

  /// Histórico de eventos de rastreamento.
  List<TrackingEvent> get trackingEvents => List.unmodifiable(_trackingEvents);

  /// Adiciona um novo evento de rastreamento ao histórico.
  void addTrackingEvent(TrackingEvent event) {
    _trackingEvents.add(event);
  }

  /// Atualiza o status geral do envio.
  void updateStatus(ShipmentStatus newStatus) {
    _status = newStatus;
  }
}
