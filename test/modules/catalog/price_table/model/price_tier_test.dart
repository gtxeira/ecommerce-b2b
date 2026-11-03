import 'package:ecommerce_b2b/modules/catalog/price_table/model/price_tier.dart';
import 'package:ecommerce_b2b/modules/shared_kernel/model/finance/value_objects/money.dart';
import 'package:flutter_test/flutter_test.dart';

PriceTier _tier({
  String productId = 'p1',
  String? variantId,
  int minQuantity = 1,
}) => PriceTier(
  productId: productId,
  variantId: variantId,
  priceTableId: 'pt-$productId',
  priceTableName: 'Tabela',
  scopeType: 'National',
  minQuantity: minQuantity,
  maxQuantity: 999,
  unitPrice: Money.create(10).getOrThrow(),
  referenceUnitPrice: Money.create(12).getOrThrow(),
  discountPerUnit: Money.create(2).getOrThrow(),
  discountPercentage: 16.67,
);

void main() {
  group('applicableTiers', () {
    test('sem variante usa apenas as faixas de produto', () {
      final tiers = [_tier(), _tier(variantId: 'v1')];

      final result = applicableTiers(tiers);

      expect(result.single.variantId, isNull);
    });

    test('variante com regra específica usa a regra dela', () {
      final tiers = [_tier(), _tier(variantId: 'v1'), _tier(variantId: 'v2')];

      final result = applicableTiers(tiers, variantId: 'v2');

      expect(result.single.variantId, 'v2');
    });

    test('variante sem regra específica cai na faixa de produto', () {
      final tiers = [_tier(), _tier(variantId: 'v1')];

      final result = applicableTiers(tiers, variantId: 'v2');

      expect(result.single.variantId, isNull);
    });

    test('produto sem faixa devolve vazio', () {
      expect(applicableTiers(const [], variantId: 'v1'), isEmpty);
    });
  });
}
