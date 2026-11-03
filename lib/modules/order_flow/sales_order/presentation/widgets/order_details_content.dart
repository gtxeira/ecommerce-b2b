import 'package:ecommerce_b2b/app/core/format/date_format.dart';
import 'package:ecommerce_b2b/app/core/format/display_labels.dart';
import 'package:ecommerce_b2b/app/presentation/widgets/discount_badge.dart';
import 'package:ecommerce_b2b/modules/order_flow/model/enums/order_status.dart';
import 'package:ecommerce_b2b/modules/order_flow/sales_order/model/sales_order.dart';
import 'package:ecommerce_b2b/modules/order_flow/sales_order/presentation/widgets/order_block_explanation.dart';
import 'package:ecommerce_b2b/modules/order_flow/sales_order/presentation/widgets/order_status_visuals.dart';
import 'package:ecommerce_b2b/modules/shared_kernel/model/finance/value_objects/money.dart';
import 'package:flutter/material.dart';

/// Conteúdo de um pedido, compartilhado entre a página de detalhe e o bottom
/// sheet usado nas listas rápidas.
class OrderDetailsContent extends StatelessWidget {
  const OrderDetailsContent({super.key, required this.order});

  final SalesOrder order;

  /// Soma dos itens, sem o frete. `null` quando o pedido não tem itens.
  Money? get _itemsTotal {
    Money? total;
    for (final item in order.items) {
      total = total == null ? item.subtotal : total + item.subtotal;
    }
    return total;
  }

  /// Economia congelada nos itens. `null` quando nenhum item teve desconto.
  Money? get _savings {
    var cents = 0;
    for (final item in order.items) {
      cents += item.pricing?.discountTotal.amountInCents ?? 0;
    }
    if (cents == 0) return null;
    return Money.create(cents / 100).getOrThrow();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final itemsTotal = _itemsTotal;
    final savings = _savings;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 12,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            OrderBlockExplanationTrigger(
              order: order,
              showInfoIcon: false,
              child: OrderStatusChip(
                status: order.status,
                showInfoIcon:
                    order.status == OrderStatus.blockedByFinance ||
                    order.status == OrderStatus.awaitingInfo,
              ),
            ),
            Text(
              'Crédito: ${order.creditStatus.label}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        if (OrderBlockExplanation.fromOrder(order) != null) ...[
          const SizedBox(height: 12),
          OrderBlockExplanationCard(order: order),
        ],
        const SizedBox(height: 8),
        Text(
          'Empresa: ${order.companyId == null ? '-' : companyLabel(tradeName: order.companyName, legalName: order.companyLegalName, id: order.companyId!)}',
          style: theme.textTheme.bodySmall?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
        if (order.createdAt != null)
          Text(
            'Criado em: ${formatDateTime(order.createdAt!)}',
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        if (order.lastActivityAt != null)
          Text(
            'Última atividade: ${formatDateTime(order.lastActivityAt!)}',
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        const Divider(height: 32),
        Text(
          'Itens do Pedido',
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        if (order.items.isEmpty)
          Text(
            'Nenhum item registrado.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          )
        else
          ...order.items.map(
            (item) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      '${item.quantity.value}x ${productLabel(name: item.productName, sku: item.productSku, variantLabel: item.variantLabel, variantSku: item.variantSku, id: item.productId.value)}',
                      style: theme.textTheme.bodyMedium,
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        item.subtotal.formatted,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '${item.unitPriceSnapshot.formatted} / un.',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                      if (item.pricing != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: DiscountBadge(
                            pricing: item.pricing!,
                            compact: true,
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        const Divider(height: 32),
        _amountRow(context, 'Itens', itemsTotal?.formatted ?? '-'),
        const SizedBox(height: 4),
        _amountRow(context, 'Frete', order.shippingCost.formatted),
        if (savings != null) ...[
          const SizedBox(height: 4),
          _amountRow(context, 'Economia', savings.formatted, highlight: true),
        ],
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Total',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              order.total.formatted,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w900,
                color: colorScheme.primary,
              ),
            ),
          ],
        ),
        if (order.financeReview != null) ...[
          const Divider(height: 32),
          Text(
            'Análise Financeira',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Decisão: ${order.financeReview!.decision.label}',
            style: theme.textTheme.bodyMedium,
          ),
          if (order.financeReview!.reviewerId.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                'Analista: ${personLabel(name: order.financeReview!.reviewerName, role: order.financeReview!.reviewerRole, id: order.financeReview!.reviewerId)}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          if (order.financeReview!.justification.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                'Justificativa: ${order.financeReview!.justification}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ),
        ],
      ],
    );
  }

  Widget _amountRow(
    BuildContext context,
    String label,
    String value, {
    bool highlight = false,
  }) {
    final theme = Theme.of(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: theme.textTheme.bodyMedium),
        Text(
          value,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: highlight ? FontWeight.bold : null,
            color: highlight ? Colors.green.shade800 : null,
          ),
        ),
      ],
    );
  }
}

/// Abre o resumo do pedido em um bottom sheet, sem sair da tela atual.
Future<void> showOrderDetailsSheet(BuildContext context, SalesOrder order) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
    ),
    builder: (sheetContext) => SafeArea(
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
                    color: Theme.of(sheetContext).colorScheme.outlineVariant,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Pedido #${order.id.displayCode}',
                style: Theme.of(sheetContext).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 16),
              OrderDetailsContent(order: order),
            ],
          ),
        ),
      ),
    ),
  );
}
