import 'package:ecommerce_b2b/app/core/format/date_format.dart';
import 'package:ecommerce_b2b/modules/sales_team/sales_representative/model/commission.dart';
import 'package:ecommerce_b2b/modules/sales_team/sales_representative/presentation/widgets/commission_status_visuals.dart';
import 'package:flutter/material.dart';

/// Item de comissão do painel e da página de comissões.
///
/// Sempre navegável: o toque abre o sheet com os detalhes e o link para o
/// pedido que originou a comissão.
class CommissionTile extends StatelessWidget {
  const CommissionTile({
    super.key,
    required this.commission,
    required this.onTap,
    this.representativeName,
    this.margin = const EdgeInsets.only(bottom: 8),
  });

  final Commission commission;
  final VoidCallback onTap;
  final String? representativeName;
  final EdgeInsetsGeometry margin;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final statusColor = commissionStatusColor(commission.status, colorScheme);
    final repName = (representativeName ?? commission.representativeName ?? '')
        .trim();
    final orderId = commission.orderId;

    return Card(
      margin: margin,
      elevation: 0,
      color: colorScheme.surfaceContainerLow,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(Icons.payments_rounded, color: statusColor),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Comissão: ${commission.amount.formatted}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      [
                        'Base: ${commission.baseAmount.formatted} '
                            '(${commission.rate.formatted}) · '
                            '${commissionStatusLabel(commission.status)}',
                        'Gerada em ${formatDateTimeOrDash(commission.createdAt)}',
                        if (repName.isNotEmpty) 'Representante: $repName',
                        orderId == null || orderId.isEmpty
                            ? 'Sem pedido vinculado'
                            : 'Pedido #$orderId',
                      ].join('\n'),
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.chevron_right_rounded),
            ],
          ),
        ),
      ),
    );
  }
}
