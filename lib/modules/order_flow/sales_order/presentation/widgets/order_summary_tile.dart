import 'package:ecommerce_b2b/app/core/format/date_format.dart';
import 'package:ecommerce_b2b/modules/order_flow/sales_order/model/sales_order.dart';
import 'package:ecommerce_b2b/modules/order_flow/sales_order/presentation/widgets/order_status_visuals.dart';
import 'package:flutter/material.dart';

/// Item de lista de pedido. Sempre navegável: quem não tem destino não deve
/// usar este widget (o chevron é a promessa de que o toque faz algo).
class OrderSummaryTile extends StatelessWidget {
  const OrderSummaryTile({
    super.key,
    required this.order,
    required this.onTap,
    this.companyName,
    this.margin = const EdgeInsets.only(bottom: 12),
  });

  final SalesOrder order;
  final VoidCallback onTap;

  /// Nome fantasia da empresa. Quando ausente, a linha é omitida.
  final String? companyName;

  final EdgeInsetsGeometry margin;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final statusColor = orderStatusColor(order.status, colorScheme);

    return Card(
      margin: margin,
      elevation: 0,
      color: colorScheme.surfaceContainerLow,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: statusColor.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Icon(orderStatusIcon(order.status), color: statusColor),
        ),
        title: Text(
          'Pedido #${order.id.displayCode}',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          [
            'Status: ${order.status.label}',
            if (companyName != null) 'Empresa: $companyName',
            'Total: ${order.total.formatted}',
            'Última atividade: ${formatDateTimeOrDash(order.activityAt)}',
          ].join('\n'),
        ),
        isThreeLine: true,
        trailing: const Icon(Icons.chevron_right_rounded),
        onTap: onTap,
      ),
    );
  }
}
