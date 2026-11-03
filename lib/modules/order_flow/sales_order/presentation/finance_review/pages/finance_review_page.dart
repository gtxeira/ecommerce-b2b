import 'package:ecommerce_b2b/app/core/di/service_locator.dart';
import 'package:ecommerce_b2b/app/core/routes/order_routes.dart';
import 'package:ecommerce_b2b/app/presentation/widgets/b2b_app_bar.dart';
import 'package:ecommerce_b2b/modules/order_flow/sales_order/model/sales_order.dart';
import 'package:ecommerce_b2b/modules/order_flow/sales_order/presentation/finance_review/cubit/finance_review_cubit.dart';
import 'package:ecommerce_b2b/modules/order_flow/sales_order/presentation/finance_review/widgets/finance_review_order_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

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
                  return FinanceReviewOrderCard(
                    order: order,
                    onOpenDetails: () => _openOrderDetails(context, order),
                    onApprove: () => _showReviewDialog(context, order, true),
                    onReject: () => _showReviewDialog(context, order, false),
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

  void _openOrderDetails(BuildContext context, SalesOrder order) {
    context.push(OrderRoutes.detail(order.id.value), extra: order);
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
                  ? 'Você está prestes a aprovar o pedido #${order.id.displayCode}. O estoque será alocado e o fluxo de expedição iniciado.'
                  : 'Você está prestes a reprovar o pedido #${order.id.displayCode}. O pedido será cancelado no sistema.',
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
