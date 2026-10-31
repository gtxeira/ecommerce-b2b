/// Enum que representa as moedas disponíveis no sistema.
enum Currency {
  brazil(code: 'BRL', symbol: 'R\$', country: 'Brasil'),
  unitedStates(code: 'USD', symbol: '\$', country: 'Estados Unidos');

  /// Código da moeda (ex: BRL, USD).
  final String code;
  /// Símbolo da moeda (ex: R$, $).
  final String symbol;
  /// País da moeda (ex: Brasil, Estados Unidos).
  final String country;

  const Currency({
    required this.code,
    required this.symbol,
    required this.country,
  });
}