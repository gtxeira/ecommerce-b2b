/// Decisão financeira do departamento financeiro.
enum FinanceDecision {
  /// Aprovado
  approved,

  /// Rejeitado/Reprovado
  rejected,

  /// Solicitar mais informações
  requestMoreInfo;

  /// Nome de exibição em português.
  String get label => switch (this) {
    FinanceDecision.approved => 'Aprovado',
    FinanceDecision.rejected => 'Reprovado',
    FinanceDecision.requestMoreInfo => 'Mais informações solicitadas',
  };
}
