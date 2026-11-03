import 'package:ecommerce_b2b/app/presentation/widgets/open_orders_badge.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget wrap(Widget child) => MaterialApp(home: Scaffold(body: child));

  group('OpenOrdersBadge', () {
    testWidgets('sem pedidos não mostra selo', (tester) async {
      await tester.pumpWidget(
        wrap(
          OpenOrdersBadge(
            count: 0,
            child: const Icon(Icons.assignment_rounded),
          ),
        ),
      );

      final badge = tester.widget<Badge>(find.byType(Badge));
      expect(badge.isLabelVisible, isFalse);
      expect(find.text('0'), findsNothing);
    });

    testWidgets('com pedidos mostra a quantidade', (tester) async {
      await tester.pumpWidget(
        wrap(
          OpenOrdersBadge(
            count: 3,
            child: const Icon(Icons.assignment_rounded),
          ),
        ),
      );

      expect(find.text('3'), findsOneWidget);
    });

    testWidgets('acima de 99 mostra 99+', (tester) async {
      await tester.pumpWidget(
        wrap(
          OpenOrdersBadge(
            count: 150,
            child: const Icon(Icons.assignment_rounded),
          ),
        ),
      );

      expect(find.text('99+'), findsOneWidget);
    });

    testWidgets('mantém o ícone filho', (tester) async {
      await tester.pumpWidget(
        wrap(
          OpenOrdersBadge(
            count: 1,
            child: const Icon(Icons.assignment_rounded),
          ),
        ),
      );

      expect(find.byIcon(Icons.assignment_rounded), findsOneWidget);
    });
  });
}
