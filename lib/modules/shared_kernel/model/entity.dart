import 'package:ecommerce_b2b/modules/shared_kernel/model/entity_id.dart';

/// Classe base para todas as Entidades do sistema.
/// Uma entidade é definida por sua identidade contínua através do tempo.
abstract class Entity<ID extends EntityId> {
  /// O identificador único da entidade.
  final ID id;

  const Entity(this.id);

  @override
  bool operator ==(Object other) => other is Entity<ID> && other.id == id;

  @override
  int get hashCode => id.hashCode;
}
