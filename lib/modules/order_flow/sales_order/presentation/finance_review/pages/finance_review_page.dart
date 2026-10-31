import 'package:ecommerce_b2b/app/core/di/service_locator.dart';
import 'package:ecommerce_b2b/app/presentation/widgets/b2b_app_bar.dart';
import 'package:ecommerce_b2b/modules/order_flow/model/enums/order_status.dart';
import 'package:ecommerce_b2b/modules/order_flow/sales_order/model/sales_order.dart';
import 'package:ecommerce_b2b/modules/order_flow/sales_order/presentation/finance_review/cubit/finance_review_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class FinanceReviewPage extends StatelessWidget {
  const FinanceReviewPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return BlocProvider(
      create: (context) => getIt<FinanceReviewCubit>()..loadPendingOrders(),
      child: Scaffold(
        backgroundColor: colorScheme.surface,
        appBar: const B2BAppBar(title: 'Análise Financeira'),
        body: BlocBuilder<FinanceReviewCubit, FinanceReviewState>(
          builder: (context, state) {
            if (state is FinanceReviewLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            if (state is FinanceReviewFailure) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.error_outline_rounded,
                      size: 64,
                      color: colorScheme.error,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Erro ao carregar análises',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(state.message),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: () => context
                          .read<FinanceReviewCubit>()
                          .loadPendingOrders(),
                      child: const Text('Recarregar'),
                    ),
                  ],
                ),
              );
            }

            if (state is FinanceReviewLoaded) {
              if (state.pendingOrders.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.gpp_good_rounded,
                        size: 80,
                        color: colorScheme.primary.withValues(alpha: 0.5),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'Fila de Análise Limpa!',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Todos os pedidos bloqueados ou pendentes já foram revisados.',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.all(20),
                itemCount: state.pendingOrders.length,
                itemBuilder: (context, index) {
                  final order = state.pendingOrders[index];
                  final isBlocked =
                      order.status == OrderStatus.blockedByFinance;
                  final statusColor = isBlocked
                      ? colorScheme.error
                      : colorScheme.tertiary;

                  return Card(
                    margin: const EdgeInsets.only(bottom: 20),
                    elevation: 0,
                    color: colorScheme.surfaceContainerLow,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(28),
                      side: BorderSide(
                        color: colorScheme.outlineVariant.withValues(
                          alpha: 0.3,
                        ),
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Pedido #${order.id.value.substring(0, 8)}',
                                    style: theme.textTheme.titleLarge?.copyWith(
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: -0.5,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Empresa ID: ${order.companyId}',
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: statusColor.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  isBlocked ? 'BLOQUEADO' : 'PENDENTE',
                                  style: TextStyle(
                                    color: statusColor,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const Divider(height: 32),

                          // Detalhes dos Itens do Pedido
                          Text(
                            'Itens do Pedido',
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 12),
                          ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: order.items.length,
                            itemBuilder: (itemCtx, itemIdx) {
                              final item = order.items[itemIdx];
                              return Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 6,
                                ),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        '${item.quantity.value}x Produto #${item.productId.value.substring(0, 8)}',
                                        style: theme.textTheme.bodyMedium,
                                      ),
                                    ),
                                    Text(
                                      item.unitPriceSnapshot.toString(),
                                      style: theme.textTheme.bodyMedium
                                          ?.copyWith(
                                            fontWeight: FontWeight.bold,
                                          ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                          const Divider(height: 32),

                          // Valor Total
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Valor Total a Faturar',
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                order.total.toString(),
                                style: theme.textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.w900,
                                  color: colorScheme.primary,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),

                          // Ações
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: () =>
                                      _showReviewDialog(context, order, false),
                                  icon: const Icon(Icons.cancel_outlined),
                                  label: const Text('REPROVAR CRÉDITO'),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: colorScheme.error,
                                    side: BorderSide(
                                      color: colorScheme.error.withValues(
                                        alpha: 0.5,
                                      ),
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 16,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: () =>
                                      _showReviewDialog(context, order, true),
                                  icon: const Icon(
                                    Icons.check_circle_outline_rounded,
                                  ),
                                  label: const Text('APROVAR'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: colorScheme.primary,
                                    foregroundColor: colorScheme.onPrimary,
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 16,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            }

            return const SizedBox.shrink();
          },
        ),
      ),
    );
  }

  void _showReviewDialog(BuildContext context, SalesOrder order, bool approve) {
    final controller = TextEditingController();
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final parentContext = context; // Mantém referência segura ao context

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        title: Text(approve ? 'Confirmar Aprovação' : 'Confirmar Reprovação'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              approve
                  ? 'Você está prestes a aprovar o pedido #${order.id.value.substring(0, 8)}. O estoque será alocado e o fluxo de expedição iniciado.'
                  : 'Você está prestes a reprovar o pedido #${order.id.value.substring(0, 8)}. O pedido será cancelado no sistema.',
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 20),
            TextField(
              controller: controller,
              decoration: const InputDecoration(
                labelText: 'Justificativa da Decisão',
                hintText: 'Digite o motivo detalhado...',
                border: OutlineInputBorder(),
                alignLabelWithHint: true,
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('CANCELAR'),
          ),
          ElevatedButton(
            onPressed: () {
              if (controller.text.trim().isEmpty) {
                ScaffoldMessenger.of(dialogContext).showSnackBar(
                  const SnackBar(
                    content: Text('Por favor, preencha a justificativa.'),
                  ),
                );
                return;
              }
              if (approve) {
                parentContext.read<FinanceReviewCubit>().approveOrder(
                  order,
                  controller.text,
                );
              } else {
                parentContext.read<FinanceReviewCubit>().rejectOrder(
                  order,
                  controller.text,
                );
              }
              Navigator.pop(dialogContext);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: approve
                  ? colorScheme.primary
                  : colorScheme.error,
              foregroundColor: approve
                  ? colorScheme.onPrimary
                  : colorScheme.onError,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('CONFIRMAR'),
          ),
        ],
      ),
    );
  }
}
