import 'package:ecommerce_b2b/modules/customer_portal/presentation/widgets/buyer_summary_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('BuyerSummaryCard dispara o callback ao tocar', (tester) async {
    var taps = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Row(
            children: [
              BuyerSummaryCard(
                title: 'Pedidos Ativos',
                value: '2 ativos',
                icon: Icons.shopping_cart_outlined,
                backgroundColor: Colors.blue.shade100,
                foregroundColor: Colors.blue.shade900,
                onTap: () => taps++,
              ),
            ],
          ),
        ),
      ),
    );

    expect(find.text('Pedidos Ativos'), findsOneWidget);
    expect(find.text('2 ativos'), findsOneWidget);

    await tester.tap(find.byType(BuyerSummaryCard));
    await tester.pump();

    expect(taps, 1);
  });
}
