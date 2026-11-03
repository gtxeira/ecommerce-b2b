import 'package:ecommerce_b2b/app/core/routes/app_pages.dart';
import 'package:flutter/material.dart';

/// Seções exibidas na barra lateral, na ordem em que aparecem.
///
/// A ordem das seções é fixa; já a ordem dos itens dentro de cada seção segue a
/// ordem declarada aqui. Grupos sem páginas visíveis para o papel atual são
/// omitidos por [AppSidebar].
enum SidebarSection {
  general('GERAL'),
  commercial('COMERCIAL'),
  financial('FINANCEIRO'),
  operations('OPERAÇÕES'),
  management('GESTÃO');

  const SidebarSection(this.label);

  final String label;

  /// Páginas que pertencem à seção, antes do filtro por papel.
  List<AppPage> get pages => switch (this) {
    SidebarSection.general => const [AppPage.home],
    SidebarSection.commercial => const [
      AppPage.orders,
      AppPage.companies,
      AppPage.catalog,
      AppPage.quotes,
    ],
    SidebarSection.financial => const [AppPage.finance, AppPage.billing],
    SidebarSection.operations => const [AppPage.inventory, AppPage.logistics],
    SidebarSection.management => const [AppPage.users],
  };
}

/// Barra lateral de navegação com seções e logo fixo.
///
/// O widget é puramente visual: recebe a página ativa e notifica a navegação
/// por callback. O controle do tema continua no menu do perfil.
class AppSidebar extends StatelessWidget {
  const AppSidebar({
    super.key,
    required this.pages,
    required this.selectedPage,
    required this.openOrdersCount,
    required this.onPageSelected,
  });

  /// Páginas visíveis para o papel do usuário logado.
  final List<AppPage> pages;

  /// Página destacada como ativa.
  final AppPage selectedPage;

  /// Quantidade de pedidos em aberto exibida no item "Pedidos".
  final int openOrdersCount;

  final ValueChanged<AppPage> onPageSelected;

  static const double width = 220;

  /// Páginas da seção que estão visíveis para o papel atual.
  List<AppPage> _visiblePagesOf(SidebarSection section) =>
      section.pages.where(pages.contains).toList();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      width: width,
      decoration: BoxDecoration(
        color: colorScheme.surface,
        border: Border(
          right: BorderSide(
            color: colorScheme.outlineVariant.withValues(alpha: 0.5),
          ),
        ),
      ),
      child: Column(
        children: [
          const _SidebarHeader(),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (final section in SidebarSection.values)
                    if (_visiblePagesOf(section).isNotEmpty) ...[
                      _SectionLabel(label: section.label),
                      for (final page in _visiblePagesOf(section))
                        _SidebarItem(
                          key: ValueKey('sidebar-${page.name}'),
                          page: page,
                          selected: page == selectedPage,
                          badgeCount: page == AppPage.orders
                              ? openOrdersCount
                              : 0,
                          onTap: () => onPageSelected(page),
                        ),
                    ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SidebarHeader extends StatelessWidget {
  const _SidebarHeader();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
      child: Image.asset(
        'assets/icon/ecommerce-b2b.png',
        width: 56,
        height: 56,
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 16, 12, 6),
      child: Text(
        label,
        style: theme.textTheme.labelSmall?.copyWith(
          color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.8),
          fontWeight: FontWeight.w700,
          letterSpacing: 1.1,
        ),
      ),
    );
  }
}

class _SidebarItem extends StatelessWidget {
  const _SidebarItem({
    super.key,
    required this.page,
    required this.selected,
    required this.badgeCount,
    required this.onTap,
  });

  final AppPage page;
  final bool selected;
  final int badgeCount;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final foreground = selected
        ? colorScheme.primary
        : colorScheme.onSurfaceVariant;

    return Semantics(
      selected: selected,
      button: true,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 2),
        child: Material(
          color: selected
              ? colorScheme.primary.withValues(alpha: 0.12)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
              child: Row(
                children: [
                  Icon(page.icon, size: 20, color: foreground),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      page.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: selected ? colorScheme.primary : null,
                        fontWeight: selected
                            ? FontWeight.w700
                            : FontWeight.w500,
                      ),
                    ),
                  ),
                  if (badgeCount > 0) ...[
                    const SizedBox(width: 8),
                    _OrdersCountBadge(count: badgeCount),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Pílula vermelha com a contagem de pedidos em aberto.
class _OrdersCountBadge extends StatelessWidget {
  const _OrdersCountBadge({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: colorScheme.error,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        count > 99 ? '99+' : '$count',
        style: TextStyle(
          color: colorScheme.onError,
          fontSize: 11,
          fontWeight: FontWeight.bold,
          height: 1.4,
        ),
      ),
    );
  }
}
