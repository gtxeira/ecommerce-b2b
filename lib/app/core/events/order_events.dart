import 'dart:async';

/// Canal único para avisar o app de que pedidos foram alterados.
///
/// Existe pelo mesmo motivo do `SessionEvents`: o dado que muda numa tela (ex.:
/// aprovação no painel financeiro) precisa refletir em outra (o badge de
/// pedidos em aberto na navegação) sem acoplar as duas.
///
/// O evento **não carrega payload**: quem escuta relê a fonte
/// (`SalesOrderRepository.getAll()`), então nunca há duas verdades. Emitir só
/// depois da mutação confirmada na API; falha na releitura do consumidor não
/// deve propagar.
class OrderEvents {
  final StreamController<void> _changed = StreamController<void>.broadcast();

  /// Disparado após uma mutação de pedido confirmada (aprovar, reprovar,
  /// faturar).
  Stream<void> get onChanged => _changed.stream;

  void notifyChanged() {
    if (!_changed.isClosed) {
      _changed.add(null);
    }
  }

  Future<void> dispose() => _changed.close();
}
