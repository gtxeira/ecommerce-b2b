import 'dart:async';

/// Canal único para avisar o app de que a sessão deixou de ser válida.
///
/// O [ApiClient] emite quando o refresh falha; o [AuthCubit] escuta e derruba o
/// usuário para a tela de login, mesmo que o 401 tenha acontecido numa tela
/// distante da autenticação.
class SessionEvents {
  final StreamController<void> _expired = StreamController<void>.broadcast();

  Stream<void> get onExpired => _expired.stream;

  void notifyExpired() {
    if (!_expired.isClosed) {
      _expired.add(null);
    }
  }

  Future<void> dispose() => _expired.close();
}
