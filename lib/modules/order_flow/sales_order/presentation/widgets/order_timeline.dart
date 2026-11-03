import 'package:ecommerce_b2b/app/core/format/date_format.dart';
import 'package:ecommerce_b2b/modules/order_flow/model/enums/order_status.dart';
import 'package:ecommerce_b2b/modules/order_flow/sales_order/model/enums/finance_decision.dart';
import 'package:ecommerce_b2b/modules/order_flow/sales_order/model/order_timeline_entry.dart';
import 'package:flutter/material.dart';

/// Histórico do pedido em forma de linha do tempo, do evento mais recente para
/// o mais antigo.
///
/// Widget puro: recebe as entradas e os estados de carga/erro. A mesma instância
/// é usada na seção do detalhe e no bottom sheet da AppBar.
class OrderTimeline extends StatelessWidget {
  const OrderTimeline({
    super.key,
    required this.entries,
    this.loading = false,
    this.error,
    this.onRetry,
  });

  final List<OrderTimelineEntry> entries;
  final bool loading;
  final String? error;
  final Future<void> Function()? onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final sorted = [...entries]..sort(_byOccurredAtDesc);

    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      color: colorScheme.surfaceContainerLow,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.history_rounded, color: colorScheme.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Histórico do pedido',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                if (sorted.isNotEmpty)
                  Text(
                    '${sorted.length} ${sorted.length == 1 ? 'evento' : 'eventos'}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            if (loading && sorted.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
              )
            else if (error != null && sorted.isEmpty)
              _TimelineError(error: error!, onRetry: onRetry)
            else if (sorted.isEmpty)
              Text(
                'Sem eventos registrados.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              )
            else
              ...sorted.indexed.map(
                (item) => _TimelineRow(
                  entry: item.$2,
                  isLast: item.$1 == sorted.length - 1,
                ),
              ),
          ],
        ),
      ),
    );
  }

  static int _byOccurredAtDesc(OrderTimelineEntry a, OrderTimelineEntry b) {
    final aDate = a.occurredAt;
    final bDate = b.occurredAt;
    if (aDate == null && bDate == null) return 0;
    if (aDate == null) return 1;
    if (bDate == null) return -1;
    return bDate.compareTo(aDate);
  }
}

class _TimelineRow extends StatelessWidget {
  const _TimelineRow({required this.entry, required this.isLast});

  final OrderTimelineEntry entry;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final color = _color(colorScheme);
    final derivedBlockNote =
        entry.toStatus == OrderStatus.blockedByFinance &&
            (entry.note == null || entry.note!.trim().isEmpty)
        ? 'Bloqueio automático por análise de crédito; aguardando revisão do Financeiro.'
        : null;
    final details = [
      entry.details,
      ?derivedBlockNote,
    ].where((value) => value.isNotEmpty).join(' · ');

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 28,
            child: Column(
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(_icon(), size: 16, color: color),
                ),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 2,
                      color: colorScheme.outlineVariant,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    entry.title,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (details.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(details, style: theme.textTheme.bodySmall),
                    ),
                  const SizedBox(height: 2),
                  Text(
                    [
                      formatDateTimeOrDash(entry.occurredAt),
                      if (entry.actorLabel != null) entry.actorLabel!,
                    ].join(' · '),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  IconData _icon() => switch (entry.type) {
    OrderTimelineEventType.created => Icons.add_circle_outline_rounded,
    OrderTimelineEventType.statusChanged => Icons.swap_horiz_rounded,
    OrderTimelineEventType.financeReviewed => Icons.fact_check_outlined,
    OrderTimelineEventType.unknown => Icons.circle_outlined,
  };

  Color _color(ColorScheme colorScheme) => switch (entry.type) {
    OrderTimelineEventType.created => colorScheme.primary,
    OrderTimelineEventType.statusChanged => colorScheme.tertiary,
    OrderTimelineEventType.financeReviewed => switch (entry.decision) {
      FinanceDecision.approved => Colors.green.shade700,
      FinanceDecision.rejected => colorScheme.error,
      FinanceDecision.requestMoreInfo || null => Colors.orange.shade800,
    },
    OrderTimelineEventType.unknown => colorScheme.outline,
  };
}

class _TimelineError extends StatelessWidget {
  const _TimelineError({required this.error, this.onRetry});

  final String error;
  final Future<void> Function()? onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Não foi possível carregar o histórico.',
          style: theme.textTheme.bodyMedium,
        ),
        const SizedBox(height: 4),
        Text(
          error,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        if (onRetry != null) ...[
          const SizedBox(height: 8),
          TextButton.icon(
            onPressed: () => onRetry!(),
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Tentar novamente'),
          ),
        ],
      ],
    );
  }
}
