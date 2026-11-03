import 'package:ecommerce_b2b/modules/order_flow/sales_order/model/finance_summary.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('FinanceSummary', () {
    Map<String, dynamic> json() => {
      'companyCount': 2,
      'totalCreditLimit': 15000.0,
      'totalOpenBalance': 1500.0,
      'totalPendingOrdersBalance': 5000.0,
      'totalExposure': 6500.0,
      'availableLimit': 8500.0,
      'utilizationPercentage': 43.33,
      'companiesAtRisk': 1,
      'companiesOverLimit': 0,
    };

    test('should map the API payload', () {
      final summary = FinanceSummary.fromJson(json());

      expect(summary.companyCount, 2);
      expect(summary.totalCreditLimit.amount, 15000);
      expect(summary.totalOpenBalance.amount, 1500);
      expect(summary.totalPendingOrdersBalance.amount, 5000);
      expect(summary.totalExposure.amount, 6500);
      expect(summary.availableLimit.amount, 8500);
      expect(summary.utilizationPercentage, 43.33);
      expect(summary.companiesAtRisk, 1);
      expect(summary.companiesOverLimit, 0);
      expect(summary.hasCompanies, isTrue);
    });

    test('should format utilization with a Brazilian decimal separator', () {
      final summary = FinanceSummary.fromJson(json());

      expect(summary.utilizationLabel, '43,3%');
    });

    test('should report an empty portfolio', () {
      final summary = FinanceSummary.fromJson({
        'companyCount': 0,
        'totalCreditLimit': 0,
        'totalOpenBalance': 0,
        'totalPendingOrdersBalance': 0,
        'totalExposure': 0,
        'availableLimit': 0,
        'utilizationPercentage': 0,
        'companiesAtRisk': 0,
        'companiesOverLimit': 0,
      });

      expect(summary.hasCompanies, isFalse);
      expect(summary.utilizationLabel, '0,0%');
    });
  });
}
