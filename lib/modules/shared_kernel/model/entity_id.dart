/// Classe base para identificadores de entidades.
/// Garante tipagem forte para IDs em vez de usar apenas Strings.
abstract class EntityId {
  final String value;

  const EntityId(this.value);

  /// Identificador legível para exibição. Retorna o valor completo: truncar o
  /// ID (ex.: `substring(0, 8)`) faz IDs com o mesmo prefixo colidirem na UI
  /// (`order-101` e `order-102` viravam ambos `order-10`).
  String get displayCode => value;

  @override
  bool operator ==(Object other) => other is EntityId && other.value == value;

  @override
  int get hashCode => value.hashCode;

  @override
  String toString() => value;
}
