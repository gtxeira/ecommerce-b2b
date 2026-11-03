import 'package:ecommerce_b2b/app/core/format/date_format.dart';
import 'package:ecommerce_b2b/app/core/routes/order_routes.dart';
import 'package:ecommerce_b2b/modules/sales_team/sales_representative/model/commission.dart';
import 'package:ecommerce_b2b/modules/sales_team/sales_representative/presentation/widgets/commission_status_visuals.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Detalhes da comissão com o atalho para o pedido que a gerou.
Future<void> showCommissionDetailsSheet(
  BuildContext context,
  Commission commission, {
  String? representativeName,
}) {
  final router = GoRouter.of(context);

  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
    ),
    builder: (sheetContext) {
      final theme = Theme.of(sheetContext);
      final colorScheme = theme.colorScheme;
      final statusColor = commissionStatusColor(commission.status, colorScheme);
      final repName =
          (representativeName ?? commission.representativeName ?? '').trim();
      final orderId = commission.orderId;

      return SafeArea(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(sheetContext).size.height * 0.85,
          ),
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                Center(
                  child: Container(
                    width: 48,
                    height: 6,
                    decoration: BoxDecoration(
                      color: colorScheme.outlineVariant,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Comissão',
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    Chip(
                      label: Text(commissionStatusLabel(commission.status)),
                      labelStyle: TextStyle(
                        color: statusColor,
                        fontWeight: FontWeight.bold,
                      ),
                      backgroundColor: statusColor.withValues(alpha: 0.12),
                      side: BorderSide.none,
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Text(
                  commission.amount.formatted,
                  style: theme.textTheme.displaySmall?.copyWith(
                    fontWeight: FontWeight.w900,
                    color: colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 20),
                _InfoRow(
                  label: 'Base de cálculo',
                  value: commission.baseAmount.formatted,
                ),
                _InfoRow(label: 'Percentual', value: commission.rate.formatted),
                _InfoRow(
                  label: 'Gerada em',
                  value: formatDateTimeOrDash(commission.createdAt),
                ),
                if (repName.isNotEmpty)
                  _InfoRow(label: 'Representante', value: repName),
                _InfoRow(
                  label: 'Pedido de origem',
                  value: orderId == null || orderId.isEmpty
                      ? 'Sem pedido vinculado'
                      : '#$orderId',
                ),
                if (orderId == null || orderId.isEmpty) ...[
                  const SizedBox(height: 12),
                  Text(
                    'Comissão histórica do seed: não existe um pedido vinculado '
                    'para abrir.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
                const SizedBox(height: 24),
                if (orderId != null && orderId.isNotEmpty)
                  FilledButton.icon(
                    onPressed: () {
                      Navigator.of(sheetContext).pop();
                      router.push(OrderRoutes.detail(orderId));
                    },
                    icon: const Icon(Icons.receipt_long_rounded),
                    label: const Text('Ver pedido'),
                  ),
                const SizedBox(height: 8),
                OutlinedButton(
                  onPressed: () => Navigator.of(sheetContext).pop(),
                  child: const Text('Fechar'),
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 150,
            child: Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
