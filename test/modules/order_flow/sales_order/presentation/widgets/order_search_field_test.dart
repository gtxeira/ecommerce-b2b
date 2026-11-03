import 'package:ecommerce_b2b/modules/order_flow/sales_order/presentation/widgets/order_search_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget wrap(Widget child) => MaterialApp(home: Scaffold(body: child));

  group('OrderSearchField', () {
    testWidgets('digitar propaga o texto', (tester) async {
      final changes = <String>[];
      await tester.pumpWidget(wrap(OrderSearchField(onChanged: changes.add)));

      await tester.enterText(find.byType(TextField), 'acme');

      expect(changes, ['acme']);
    });

    testWidgets('mostra o botão de limpar só com texto', (tester) async {
      await tester.pumpWidget(wrap(OrderSearchField(onChanged: (_) {})));

      expect(find.byIcon(Icons.clear), findsNothing);

      await tester.enterText(find.byType(TextField), 'acme');
      await tester.pump();

      expect(find.byIcon(Icons.clear), findsOneWidget);
    });

    testWidgets('limpar zera o texto e propaga vazio', (tester) async {
      final changes = <String>[];
      await tester.pumpWidget(wrap(OrderSearchField(onChanged: changes.add)));

      await tester.enterText(find.byType(TextField), 'acme');
      await tester.pump();
      await tester.tap(find.byIcon(Icons.clear));
      await tester.pump();

      expect(changes.last, '');
      expect(find.byIcon(Icons.clear), findsNothing);
      expect(
        tester.widget<TextField>(find.byType(TextField)).controller?.text,
        '',
      );
    });

    testWidgets('respeita o valor inicial', (tester) async {
      await tester.pumpWidget(
        wrap(OrderSearchField(initialValue: 'inicial', onChanged: (_) {})),
      );

      expect(find.text('inicial'), findsOneWidget);
    });
  });
}
