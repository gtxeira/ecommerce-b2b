import 'package:ecommerce_b2b/app/core/di/service_locator.dart';
import 'package:ecommerce_b2b/app/core/format/date_format.dart';
import 'package:ecommerce_b2b/app/core/format/display_labels.dart';
import 'package:ecommerce_b2b/app/core/routes/app_pages.dart';
import 'package:ecommerce_b2b/app/core/routes/commission_routes.dart';
import 'package:ecommerce_b2b/app/presentation/widgets/b2b_app_bar.dart';
import 'package:ecommerce_b2b/modules/identity_access/presentation/cubit/auth_cubit.dart';
import 'package:ecommerce_b2b/modules/sales_team/sales_representative/model/commission.dart';
import 'package:ecommerce_b2b/modules/sales_team/sales_representative/presentation/cubit/representative_dashboard_cubit.dart';
import 'package:ecommerce_b2b/modules/sales_team/sales_representative/presentation/widgets/commission_details_sheet.dart';
import 'package:ecommerce_b2b/modules/sales_team/sales_representative/presentation/widgets/commission_tile.dart';
import 'package:ecommerce_b2b/modules/shared_kernel/model/common/ids/representative_id.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

const _teamScopeValue = '__team__';

class RepresentativeHomePage extends StatelessWidget {
  const RepresentativeHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final authState = context.watch<AuthCubit>().state;

    if (authState is! AuthAuthenticated) {
      return const Center(child: CircularProgressIndicator());
    }

    final session = authState.session;

    return BlocProvider(
      create: (context) =>
          getIt<RepresentativeDashboardCubit>()
            ..loadDashboard(session, teamView: session.isSupervisor),
      child: Scaffold(
        appBar: const B2BAppBar(title: 'Painel do Representante'),
        body: BlocBuilder<RepresentativeDashboardCubit, RepresentativeDashboardState>(
          builder: (context, state) {
            if (state is RepresentativeDashboardLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            if (state is RepresentativeDashboardFailure) {
              return Center(
                child: Text(
                  state.message,
                  style: TextStyle(color: colorScheme.error),
                ),
              );
            }

            if (state is RepresentativeDashboardLoaded) {
              return RefreshIndicator(
                onRefresh: () =>
                    context.read<RepresentativeDashboardCubit>().loadDashboard(
                      session,
                      targetRepId: state.selectedRepId,
                      teamView: state.isTeamView,
                    ),
                child: CustomScrollView(
                  slivers: [
                    // Supervisor Team Selector
                    if (session.isSupervisor && state.subordinates.isNotEmpty)
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20.0,
                            vertical: 10.0,
                          ),
                          child: Card(
                            elevation: 2,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16.0,
                                vertical: 12.0,
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.supervised_user_circle_rounded,
                                    color: colorScheme.primary,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          'Visualizar Equipe',
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.grey,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        DropdownButtonHideUnderline(
                                          child: DropdownButton<String>(
                                            isExpanded: true,
                                            value: state.isTeamView
                                                ? _teamScopeValue
                                                : state.selectedRepId.value,
                                            items: [
                                              DropdownMenuItem(
                                                value: _teamScopeValue,
                                                child: const Text(
                                                  'Toda a Equipe (Consolidado)',
                                                  style: TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ),
                                              DropdownMenuItem(
                                                value: session.userId.value,
                                                child: const Text(
                                                  'Meu Painel (Pessoal)',
                                                ),
                                              ),
                                              ...state.subordinates.map(
                                                (sub) => DropdownMenuItem(
                                                  value: sub.id.value,
                                                  child: Text(sub.fullName),
                                                ),
                                              ),
                                            ],
                                            onChanged: (newValue) {
                                              if (newValue == null) return;
                                              if (newValue == _teamScopeValue) {
                                                context
                                                    .read<
                                                      RepresentativeDashboardCubit
                                                    >()
                                                    .loadDashboard(
                                                      session,
                                                      teamView: true,
                                                    );
                                              } else {
                                                context
                                                    .read<
                                                      RepresentativeDashboardCubit
                                                    >()
                                                    .loadDashboard(
                                                      session,
                                                      targetRepId:
                                                          RepresentativeId(
                                                            newValue,
                                                          ),
                                                    );
                                              }
                                            },
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),

                    // Resumo Expressivo
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              state.isTeamView && state.subordinates.isNotEmpty
                                  ? 'Desempenho da Equipe'
                                  : state.selectedRepId.value ==
                                        session.userId.value
                                  ? 'Seu Desempenho'
                                  : 'Desempenho: ${state.selectedRepName}',
                              style: theme.textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.w900,
                                letterSpacing: -1,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                _buildMetricCard(
                                  context,
                                  label: 'Comissões',
                                  value: _calculateTotalCommissions(
                                    state.commissions,
                                  ),
                                  icon: Icons.payments_outlined,
                                  color: colorScheme.primaryContainer,
                                  onTap: () => context.push(
                                    CommissionRoutes.withScope(
                                      isTeamView: state.isTeamView,
                                      representativeId:
                                          state.selectedRepId.value,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                _buildMetricCard(
                                  context,
                                  label: 'Carteira',
                                  value: '${state.clientCount} Clientes',
                                  icon: Icons.supervised_user_circle_outlined,
                                  color: colorScheme.secondaryContainer,
                                  onTap: () =>
                                      context.push(_companiesPath(state)),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),

                    if (state.isTeamView &&
                        state.subordinates.isNotEmpty &&
                        state.performances.isNotEmpty)
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Resumo por Representante',
                                style: theme.textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 12),
                              ...state.performances.map(
                                (performance) => Card(
                                  margin: const EdgeInsets.only(bottom: 8),
                                  elevation: 0,
                                  color: colorScheme.surfaceContainerLow,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: ListTile(
                                    leading: CircleAvatar(
                                      backgroundColor:
                                          colorScheme.primaryContainer,
                                      child: Icon(
                                        Icons.person_rounded,
                                        color: colorScheme.onPrimaryContainer,
                                      ),
                                    ),
                                    title: Text(
                                      performance.isSelf
                                          ? '${performance.name} (Você)'
                                          : performance.name,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    subtitle: Text(
                                      'Comissões: ${performance.commissionTotal.formatted} · '
                                      'Clientes: ${performance.clientsCount} · '
                                      'Orçamentos: ${performance.quotesCount}',
                                    ),
                                    trailing: const Icon(
                                      Icons.chevron_right_rounded,
                                    ),
                                    onTap: () => context
                                        .read<RepresentativeDashboardCubit>()
                                        .loadDashboard(
                                          session,
                                          targetRepId:
                                              performance.representativeId,
                                        ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                    // Lista de Comissões Recentes
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                'Comissões Recentes',
                                style: theme.textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            TextButton(
                              onPressed: () => context.push(
                                CommissionRoutes.withScope(
                                  isTeamView: state.isTeamView,
                                  representativeId: state.selectedRepId.value,
                                ),
                              ),
                              child: const Text('Ver todas'),
                            ),
                          ],
                        ),
                      ),
                    ),
                    if (state.commissions.isEmpty)
                      const SliverToBoxAdapter(
                        child: Padding(
                          padding: EdgeInsets.all(32.0),
                          child: Center(
                            child: Text('Nenhuma comissão registrada.'),
                          ),
                        ),
                      )
                    else
                      SliverPadding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        sliver: SliverList(
                          delegate: SliverChildBuilderDelegate((
                            context,
                            index,
                          ) {
                            final commission = state.commissions[index];
                            return CommissionTile(
                              commission: commission,
                              representativeName: state.isTeamView
                                  ? commission.representativeName
                                  : null,
                              onTap: () => showCommissionDetailsSheet(
                                context,
                                commission,
                                representativeName: state.isTeamView
                                    ? commission.representativeName
                                    : null,
                              ),
                            );
                          }, childCount: state.commissions.length),
                        ),
                      ),

                    // Lista de Orçamentos Recentes
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 32, 20, 16),
                        child: Text(
                          'Orçamentos Recentes',
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    if (state.recentQuotes.isEmpty)
                      const SliverToBoxAdapter(
                        child: Padding(
                          padding: EdgeInsets.all(32.0),
                          child: Center(
                            child: Text('Nenhum orçamento registrado.'),
                          ),
                        ),
                      )
                    else
                      SliverPadding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        sliver: SliverList(
                          delegate: SliverChildBuilderDelegate((
                            context,
                            index,
                          ) {
                            final quote = state.recentQuotes[index];
                            return Card(
                              margin: const EdgeInsets.only(bottom: 8),
                              child: ListTile(
                                leading: CircleAvatar(
                                  backgroundColor:
                                      colorScheme.tertiaryContainer,
                                  child: const Icon(
                                    Icons.request_quote_rounded,
                                  ),
                                ),
                                title: Text(
                                  'Orçamento #${quote.id.displayCode}',
                                ),
                                subtitle: Text(
                                  [
                                    'Total: ${quote.total.formatted} - ${quote.status.label}',
                                    if (quote.companyId != null)
                                      'Empresa: ${companyLabel(tradeName: quote.companyName, legalName: quote.companyLegalName, id: quote.companyId!)}',
                                    [
                                      'Criado em ${formatDateTimeOrDash(quote.createdAt)}',
                                      if (state.isTeamView &&
                                          (quote.representativeName ?? '')
                                              .trim()
                                              .isNotEmpty)
                                        'Rep: ${quote.representativeName}',
                                    ].join(' · '),
                                  ].join('\n'),
                                ),
                                isThreeLine: true,
                                trailing: const Icon(
                                  Icons.chevron_right_rounded,
                                ),
                                onTap: () => context.go(
                                  '${AppPage.quotes.path}?tab=list',
                                ),
                              ),
                            );
                          }, childCount: state.recentQuotes.length),
                        ),
                      ),
                    const SliverToBoxAdapter(child: SizedBox(height: 32)),
                  ],
                ),
              );
            }

            return const SizedBox.shrink();
          },
        ),
      ),
    );
  }

  String _companiesPath(RepresentativeDashboardLoaded state) {
    if (state.isTeamView) {
      return '${AppPage.companies.path}?scope=team';
    }
    return '${AppPage.companies.path}?representativeId=${Uri.encodeQueryComponent(state.selectedRepId.value)}';
  }

  String _calculateTotalCommissions(List<Commission> commissions) {
    if (commissions.isEmpty) return 'R\$ 0,00';

    var total = commissions.first.amount;
    for (var i = 1; i < commissions.length; i++) {
      total = total + commissions[i].amount;
    }
    return total.formatted;
  }

  Widget _buildMetricCard(
    BuildContext context, {
    required String label,
    required String value,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    final foreground = Theme.of(context).colorScheme.onSurface;
    return Expanded(
      child: Material(
        color: color,
        borderRadius: BorderRadius.circular(28),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(28),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(icon, color: foreground, size: 28),
                    const Spacer(),
                    Icon(
                      Icons.chevron_right_rounded,
                      color: foreground.withValues(alpha: 0.55),
                      size: 20,
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
