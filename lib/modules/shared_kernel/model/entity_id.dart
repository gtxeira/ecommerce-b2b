/// Classe base para identificadores de entidades.
/// Garante tipagem forte para IDs em vez de usar apenas Strings.
abstract class EntityId {
  final String value;

  const EntityId(this.value);

  @override
  bool operator ==(Object other) => other is EntityId && other.value == value;

  @override
  int get hashCode => value.hashCode;

  @override
  String toString() => value;
}
