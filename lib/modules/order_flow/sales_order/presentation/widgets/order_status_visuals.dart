import 'package:ecommerce_b2b/modules/order_flow/model/enums/order_status.dart';
import 'package:flutter/material.dart';

/// Cor de exibição do status do pedido. Fonte única para listas, chips e
/// detalhes, para que o mesmo status não apareça com cores diferentes.
Color orderStatusColor(OrderStatus status, ColorScheme colorScheme) {
  return switch (status) {
    OrderStatus.pendingFinanceApproval => colorScheme.tertiary,
    OrderStatus.blockedByFinance => colorScheme.error,
    OrderStatus.awaitingInfo => Colors.amber.shade800,
    OrderStatus.pickingPacking => colorScheme.primary,
    OrderStatus.inTransit => Colors.orange,
    OrderStatus.delivered => Colors.green,
    OrderStatus.invoiced => Colors.teal,
    OrderStatus.rma => colorScheme.secondary,
    OrderStatus.cancelled => colorScheme.outline,
  };
}

/// Ícone de exibição do status do pedido.
IconData orderStatusIcon(OrderStatus status) {
  return switch (status) {
    OrderStatus.pendingFinanceApproval => Icons.hourglass_empty_rounded,
    OrderStatus.blockedByFinance => Icons.lock_rounded,
    OrderStatus.awaitingInfo => Icons.help_outline_rounded,
    OrderStatus.pickingPacking => Icons.inventory_2_outlined,
    OrderStatus.inTransit => Icons.local_shipping_outlined,
    OrderStatus.delivered => Icons.check_circle_outline_rounded,
    OrderStatus.invoiced => Icons.receipt_long_outlined,
    OrderStatus.rma => Icons.assignment_return_outlined,
    OrderStatus.cancelled => Icons.cancel_outlined,
  };
}

/// Selo compacto com o status do pedido.
class OrderStatusChip extends StatelessWidget {
  const OrderStatusChip({
    super.key,
    required this.status,
    this.showInfoIcon = false,
  });

  final OrderStatus status;

  /// Mostra o ícone de informação quando o status tem uma explicação associada
  /// (bloqueio/aguardando informações). Quem envolve o chip no trigger define o
  /// comportamento de clique.
  final bool showInfoIcon;

  @override
  Widget build(BuildContext context) {
    final color = orderStatusColor(status, Theme.of(context).colorScheme);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            status.label,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
          ),
          if (showInfoIcon) ...[
            const SizedBox(width: 4),
            Icon(Icons.info_outline_rounded, size: 13, color: color),
          ],
        ],
      ),
    );
  }
}
