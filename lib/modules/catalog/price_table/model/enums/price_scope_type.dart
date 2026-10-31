/// Tipo de escopo de preço (RF5).
enum PriceScopeType {
  national,
  regional,
  customerSpecific;

  /// Nome de exibição em português.
  String get label => switch (this) {
    PriceScopeType.national => 'Nacional',
    PriceScopeType.regional => 'Regional',
    PriceScopeType.customerSpecific => 'Específico por Cliente',
  };
}
