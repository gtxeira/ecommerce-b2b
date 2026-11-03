import 'package:ecommerce_b2b/app/presentation/widgets/discount_badge.dart';
import 'package:ecommerce_b2b/modules/catalog/price_table/model/pricing_explanation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final pricing = PricingExplanation.fromJson({
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
  });

  testWidgets('mostra o percentual e abre a explicação ao tocar', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(child: DiscountBadge(pricing: pricing, compact: true)),
        ),
      ),
    );

    expect(find.text('−9,09%'), findsOneWidget);

    await tester.tap(find.byType(ActionChip));
    await tester.pumpAndSettle();

    expect(find.text('Por que este desconto?'), findsOneWidget);
    expect(find.text('Tabela Atacado SP'), findsOneWidget);
    expect(find.text('10–999 un.'), findsOneWidget);
    expect(find.text('São Paulo (SP)'), findsOneWidget);
    expect(find.text('R\$ 500,00'), findsWidgets);
  });
}
