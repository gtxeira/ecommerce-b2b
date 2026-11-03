import 'package:ecommerce_b2b/modules/sales_team/sales_representative/model/commission.dart';
import 'package:ecommerce_b2b/modules/sales_team/sales_representative/model/enums/commission_status.dart';
import 'package:ecommerce_b2b/modules/sales_team/sales_representative/presentation/widgets/commission_details_sheet.dart';
import 'package:ecommerce_b2b/modules/shared_kernel/model/finance/value_objects/money.dart';
import 'package:ecommerce_b2b/modules/shared_kernel/model/finance/value_objects/percentage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const both = {CommissionStatus.paid, CommissionStatus.cancelled};

  Commission commission({
    int id = 5,
    CommissionStatus status = CommissionStatus.pending,
  }) => Commission(
    id: id,
    baseAmount: Money.create(1000).getOrThrow(),
    rate: Percentage.create(5).getOrThrow(),
    amount: Money.create(50).getOrThrow(),
    status: status,
    createdAt: DateTime.utc(2026, 11, 3, 14, 30),
    representativeName: 'Representante Mock',
  );

  Future<void> openSheet(
    WidgetTester tester,
    Commission value, {
    CommissionStatusCallback? onStatusChange,
    Set<CommissionStatus> allowedStatuses = const {},
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => Center(
              child: ElevatedButton(
                onPressed: () => showCommissionDetailsSheet(
                  context,
                  value,
                  onStatusChange: onStatusChange,
                  allowedStatuses: allowedStatuses,
                ),
                child: const Text('abrir'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('abrir'));
    await tester.pumpAndSettle();
  }

  testWidgets('comissão pendente com permissão total oferece as duas ações', (
    tester,
  ) async {
    await openSheet(
      tester,
      commission(),
      onStatusChange: (_) async => null,
      allowedStatuses: both,
    );

    expect(find.text('Marcar como paga'), findsOneWidget);
    expect(find.text('Cancelar comissão'), findsOneWidget);
  });

  testWidgets('supervisor vê somente a ação de cancelar', (tester) async {
    await openSheet(
      tester,
      commission(),
      onStatusChange: (_) async => null,
      allowedStatuses: const {CommissionStatus.cancelled},
    );

    expect(find.text('Marcar como paga'), findsNothing);
    expect(find.text('Cancelar comissão'), findsOneWidget);
  });

  testWidgets('sem permissão, comissão pendente não mostra ações', (
    tester,
  ) async {
    await openSheet(tester, commission());

    expect(find.text('Marcar como paga'), findsNothing);
    expect(find.text('Cancelar comissão'), findsNothing);
  });

  testWidgets('comissão paga não oferece novas transições', (tester) async {
    await openSheet(
      tester,
      commission(status: CommissionStatus.paid),
      onStatusChange: (_) async => null,
      allowedStatuses: both,
    );

    expect(find.text('Marcar como paga'), findsNothing);
    expect(find.text('Cancelar comissão'), findsNothing);
  });

  testWidgets('confirmar dispara o callback com o status escolhido', (
    tester,
  ) async {
    CommissionStatus? received;
    await openSheet(
      tester,
      commission(),
      onStatusChange: (target) async {
        received = target;
        return null;
      },
      allowedStatuses: both,
    );

    await tester.tap(find.text('Marcar como paga'));
    await tester.pumpAndSettle();
    expect(find.text('Confirmar'), findsOneWidget);

    await tester.tap(find.text('Confirmar'));
    await tester.pumpAndSettle();

    expect(received, CommissionStatus.paid);
  });
}
