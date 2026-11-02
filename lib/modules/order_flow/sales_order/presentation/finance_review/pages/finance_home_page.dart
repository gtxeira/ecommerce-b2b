import 'package:ecommerce_b2b/app/core/di/service_locator.dart';
import 'package:ecommerce_b2b/app/core/routes/app_pages.dart';
import 'package:ecommerce_b2b/app/presentation/widgets/b2b_app_bar.dart';
import 'package:ecommerce_b2b/modules/order_flow/sales_order/model/sales_order.dart';
import 'package:ecommerce_b2b/modules/order_flow/sales_order/presentation/finance_review/cubit/finance_review_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

class FinanceHomePage extends StatelessWidget {
  const FinanceHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return BlocProvider(
      create: (context) => getIt<FinanceReviewCubit>()..loadPendingOrders(),
      child: Scaffold(
        appBar: const B2BAppBar(title: 'Painel Financeiro'),
        body: BlocBuilder<FinanceReviewCubit, FinanceReviewState>(
          builder: (context, state) {
            int pendingCount = 0;
            bool isLoading = state is FinanceReviewLoading;
            List<SalesOrder> recentReleases = const [];

            if (state is FinanceReviewLoaded) {
              pendingCount = state.pendingOrders.length;
              recentReleases = state.recentReleases;
            }

            return RefreshIndicator(
              onRefresh: () async {
                context.read<FinanceReviewCubit>().loadPendingOrders();
              },
              child: CustomScrollView(
                slivers: [
                  // Cabeçalho de Boas-vindas
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Gestão de Risco',
                            style: theme.textTheme.displaySmall?.copyWith(
                              fontWeight: FontWeight.w900,
                              letterSpacing: -1.5,
                              color: colorScheme.onSurface,
                            ),
                          ),
                          Text(
                            'Monitore a saúde financeira, controle limites de crédito e aprove faturamentos.',
                            style: theme.textTheme.bodyLarge?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Cards de Métricas Críticas (Expressive Row)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24.0),
                      child: Row(
                        children: [
                          _buildMetricCard(
                            context,
                            'Meta de Inadimplência',
                            '< 2.0%',
                            Icons.trending_down_rounded,
                            colorScheme.errorContainer,
                            colorScheme.onErrorContainer,
                          ),
                          const SizedBox(width: 12),
                          _buildMetricCard(
                            context,
                            'Carteira Ativa',
                            'R\$ 4.8M',
                            Icons.account_balance_rounded,
                            colorScheme.secondaryContainer,
                            colorScheme.onSecondaryContainer,
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Ação Principal: Revisão de Crédito
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(24, 32, 24, 16),
                      child: isLoading
                          ? const Center(child: Padding(padding: EdgeInsets.all(32), child: CircularProgressIndicator()))
                          : _buildActionHeroCard(
                              context,
                              'Revisão de Crédito',
                              pendingCount == 0
                                  ? 'Nenhum pedido aguardando sua análise manual.'
                                  : 'Existem $pendingCount ${pendingCount == 1 ? 'pedido aguardando' : 'pedidos aguardando'} sua análise manual.',
                              Icons.gpp_maybe_rounded,
                              pendingCount > 0 ? colorScheme.primary : colorScheme.surfaceContainerHigh,
                              pendingCount > 0 ? colorScheme.onPrimary : colorScheme.onSurface,
                              () => context.go(AppPage.finance.path),
                            ),
                    ),
                  ),

                  // Seção de Atividades Recentes
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
                      child: Text(
                        'Histórico Recente de Liberações',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ),

                  if (isLoading)
                    const SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.symmetric(vertical: 32),
                        child: Center(child: CircularProgressIndicator()),
                      ),
                    )
                  else if (recentReleases.isEmpty)
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Text(
                          'Nenhuma liberação recente.',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    )
                  else
                    SliverPadding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate((context, index) {
                          final order = recentReleases[index];
                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            color: colorScheme.surfaceContainerLow,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(24),
                            ),
                            child: ListTile(
                              contentPadding: const EdgeInsets.all(16),
                              leading: CircleAvatar(
                                backgroundColor: Colors.green.withValues(
                                  alpha: 0.15,
                                ),
                                child: const Icon(
                                  Icons.check_circle_outline_rounded,
                                  color: Colors.green,
                                ),
                              ),
                              title: Text(
                                'Pedido #${order.id.displayCode}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              subtitle: Text(
                                'Status: ${order.status.label} • Total: ${order.total.formatted}',
                                style: const TextStyle(fontSize: 12),
                              ),
                              trailing: const Icon(Icons.chevron_right_rounded),
                            ),
                          );
                        }, childCount: recentReleases.length),
                      ),
                    ),

                  const SliverToBoxAdapter(child: SizedBox(height: 32)),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildMetricCard(
    BuildContext context,
    String label,
    String value,
    IconData icon,
    Color backgroundColor,
    Color foregroundColor,
  ) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(28),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: foregroundColor, size: 28),
            const SizedBox(height: 16),
            Text(
              value,
              style: TextStyle(
                color: foregroundColor,
                fontSize: 22,
                fontWeight: FontWeight.w900,
              ),
            ),
            Text(
              label,
              style: TextStyle(
                color: foregroundColor.withValues(alpha: 0.8),
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionHeroCard(
    BuildContext context,
    String title,
    String subtitle,
    IconData icon,
    Color backgroundColor,
    Color foregroundColor,
    VoidCallback onTap,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: backgroundColor.withValues(alpha: 0.2),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(32),
          child: Padding(
            padding: const EdgeInsets.all(28.0),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: foregroundColor.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, size: 36, color: foregroundColor),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                          color: foregroundColor,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 14,
                          color: foregroundColor.withValues(alpha: 0.8),
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 18,
                  color: foregroundColor,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
