import 'package:ecommerce_b2b/modules/order_flow/sales_order/presentation/finance_review/widgets/finance_metric_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('should render label, value and caption', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: FinanceMetricCard(
            label: 'Crédito em Uso pelos Clientes',
            value: 'R\$ 6.500,00',
            caption: 'de R\$ 15.000,00 concedidos aos clientes',
            icon: Icons.account_balance_rounded,
            backgroundColor: Colors.blue,
            foregroundColor: Colors.white,
          ),
        ),
      ),
    );

    expect(find.text('Crédito em Uso pelos Clientes'), findsOneWidget);
    expect(find.text('R\$ 6.500,00'), findsOneWidget);
    expect(
      find.text('de R\$ 15.000,00 concedidos aos clientes'),
      findsOneWidget,
    );
    expect(find.byIcon(Icons.account_balance_rounded), findsOneWidget);
  });
}
