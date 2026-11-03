/// Rotas internas de comissões do representante.
class CommissionRoutes {
  const CommissionRoutes._();

  static const String list = '/commissions';

  /// Abre a lista já no escopo consolidado da equipe.
  static const String team = '$list?scope=team';

  /// Abre a lista com a carteira de um representante específico.
  static String forRepresentative(String representativeId) =>
      '$list?representativeId=${Uri.encodeQueryComponent(representativeId)}';

  static String withScope({
    required bool isTeamView,
    required String representativeId,
  }) => isTeamView ? team : forRepresentative(representativeId);
}
