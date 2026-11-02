import 'package:ecommerce_b2b/app/core/di/service_locator.dart';
import 'package:ecommerce_b2b/app/presentation/widgets/b2b_app_bar.dart';
import 'package:ecommerce_b2b/modules/identity_access/presentation/cubit/auth_cubit.dart';
import 'package:ecommerce_b2b/modules/order_flow/sales_order/model/repositories/sales_order_repository.dart';
import 'package:ecommerce_b2b/modules/order_flow/sales_order/model/sales_order.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:ecommerce_b2b/app/core/routes/app_pages.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<SalesOrder> _recentOrders = const [];
  bool _loadingOrders = true;

  @override
  void initState() {
    super.initState();
    _loadRecentOrders();
  }

  Future<void> _loadRecentOrders() async {
    try {
      final orders = await getIt<SalesOrderRepository>().getAll();
      if (!mounted) return;
      setState(() {
        _recentOrders = orders.take(3).toList();
        _loadingOrders = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loadingOrders = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final authState = context.watch<AuthCubit>().state;
    final cardPages = authState is AuthAuthenticated
        ? AppPage.sidebarPagesFor(authState.session.role)
              .where((page) => page != AppPage.home && page != AppPage.login)
              .toList()
        : <AppPage>[];

    return Scaffold(
      appBar: const B2BAppBar(title: 'Painel Principal'),
      body: CustomScrollView(
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.all(20.0),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 1.4,
              ),
              delegate: SliverChildBuilderDelegate((context, index) {
                final page = cardPages[index];
                return _buildMenuCard(context, page, colorScheme);
              }, childCount: cardPages.length),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 20.0,
                vertical: 10.0,
              ),
              child: Text(
                'Atividades Recentes',
                style: textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          if (_loadingOrders)
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Center(child: CircularProgressIndicator()),
              ),
            )
          else if (_recentOrders.isEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20.0,
                  vertical: 8.0,
                ),
                child: Text(
                  'Nenhum pedido registrado.',
                  style: textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            )
          else
            SliverList(
              delegate: SliverChildBuilderDelegate((context, index) {
                final order = _recentOrders[index];
                return ListTile(
                  leading: const CircleAvatar(
                    child: Icon(Icons.history, size: 20),
                  ),
                  title: Text(
                    'Pedido #${order.id.displayCode}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    'Status: ${order.status.label} • Total: ${order.total.formatted}',
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {},
                );
              }, childCount: _recentOrders.length),
            ),
          const SliverToBoxAdapter(child: SizedBox(height: 40)),
        ],
      ),
    );
  }

  Widget _buildMenuCard(
    BuildContext context,
    AppPage page,
    ColorScheme colorScheme,
  ) {
    // Resolve o par de cores (Fundo e Texto) com base na propriedade do enum
    final (backgroundColor, foregroundColor) = switch (page.colorType) {
      CardColorType.primary => (colorScheme.primary, colorScheme.onPrimary),
      CardColorType.primaryContainer => (
        colorScheme.primaryContainer,
        colorScheme.onPrimaryContainer,
      ),
      CardColorType.secondaryContainer => (
        colorScheme.secondaryContainer,
        colorScheme.onSecondaryContainer,
      ),
      CardColorType.tertiaryContainer => (
        colorScheme.tertiaryContainer,
        colorScheme.onTertiaryContainer,
      ),
      CardColorType.surfaceVariant => (
        colorScheme.surfaceContainerHighest,
        colorScheme.onSurfaceVariant,
      ),
    };

    return Card(
      elevation: 0,
      color: backgroundColor,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: InkWell(
        onTap: () => context.go(page.path),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(page.icon, size: 32, color: foregroundColor),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    page.label,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: foregroundColor,
                    ),
                  ),
                  Text(
                    page.subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: foregroundColor.withValues(alpha: 0.8),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
