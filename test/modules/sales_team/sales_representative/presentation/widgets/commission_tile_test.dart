import 'package:ecommerce_b2b/modules/sales_team/sales_representative/model/commission.dart';
import 'package:ecommerce_b2b/modules/sales_team/sales_representative/model/enums/commission_status.dart';
import 'package:ecommerce_b2b/modules/sales_team/sales_representative/presentation/widgets/commission_tile.dart';
import 'package:ecommerce_b2b/modules/shared_kernel/model/finance/value_objects/money.dart';
import 'package:ecommerce_b2b/modules/shared_kernel/model/finance/value_objects/percentage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Commission commission({String? orderId}) => Commission(
    baseAmount: Money.create(1000).getOrThrow(),
    rate: Percentage.create(5).getOrThrow(),
    amount: Money.create(50).getOrThrow(),
    status: CommissionStatus.pending,
    orderId: orderId,
    createdAt: DateTime.utc(2026, 11, 3, 14, 30),
    representativeName: 'Representante Mock',
  );

  testWidgets('mostra data, representante e pedido de origem', (tester) async {
    var tapped = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CommissionTile(
            commission: commission(orderId: 'order-1'),
            onTap: () => tapped = true,
          ),
        ),
      ),
    );

    expect(find.textContaining('Gerada em'), findsOneWidget);
    expect(
      find.textContaining('Representante: Representante Mock'),
      findsOneWidget,
    );
    expect(find.textContaining('Pedido #order-1'), findsOneWidget);

    await tester.tap(find.byType(CommissionTile));
    expect(tapped, isTrue);
  });

  testWidgets('indica comissão histórica sem pedido vinculado', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CommissionTile(commission: commission(), onTap: () {}),
        ),
      ),
    );

    expect(find.textContaining('Sem pedido vinculado'), findsOneWidget);
  });
}
