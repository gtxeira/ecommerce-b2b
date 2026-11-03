import 'package:ecommerce_b2b/modules/order_flow/sales_order/model/finance_summary.dart';

/// Textos dos indicadores do painel financeiro.
///
/// O painel é de risco de crédito da carteira de clientes: o limite exibido é
/// o total concedido às empresas-clientes, não o financeiro da empresa vendedora.
const financeExposureLabel = 'Crédito em Uso pelos Clientes';
const financeCommitmentLabel = 'Limite da Carteira Comprometido';

String financeExposureCaption(FinanceSummary summary) => summary.hasCompanies
    ? 'de ${summary.totalCreditLimit.formatted} concedidos aos clientes'
    : 'Nenhum cliente na carteira';

String financeRiskCaption(FinanceSummary summary) {
  if (!summary.hasCompanies) return 'Sem limite concedido aos clientes';

  if (summary.companiesOverLimit > 0) {
    return summary.companiesOverLimit == 1
        ? '1 cliente acima do limite'
        : '${summary.companiesOverLimit} clientes acima do limite';
  }

  if (summary.companiesAtRisk == 0) {
    return 'Nenhum cliente em atenção';
  }

  return summary.companiesAtRisk == 1
      ? '1 cliente em atenção'
      : '${summary.companiesAtRisk} clientes em atenção';
}
