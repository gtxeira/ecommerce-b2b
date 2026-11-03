import 'package:ecommerce_b2b/modules/identity_access/presentation/cubit/auth_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:ecommerce_b2b/app/core/routes/app_pages.dart';
import 'package:ecommerce_b2b/main.dart';

class MainLayout extends StatelessWidget {
  /// O child representa a tela interna atual que o GoRouter injeta automaticamente.
  final Widget child;

  const MainLayout({super.key, required this.child});

  /// Calcula dinamicamente o índice correto do menu baseado no path atual da URL.
  ///
  /// O match é por prefixo (para rotas filhas) com caso especial para `/`, que
  /// não pode casar com qualquer caminho. Rotas fora da sidebar (ex.:
  /// `/orders/:id`) caem no fallback da Home.
  int _calculateSelectedIndex(BuildContext context, List<AppPage> pages) {
    final String path = GoRouterState.of(context).uri.path;

    var selectedIndex = 0;
    var longestMatch = -1;

    for (int i = 0; i < pages.length; i++) {
      final String pagePath = pages[i].path;
      final bool matches = pagePath == '/'
          ? path == '/'
          : path == pagePath || path.startsWith('$pagePath/');

      if (matches && pagePath.length > longestMatch) {
        selectedIndex = i;
        longestMatch = pagePath.length;
      }
    }

    return selectedIndex; // Fallback para a primeira página (Home)
  }

  /// Navega dinamicamente usando a estrutura de rotas do GoRouter
  void _onDestinationSelected(
    BuildContext context,
    int index,
    List<AppPage> pages,
  ) {
    final destinationPage = pages[index];
    context.go(destinationPage.path);
  }

  @override
  Widget build(BuildContext context) {
    final authState = context.watch<AuthCubit>().state;

    // Fallback caso não esteja autenticado (embora o router deva bloquear)
    if (authState is! AuthAuthenticated) return child;

    final visiblePages = AppPage.sidebarPagesFor(authState.session.role);
    final selectedIndex = _calculateSelectedIndex(context, visiblePages);

    return Scaffold(
      body: Row(
        children: [
          NavigationRail(
            selectedIndex: selectedIndex,
            onDestinationSelected: (index) =>
                _onDestinationSelected(context, index, visiblePages),
            labelType: NavigationRailLabelType.all,
            leading: Padding(
              padding: const EdgeInsets.symmetric(
                vertical: 24.0,
                horizontal: 8.0,
              ),
              child: Image.asset(
                'assets/icon/ecommerce-b2b.png',
                width: 56,
                height: 56,
              ),
            ),
            destinations: visiblePages.map((page) {
              return NavigationRailDestination(
                icon: Icon(page.icon),
                selectedIcon: Icon(page.icon),
                label: Text(page.label),
              );
            }).toList(),
            trailing: Expanded(
              child: Align(
                alignment: Alignment.bottomCenter,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 24.0),
                  child: ValueListenableBuilder<ThemeMode>(
                    valueListenable: themeNotifier,
                    builder: (context, currentMode, _) {
                      final isDark =
                          currentMode == ThemeMode.dark ||
                          (currentMode == ThemeMode.system &&
                              MediaQuery.of(context).platformBrightness ==
                                  Brightness.dark);
                      return IconButton(
                        icon: Icon(isDark ? Icons.light_mode : Icons.dark_mode),
                        onPressed: () {
                          themeNotifier.value = isDark
                              ? ThemeMode.light
                              : ThemeMode.dark;
                        },
                        tooltip: isDark
                            ? 'Mudar para Tema Claro'
                            : 'Mudar para Tema Escuro',
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
          const VerticalDivider(thickness: 1, width: 1),
          // Exibe dinamicamente o conteúdo da sub-rota ativa gerenciada pelo GoRouter
          Expanded(child: child),
        ],
      ),
    );
  }
}
