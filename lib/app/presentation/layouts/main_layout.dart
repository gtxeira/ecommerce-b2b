import 'package:ecommerce_b2b/app/core/routes/app_pages.dart';
import 'package:ecommerce_b2b/app/presentation/layouts/app_sidebar.dart';
import 'package:ecommerce_b2b/modules/identity_access/presentation/cubit/auth_cubit.dart';
import 'package:ecommerce_b2b/modules/order_flow/sales_order/presentation/cubit/open_orders_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

class MainLayout extends StatelessWidget {
  /// O child representa a tela interna atual que o GoRouter injeta automaticamente.
  final Widget child;

  const MainLayout({super.key, required this.child});

  /// Descobre qual página da sidebar corresponde ao path atual da URL.
  ///
  /// O match é por prefixo (para rotas filhas) com caso especial para `/`, que
  /// não pode casar com qualquer caminho. Rotas fora da sidebar (ex.:
  /// `/orders/:id`) caem no fallback da primeira página (Home).
  AppPage _calculateSelectedPage(BuildContext context, List<AppPage> pages) {
    final String path = GoRouterState.of(context).uri.path;

    var selectedPage = pages.first;
    var longestMatch = -1;

    for (final page in pages) {
      final String pagePath = page.path;
      final bool matches = pagePath == '/'
          ? path == '/'
          : path == pagePath || path.startsWith('$pagePath/');

      if (matches && pagePath.length > longestMatch) {
        selectedPage = page;
        longestMatch = pagePath.length;
      }
    }

    return selectedPage;
  }

  /// Navega dinamicamente usando a estrutura de rotas do GoRouter.
  void _onPageSelected(BuildContext context, AppPage page) {
    context.go(page.path);
  }

  @override
  Widget build(BuildContext context) {
    final authState = context.watch<AuthCubit>().state;

    // Fallback caso não esteja autenticado (embora o router deva bloquear)
    if (authState is! AuthAuthenticated) return child;

    final visiblePages = AppPage.sidebarPagesFor(authState.session.role);
    if (visiblePages.isEmpty) return child;

    final selectedPage = _calculateSelectedPage(context, visiblePages);
    final openOrdersCount = context.watch<OpenOrdersCubit>().state.count;

    return Scaffold(
      body: Row(
        children: [
          AppSidebar(
            pages: visiblePages,
            selectedPage: selectedPage,
            openOrdersCount: openOrdersCount,
            onPageSelected: (page) => _onPageSelected(context, page),
          ),
          // Exibe dinamicamente o conteúdo da sub-rota ativa gerenciada pelo GoRouter
          Expanded(child: child),
        ],
      ),
    );
  }
}
