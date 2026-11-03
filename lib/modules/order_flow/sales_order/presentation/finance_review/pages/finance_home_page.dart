import 'package:ecommerce_b2b/app/core/di/service_locator.dart';
import 'package:ecommerce_b2b/app/core/routes/app_pages.dart';
import 'package:ecommerce_b2b/app/core/routes/order_routes.dart';
import 'package:ecommerce_b2b/app/presentation/widgets/b2b_app_bar.dart';
import 'package:ecommerce_b2b/modules/order_flow/sales_order/model/sales_order.dart';
import 'package:ecommerce_b2b/modules/order_flow/sales_order/presentation/finance_review/cubit/finance_review_cubit.dart';
import 'package:ecommerce_b2b/modules/order_flow/sales_order/presentation/finance_review/cubit/finance_summary_cubit.dart';
import 'package:ecommerce_b2b/modules/order_flow/sales_order/presentation/finance_review/finance_summary_copy.dart';
import 'package:ecommerce_b2b/modules/order_flow/sales_order/presentation/finance_review/widgets/finance_metric_card.dart';
import 'package:ecommerce_b2b/modules/order_flow/sales_order/presentation/widgets/order_summary_tile.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

class FinanceHomePage extends StatelessWidget {
  const FinanceHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (context) => getIt<FinanceReviewCubit>()..loadPendingOrders(),
        ),
        BlocProvider(create: (context) => getIt<FinanceSummaryCubit>()..load()),
      ],
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
                await Future.wait([
                  context.read<FinanceReviewCubit>().loadPendingOrders(),
                  context.read<FinanceSummaryCubit>().load(),
                ]);
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
                            'Monitore o risco de crédito da carteira de clientes, controle limites e aprove faturamentos.',
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
                      child:
                          BlocBuilder<FinanceSummaryCubit, FinanceSummaryState>(
                            builder: _buildSummarySection,
                          ),
                    ),
                  ),

                  // Ação Principal: Revisão de Crédito
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(24, 32, 24, 16),
                      child: isLoading
                          ? const Center(
                              child: Padding(
                                padding: EdgeInsets.all(32),
                                child: CircularProgressIndicator(),
                              ),
                            )
                          : _buildActionHeroCard(
                              context,
                              'Revisão de Crédito',
                              pendingCount == 0
                                  ? 'Nenhum pedido aguardando sua análise manual.'
                                  : 'Existem $pendingCount ${pendingCount == 1 ? 'pedido aguardando' : 'pedidos aguardando'} sua análise manual.',
                              Icons.gpp_maybe_rounded,
                              pendingCount > 0
                                  ? colorScheme.primary
                                  : colorScheme.surfaceContainerHigh,
                              pendingCount > 0
                                  ? colorScheme.onPrimary
                                  : colorScheme.onSurface,
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
                          return OrderSummaryTile(
                            order: order,
                            onTap: () => context.push(
                              OrderRoutes.detail(order.id.value),
                              extra: order,
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

  Widget _buildSummarySection(BuildContext context, FinanceSummaryState state) {
    final colorScheme = Theme.of(context).colorScheme;

    if (state is FinanceSummaryLoaded) {
      final summary = state.summary;
      return _buildMetricRow(
        context,
        exposureValue: summary.hasCompanies
            ? summary.totalExposure.formatted
            : '—',
        exposureCaption: financeExposureCaption(summary),
        utilizationValue: summary.hasCompanies ? summary.utilizationLabel : '—',
        utilizationCaption: financeRiskCaption(summary),
        risk:
            summary.hasCompanies &&
            (summary.companiesOverLimit > 0 ||
                summary.utilizationPercentage >= 80),
      );
    }

    if (state is FinanceSummaryFailure) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: colorScheme.errorContainer,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.error_outline_rounded,
                  color: colorScheme.onErrorContainer,
                  size: 20,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Não foi possível carregar os indicadores.',
                    style: TextStyle(
                      color: colorScheme.onErrorContainer,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: () => context.read<FinanceSummaryCubit>().load(),
                  style: TextButton.styleFrom(
                    foregroundColor: colorScheme.onErrorContainer,
                  ),
                  child: const Text('Tentar novamente'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          _buildMetricRow(
            context,
            exposureValue: '—',
            exposureCaption: 'Indisponível',
            utilizationValue: '—',
            utilizationCaption: 'Indisponível',
            risk: false,
          ),
        ],
      );
    }

    return _buildMetricRow(
      context,
      exposureValue: '—',
      exposureCaption: 'Carregando indicadores...',
      utilizationValue: '—',
      utilizationCaption: 'Carregando indicadores...',
      risk: false,
    );
  }

  Widget _buildMetricRow(
    BuildContext context, {
    required String exposureValue,
    required String exposureCaption,
    required String utilizationValue,
    required String utilizationCaption,
    required bool risk,
  }) {
    final colorScheme = Theme.of(context).colorScheme;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: FinanceMetricCard(
              label: financeExposureLabel,
              value: exposureValue,
              caption: exposureCaption,
              icon: Icons.account_balance_rounded,
              backgroundColor: colorScheme.secondaryContainer,
              foregroundColor: colorScheme.onSecondaryContainer,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: FinanceMetricCard(
              label: financeCommitmentLabel,
              value: utilizationValue,
              caption: utilizationCaption,
              icon: Icons.trending_up_rounded,
              backgroundColor: risk
                  ? colorScheme.errorContainer
                  : colorScheme.primaryContainer,
              foregroundColor: risk
                  ? colorScheme.onErrorContainer
                  : colorScheme.onPrimaryContainer,
            ),
          ),
        ],
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
