import 'dart:ui' show Tristate;

import 'package:ecommerce_b2b/app/core/routes/app_pages.dart';
import 'package:ecommerce_b2b/app/presentation/layouts/app_sidebar.dart';
import 'package:ecommerce_b2b/app/presentation/theme/app_theme.dart';
import 'package:ecommerce_b2b/modules/identity_access/model/enums/user_role.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _wrap({
  required List<AppPage> pages,
  AppPage? selectedPage,
  int openOrdersCount = 0,
  ValueChanged<AppPage>? onPageSelected,
}) => MaterialApp(
  theme: AppTheme.light,
  home: Scaffold(
    body: Row(
      children: [
        AppSidebar(
          pages: pages,
          selectedPage: selectedPage ?? pages.first,
          openOrdersCount: openOrdersCount,
          onPageSelected: onPageSelected ?? (_) {},
        ),
      ],
    ),
  ),
);

void main() {
  group('agrupamento', () {
    testWidgets('admin vê as cinco seções na ordem da referência', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(pages: AppPage.sidebarPagesFor(UserRole.admin)),
      );

      final labels = SidebarSection.values.map((section) => section.label);
      for (final label in labels) {
        expect(find.text(label), findsOneWidget);
      }

      final positions = labels
          .map((label) => tester.getTopLeft(find.text(label)).dy)
          .toList();
      expect(positions, orderedEquals([...positions]..sort()));
    });

    testWidgets('financeiro não vê seções sem páginas liberadas', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(pages: AppPage.sidebarPagesFor(UserRole.finance)),
      );

      expect(find.text('GERAL'), findsOneWidget);
      expect(find.text('COMERCIAL'), findsOneWidget);
      expect(find.text('FINANCEIRO'), findsOneWidget);
      expect(find.text('OPERAÇÕES'), findsNothing);
      expect(find.text('GESTÃO'), findsNothing);
      expect(find.text('Comissões'), findsOneWidget);
    });

    testWidgets('representante vê operações e não vê financeiro', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(pages: AppPage.sidebarPagesFor(UserRole.representative)),
      );

      expect(find.text('OPERAÇÕES'), findsOneWidget);
      expect(find.text('FINANCEIRO'), findsNothing);
      expect(find.text('GESTÃO'), findsNothing);
      expect(find.text('Comissões'), findsOneWidget);
    });

    testWidgets('só renderiza as páginas recebidas', (tester) async {
      await tester.pumpWidget(
        _wrap(pages: AppPage.sidebarPagesFor(UserRole.finance)),
      );

      expect(find.text('Pedidos'), findsOneWidget);
      expect(find.text('Empresas'), findsNothing);
      expect(find.text('Usuários'), findsNothing);
    });
  });

  group('badge de pedidos', () {
    testWidgets('mostra a contagem à direita do item Pedidos', (tester) async {
      await tester.pumpWidget(
        _wrap(
          pages: AppPage.sidebarPagesFor(UserRole.admin),
          openOrdersCount: 3,
        ),
      );

      expect(find.text('3'), findsOneWidget);

      final badgeX = tester.getCenter(find.text('3')).dx;
      final labelX = tester.getCenter(find.text('Pedidos')).dx;
      expect(badgeX, greaterThan(labelX));
    });

    testWidgets('fica oculto quando não há pedidos em aberto', (tester) async {
      await tester.pumpWidget(
        _wrap(
          pages: AppPage.sidebarPagesFor(UserRole.admin),
          openOrdersCount: 0,
        ),
      );

      expect(find.text('0'), findsNothing);
    });

    testWidgets('limita a contagem em 99+', (tester) async {
      await tester.pumpWidget(
        _wrap(
          pages: AppPage.sidebarPagesFor(UserRole.admin),
          openOrdersCount: 150,
        ),
      );

      expect(find.text('99+'), findsOneWidget);
    });
  });

  group('interação', () {
    testWidgets('clicar em um item devolve a página correspondente', (
      tester,
    ) async {
      AppPage? selected;
      await tester.pumpWidget(
        _wrap(
          pages: AppPage.sidebarPagesFor(UserRole.admin),
          onPageSelected: (page) => selected = page,
        ),
      );

      await tester.tap(find.text('Empresas'));
      await tester.pumpAndSettle();

      expect(selected, AppPage.companies);
    });

    testWidgets('marca o item ativo como selecionado', (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        _wrap(
          pages: AppPage.sidebarPagesFor(UserRole.admin),
          selectedPage: AppPage.orders,
        ),
      );

      final orders = tester.getSemantics(
        find.byKey(const ValueKey('sidebar-orders')),
      );
      final home = tester.getSemantics(
        find.byKey(const ValueKey('sidebar-home')),
      );

      expect(orders.flagsCollection.isSelected, Tristate.isTrue);
      expect(home.flagsCollection.isSelected, Tristate.isFalse);
      handle.dispose();
    });

    testWidgets('não renderiza rodapé, o tema fica no perfil', (tester) async {
      await tester.pumpWidget(
        _wrap(pages: AppPage.sidebarPagesFor(UserRole.admin)),
      );

      expect(find.byType(IconButton), findsNothing);
      expect(find.byType(Divider), findsNothing);
    });
  });

  testWidgets('continua rolável em janelas baixas', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: SizedBox(
            height: 220,
            child: AppSidebar(
              pages: AppPage.sidebarPagesFor(UserRole.admin),
              selectedPage: AppPage.home,
              openOrdersCount: 2,
              onPageSelected: (_) {},
            ),
          ),
        ),
      ),
    );

    expect(tester.takeException(), isNull);
    expect(find.byType(Scrollable), findsWidgets);

    await tester.drag(
      find.byType(SingleChildScrollView),
      const Offset(0, -400),
    );
    await tester.pumpAndSettle();

    expect(find.text('Usuários'), findsOneWidget);
  });
}
