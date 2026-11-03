import 'package:ecommerce_b2b/modules/order_flow/sales_order/model/finance_summary.dart';
import 'package:ecommerce_b2b/modules/order_flow/sales_order/presentation/finance_review/finance_summary_copy.dart';
import 'package:ecommerce_b2b/modules/shared_kernel/model/finance/value_objects/money.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  FinanceSummary summary({
    int companyCount = 2,
    double totalCreditLimit = 600000,
    int companiesAtRisk = 0,
    int companiesOverLimit = 0,
  }) => FinanceSummary(
    companyCount: companyCount,
    totalCreditLimit: Money.create(totalCreditLimit).getOrThrow(),
    totalOpenBalance: Money.create(0).getOrThrow(),
    totalPendingOrdersBalance: Money.create(0).getOrThrow(),
    totalExposure: Money.create(0).getOrThrow(),
    availableLimit: Money.create(totalCreditLimit).getOrThrow(),
    utilizationPercentage: 0,
    companiesAtRisk: companiesAtRisk,
    companiesOverLimit: companiesOverLimit,
  );

  group('finance summary copy', () {
    test('should name the portfolio limit as granted to clients', () {
      expect(financeExposureLabel, 'Crédito em Uso pelos Clientes');
      expect(
        financeExposureCaption(summary()),
        'de R\$ 600.000,00 concedidos aos clientes',
      );
    });

    test('should use client wording for an empty portfolio', () {
      final empty = summary(companyCount: 0, totalCreditLimit: 0);

      expect(financeExposureCaption(empty), 'Nenhum cliente na carteira');
      expect(financeRiskCaption(empty), 'Sem limite concedido aos clientes');
    });

    test('should describe the commitment label and no-risk state', () {
      expect(financeCommitmentLabel, 'Limite da Carteira Comprometido');
      expect(financeRiskCaption(summary()), 'Nenhum cliente em atenção');
    });

    test('should use singular and plural for clients at risk', () {
      expect(
        financeRiskCaption(summary(companiesAtRisk: 1)),
        '1 cliente em atenção',
      );
      expect(
        financeRiskCaption(summary(companiesAtRisk: 3)),
        '3 clientes em atenção',
      );
    });

    test('should prioritize clients over the limit', () {
      expect(
        financeRiskCaption(summary(companiesAtRisk: 2, companiesOverLimit: 1)),
        '1 cliente acima do limite',
      );
      expect(
        financeRiskCaption(summary(companiesAtRisk: 4, companiesOverLimit: 2)),
        '2 clientes acima do limite',
      );
    });
  });
}
