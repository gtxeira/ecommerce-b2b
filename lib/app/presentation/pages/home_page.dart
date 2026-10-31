import 'package:ecommerce_b2b/app/presentation/widgets/b2b_app_bar.dart';
import 'package:ecommerce_b2b/modules/identity_access/presentation/cubit/auth_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:ecommerce_b2b/app/core/routes/app_pages.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

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
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) => ListTile(
                leading: const CircleAvatar(
                  child: Icon(Icons.history, size: 20),
                ),
                title: Text('Pedido #100${5 - index} atualizado'),
                subtitle: const Text('Status alterado para "Em Transporte"'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {},
              ),
              childCount: 3,
            ),
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
