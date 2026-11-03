import 'package:ecommerce_b2b/app/presentation/widgets/discount_badge.dart';
import 'package:ecommerce_b2b/modules/catalog/price_table/model/pricing_explanation.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final json = {
    'referenceUnitPrice': 5500.0,
    'discountPerUnit': 500.0,
    'discountTotal': 5000.0,
    'discountPercentage': 9.09,
    'priceTableId': 'pt-1',
    'priceTableName': 'Tabela Atacado SP',
    'scopeType': 'Regional',
    'minQuantity': 10,
    'maxQuantity': 999,
    'state': 'SaoPaulo',
  };

  group('PricingExplanation', () {
    test('should map the snapshot and format labels', () {
      final pricing = PricingExplanation.fromJson(json);

      expect(pricing.referenceUnitPrice.amount, 5500);
      expect(pricing.discountPerUnit.amount, 500);
      expect(pricing.discountTotal.amount, 5000);
      expect(pricing.discountPercentage, 9.09);
      expect(pricing.priceTableName, 'Tabela Atacado SP');
      expect(pricing.rangeLabel, '10–999 un.');
      expect(pricing.locationLabel, 'São Paulo (SP)');
    });

    test('should call a rule without UF national', () {
      final pricing = PricingExplanation.fromJson({...json, 'state': null});

      expect(pricing.locationLabel, 'Nacional');
    });

    test('should build the tooltip text with table, range and savings', () {
      final pricing = PricingExplanation.fromJson(json);

      final text = explanationText(pricing);

      expect(text, contains('Tabela Atacado SP'));
      expect(text, contains('10–999 un.'));
      expect(text, contains('São Paulo (SP)'));
      expect(text, contains('R\$ 5.500,00'));
      expect(text, contains('R\$ 500,00'));
      expect(text, contains('9,09%'));
    });
  });
}
