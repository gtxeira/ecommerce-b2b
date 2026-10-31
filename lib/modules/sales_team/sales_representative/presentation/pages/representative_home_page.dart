import 'package:ecommerce_b2b/app/core/di/service_locator.dart';
import 'package:ecommerce_b2b/app/presentation/widgets/b2b_app_bar.dart';
import 'package:ecommerce_b2b/modules/identity_access/presentation/cubit/auth_cubit.dart';
import 'package:ecommerce_b2b/modules/sales_team/sales_representative/model/commission.dart';
import 'package:ecommerce_b2b/modules/sales_team/sales_representative/presentation/cubit/representative_dashboard_cubit.dart';
import 'package:ecommerce_b2b/modules/shared_kernel/model/common/ids/representative_id.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

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
          getIt<RepresentativeDashboardCubit>()..loadDashboard(session),
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
                onRefresh: () => context
                    .read<RepresentativeDashboardCubit>()
                    .loadDashboard(session, targetRepId: state.selectedRepId),
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
                                          child: DropdownButton<RepresentativeId>(
                                            isExpanded: true,
                                            value: state.selectedRepId,
                                            items: [
                                              DropdownMenuItem(
                                                value: RepresentativeId(
                                                  session.userId.value,
                                                ),
                                                child: const Text(
                                                  'Meu Painel (Pessoal)',
                                                  style: TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ),
                                              ...state.subordinates.map(
                                                (sub) => DropdownMenuItem(
                                                  value: sub.id,
                                                  child: Text(sub.fullName),
                                                ),
                                              ),
                                            ],
                                            onChanged: (newRepId) {
                                              if (newRepId != null) {
                                                context
                                                    .read<
                                                      RepresentativeDashboardCubit
                                                    >()
                                                    .loadDashboard(
                                                      session,
                                                      targetRepId: newRepId,
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
                              state.selectedRepId.value == session.userId.value
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
                                  'Comissões',
                                  _calculateTotalCommissions(state.commissions),
                                  Icons.payments_outlined,
                                  colorScheme.primaryContainer,
                                ),
                                const SizedBox(width: 12),
                                _buildMetricCard(
                                  context,
                                  'Carteira',
                                  '${state.assignments.length} Clientes',
                                  Icons.supervised_user_circle_outlined,
                                  colorScheme.secondaryContainer,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Lista de Comissões Recentes
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
                        child: Text(
                          'Comissões Recentes',
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
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
                            return Card(
                              margin: const EdgeInsets.only(bottom: 8),
                              child: ListTile(
                                leading: CircleAvatar(
                                  backgroundColor:
                                      colorScheme.surfaceContainerHighest,
                                  child: const Icon(Icons.attach_money_rounded),
                                ),
                                title: Text(
                                  'Comissão: ${commission.amount.formatted}',
                                ),
                                subtitle: Text(
                                  'Base: ${commission.baseAmount.formatted} (${commission.rate.formatted})',
                                ),
                                trailing: const Icon(
                                  Icons.chevron_right_rounded,
                                ),
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
                                  'Orçamento #${quote.id.value.substring(0, 8)}',
                                ),
                                subtitle: Text(
                                  'Total: ${quote.total.formatted} - ${quote.status.label}',
                                ),
                                trailing: const Icon(
                                  Icons.chevron_right_rounded,
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

  String _calculateTotalCommissions(List<Commission> commissions) {
    if (commissions.isEmpty) return 'R\$ 0,00';

    var total = commissions.first.amount;
    for (var i = 1; i < commissions.length; i++) {
      total = total + commissions[i].amount;
    }
    return total.formatted;
  }

  Widget _buildMetricCard(
    BuildContext context,
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Expanded(
      child: Card(
        color: color,
        margin: EdgeInsets.zero,
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, size: 28),
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
    );
  }
}
