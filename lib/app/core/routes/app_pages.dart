import 'package:ecommerce_b2b/app/core/routes/order_routes.dart';
import 'package:ecommerce_b2b/modules/identity_access/model/enums/user_role.dart';
import 'package:flutter/material.dart';

enum AppPage {
  login(
    path: '/login',
    label: 'Login',
    subtitle: 'Autenticação',
    icon: Icons.login_rounded,
    colorType: CardColorType.primary,
  ),
  home(
    path: '/',
    label: 'Painel Principal',
    subtitle: 'Visão geral',
    icon: Icons.home_rounded,
    colorType: CardColorType.surfaceVariant,
  ),
  companies(
    path: '/companies',
    label: 'Empresas',
    subtitle: 'Cadastro e gestão',
    icon: Icons.business_rounded,
    colorType: CardColorType.primaryContainer,
  ),
  buyers(
    path: '/buyers',
    label: 'Compradores',
    subtitle: 'Acessos autorizados',
    icon: Icons.people_alt_rounded,
    colorType: CardColorType.secondaryContainer,
  ),
  catalog(
    path: '/catalog',
    label: 'Catálogo',
    subtitle: 'Produtos e preços',
    icon: Icons.auto_awesome_mosaic_rounded,
    colorType: CardColorType.tertiaryContainer,
  ),
  orders(
    path: OrderRoutes.list,
    label: 'Pedidos',
    subtitle: 'Abertos e encerrados',
    icon: Icons.assignment_rounded,
    colorType: CardColorType.primaryContainer,
  ),
  quotes(
    path: '/quotes',
    label: 'Orçamentos',
    subtitle: 'Gestão de propostas',
    icon: Icons.receipt_long_rounded,
    colorType: CardColorType.primary,
  ),
  finance(
    path: '/finance',
    label: 'Análise de Crédito',
    subtitle: 'Revisão de pedidos',
    icon: Icons.account_balance_wallet_rounded,
    colorType: CardColorType.surfaceVariant,
  ),
  billing(
    path: '/billing',
    label: 'Faturamento',
    subtitle: 'Pedidos entregues',
    icon: Icons.receipt_long_rounded,
    colorType: CardColorType.tertiaryContainer,
  ),
  dashboard(
    path: '/dashboard',
    label: 'Dashboard',
    subtitle: 'Indicadores de venda',
    icon: Icons.analytics_rounded,
    colorType: CardColorType.surfaceVariant,
  ),
  logistics(
    path: '/logistics',
    label: 'Logística',
    subtitle: 'Expedição e rastreio',
    icon: Icons.local_shipping_rounded,
    colorType: CardColorType.surfaceVariant,
  ),
  inventory(
    path: '/inventory',
    label: 'Estoque',
    subtitle: 'Níveis de inventário',
    icon: Icons.inventory_rounded,
    colorType: CardColorType.surfaceVariant,
  ),
  users(
    path: '/users',
    label: 'Usuários',
    subtitle: 'Acessos e papéis',
    icon: Icons.manage_accounts_rounded,
    colorType: CardColorType.secondaryContainer,
  ),
  portal(
    path: '/portal',
    label: 'Portal',
    subtitle: 'Pós-venda e RMAs',
    icon: Icons.support_agent_rounded,
    colorType: CardColorType.surfaceVariant,
  );

  final String path;
  final String label;
  final String subtitle;
  final IconData icon;
  final CardColorType colorType;

  const AppPage({
    required this.path,
    required this.label,
    required this.subtitle,
    required this.icon,
    required this.colorType,
  });

  /// Define quais páginas são visíveis para cada papel na barra lateral
  static List<AppPage> sidebarPagesFor(UserRole role) {
    return switch (role) {
      UserRole.representative => [
        AppPage.home,
        AppPage.orders,
        AppPage.companies,
        AppPage.catalog,
        AppPage.quotes,
        AppPage.logistics,
        AppPage.inventory,
      ],
      UserRole.supervisor => [
        AppPage.home,
        AppPage.orders,
        AppPage.companies,
        AppPage.catalog,
        AppPage.quotes,
        AppPage.logistics,
        AppPage.inventory,
        AppPage.billing,
      ],
      UserRole.finance => [
        AppPage.home,
        AppPage.orders,
        AppPage.finance,
        AppPage.billing,
      ],
      UserRole.admin => [
        AppPage.home,
        AppPage.orders,
        AppPage.companies,
        AppPage.catalog,
        AppPage.quotes,
        AppPage.inventory,
        AppPage.finance,
        AppPage.billing,
        AppPage.logistics,
        AppPage.users,
      ],
      UserRole.buyer => [], // Comprador não usa sidebar/MainLayout
    };
  }
}

/// Helper interno para mapear as cores corretas dinamicamente com base no contexto
enum CardColorType {
  primary,
  primaryContainer,
  secondaryContainer,
  tertiaryContainer,
  surfaceVariant,
}
