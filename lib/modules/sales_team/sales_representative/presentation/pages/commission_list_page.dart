import 'package:ecommerce_b2b/app/core/di/service_locator.dart';
import 'package:ecommerce_b2b/app/presentation/widgets/b2b_app_bar.dart';
import 'package:ecommerce_b2b/modules/identity_access/model/user_session.dart';
import 'package:ecommerce_b2b/modules/identity_access/presentation/cubit/auth_cubit.dart';
import 'package:ecommerce_b2b/modules/sales_team/sales_representative/model/commission.dart';
import 'package:ecommerce_b2b/modules/sales_team/sales_representative/presentation/cubit/commission_list_cubit.dart';
import 'package:ecommerce_b2b/modules/sales_team/sales_representative/presentation/utils/commission_permissions.dart';
import 'package:ecommerce_b2b/modules/sales_team/sales_representative/presentation/widgets/commission_details_sheet.dart';
import 'package:ecommerce_b2b/modules/sales_team/sales_representative/presentation/widgets/commission_tile.dart';
import 'package:ecommerce_b2b/modules/shared_kernel/model/common/ids/representative_id.dart';
import 'package:ecommerce_b2b/modules/shared_kernel/model/finance/value_objects/money.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

const _teamScopeValue = '__team__';

class CommissionListPage extends StatelessWidget {
  const CommissionListPage({
    super.key,
    this.initialRepresentativeId,
    this.initialTeamView,
  });

  final String? initialRepresentativeId;

  /// Quando nulo, o supervisor abre no consolidado e o representante no pessoal.
  final bool? initialTeamView;

  @override
  Widget build(BuildContext context) {
    final authState = context.watch<AuthCubit>().state;
    if (authState is! AuthAuthenticated) {
      return const Center(child: CircularProgressIndicator());
    }

    final session = authState.session;

    return BlocProvider(
      create: (context) => getIt<CommissionListCubit>()
        ..load(
          session,
          targetRepId: initialRepresentativeId == null
              ? null
              : RepresentativeId(initialRepresentativeId!),
          teamView: initialTeamView ?? session.isSupervisor,
        ),
      child: Scaffold(
        appBar: const B2BAppBar(title: 'Comissões'),
        body: BlocBuilder<CommissionListCubit, CommissionListState>(
          builder: (context, state) {
            if (state is CommissionListLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            if (state is CommissionListFailure) {
              return Center(
                child: Text(
                  state.message,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              );
            }

            if (state is CommissionListLoaded) {
              return RefreshIndicator(
                onRefresh: () => context.read<CommissionListCubit>().load(
                  session,
                  targetRepId: state.selectedRepId,
                  teamView: state.isTeamView,
                ),
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                  children: [
                    if (session.isSupervisor && state.subordinates.isNotEmpty)
                      _ScopeSelector(
                        session: session,
                        state: state,
                        onChanged: (value) {
                          if (value == _teamScopeValue) {
                            context.read<CommissionListCubit>().load(
                              session,
                              teamView: true,
                            );
                          } else {
                            context.read<CommissionListCubit>().load(
                              session,
                              targetRepId: RepresentativeId(value),
                            );
                          }
                        },
                      ),
                    const SizedBox(height: 8),
                    _SummaryHeader(state: state),
                    const SizedBox(height: 16),
                    if (state.commissions.isEmpty)
                      const Padding(
                        padding: EdgeInsets.all(32),
                        child: Center(
                          child: Text('Nenhuma comissão registrada.'),
                        ),
                      )
                    else
                      ...state.commissions.map((commission) {
                        final allowedStatuses = allowedCommissionStatusActions(
                          session,
                          commission,
                        );
                        return CommissionTile(
                          commission: commission,
                          representativeName: commission.representativeName,
                          onTap: () => showCommissionDetailsSheet(
                            context,
                            commission,
                            representativeName: commission.representativeName,
                            allowedStatuses: allowedStatuses,
                            onStatusChange: allowedStatuses.isEmpty
                                ? null
                                : (target) async {
                                    final error = await context
                                        .read<CommissionListCubit>()
                                        .updateStatus(
                                          session,
                                          commission,
                                          target,
                                        );
                                    if (context.mounted && error != null) {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(content: Text(error)),
                                      );
                                    }
                                    return error;
                                  },
                          ),
                        );
                      }),
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
}

class _ScopeSelector extends StatelessWidget {
  const _ScopeSelector({
    required this.session,
    required this.state,
    required this.onChanged,
  });

  final UserSession session;
  final CommissionListLoaded state;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final currentValue = state.isTeamView
        ? _teamScopeValue
        : state.selectedRepId.value;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          children: [
            Icon(
              Icons.supervised_user_circle_rounded,
              color: colorScheme.primary,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
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
                      value: currentValue,
                      items: [
                        DropdownMenuItem(
                          value: _teamScopeValue,
                          child: const Text(
                            'Toda a Equipe (Consolidado)',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                        DropdownMenuItem(
                          value: session.userId.value,
                          child: const Text('Meu Painel (Pessoal)'),
                        ),
                        ...state.subordinates.map(
                          (sub) => DropdownMenuItem(
                            value: sub.id.value,
                            child: Text(sub.fullName),
                          ),
                        ),
                      ],
                      onChanged: (value) {
                        if (value != null) onChanged(value);
                      },
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryHeader extends StatelessWidget {
  const _SummaryHeader({required this.state});

  final CommissionListLoaded state;

  @override
  Widget build(BuildContext context) {
    final total = _total(state.commissions);
    return Card(
      color: Theme.of(context).colorScheme.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            const Icon(Icons.payments_outlined, size: 28),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    total.formatted,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  Text(
                    state.isTeamView
                        ? 'Total consolidado · ${state.commissions.length} comissões'
                        : '${state.selectedRepName} · ${state.commissions.length} comissões',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Money _total(List<Commission> commissions) {
    if (commissions.isEmpty) return Money.create(0).getOrThrow();
    var total = commissions.first.amount;
    for (var i = 1; i < commissions.length; i++) {
      total = total + commissions[i].amount;
    }
    return total;
  }
}
