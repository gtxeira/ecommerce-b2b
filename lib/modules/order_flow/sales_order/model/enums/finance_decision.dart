/// Decisão financeira do departamento financeiro.
enum FinanceDecision {
  /// Aprovado
  approved,

  /// Rejeitado/Reprovado
  rejected,

  /// Solicitar mais informações
  requestMoreInfo;

  /// Converte o nome devolvido pela API (case-insensitive).
  static FinanceDecision fromApi(String value) => switch (value.toLowerCase()) {
    'approved' => FinanceDecision.approved,
    'rejected' => FinanceDecision.rejected,
    _ => FinanceDecision.requestMoreInfo,
  };

  /// Nome de exibição em português.
  String get label => switch (this) {
    FinanceDecision.approved => 'Aprovado',
    FinanceDecision.rejected => 'Reprovado',
    FinanceDecision.requestMoreInfo => 'Mais informações solicitadas',
  };
}
