import 'package:ecommerce_b2b/app/core/format/date_format.dart';
import 'package:ecommerce_b2b/app/core/format/display_labels.dart';
import 'package:ecommerce_b2b/modules/order_flow/model/enums/order_status.dart';
import 'package:ecommerce_b2b/modules/order_flow/sales_order/model/enums/finance_decision.dart';
import 'package:ecommerce_b2b/modules/order_flow/sales_order/model/finance_review.dart';
import 'package:ecommerce_b2b/modules/order_flow/sales_order/model/sales_order.dart';
import 'package:flutter/material.dart';

/// Explicação exibida para pedidos bloqueados ou aguardando informações.
///
/// O motivo "de negócio" vem da análise financeira quando ela existe. Pedidos
/// bloqueados automaticamente pela política de crédito nascem sem `FinanceReview`;
/// nesse caso usamos um texto padrão para não deixar o usuário sem explicação.
class OrderBlockExplanation {
  const OrderBlockExplanation({
    required this.title,
    required this.reason,
    required this.isBlocked,
    required this.hasFinanceReview,
    this.review,
  });

  final String title;
  final String reason;
  final bool isBlocked;
  final bool hasFinanceReview;
  final FinanceReview? review;

  static const String blockedFallbackReason =
      'O valor total do pedido ultrapassou o limite de crédito disponível da '
      'empresa. O pedido aguarda análise manual do Financeiro.';

  static const String awaitingInfoFallbackReason =
      'O Financeiro solicitou informações adicionais para prosseguir com a '
      'análise deste pedido.';

  /// Devolve `null` quando o pedido não está bloqueado nem aguardando informações.
  static OrderBlockExplanation? fromOrder(SalesOrder order) {
    final isBlocked = order.status == OrderStatus.blockedByFinance;
    final isAwaiting = order.status == OrderStatus.awaitingInfo;
    if (!isBlocked && !isAwaiting) return null;

    final review = order.financeReview;
    final storedReason = review?.justification.trim() ?? '';
    final hasFinanceReview = review != null && storedReason.isNotEmpty;
    final reason = hasFinanceReview
        ? storedReason
        : isBlocked
        ? blockedFallbackReason
        : awaitingInfoFallbackReason;

    return OrderBlockExplanation(
      title: isBlocked
          ? 'Pedido bloqueado pelo Financeiro'
          : 'Informações solicitadas pelo Financeiro',
      reason: reason,
      isBlocked: isBlocked,
      hasFinanceReview: hasFinanceReview,
      review: review,
    );
  }

  /// Texto curto usado no tooltip. O dialog mostra os metadados completos.
  String get tooltipMessage => reason;

  String get sourceLabel =>
      review != null ? 'Análise financeira' : 'Política de crédito';

  FinanceDecision? get decision => review?.decision;

  String? get reviewerLabel {
    final value = review;
    if (value == null) return null;

    final name = (value.reviewerName ?? '').trim();
    final role = displayRole(value.reviewerRole);
    if (name.isEmpty && role == null && value.reviewerId.isEmpty) return null;
    if (value.reviewerId.isEmpty) {
      if (name.isEmpty) return role;
      return role == null ? name : '$name ($role)';
    }
    return personLabel(
      name: value.reviewerName,
      role: value.reviewerRole,
      id: value.reviewerId,
    );
  }

  DateTime? get reviewedAt => review?.reviewedAt;
}

/// Abre o dialog com a explicação completa do bloqueio.
Future<void> showOrderBlockExplanationDialog(
  BuildContext context,
  SalesOrder order,
) {
  final explanation = OrderBlockExplanation.fromOrder(order);
  if (explanation == null) return Future<void>.value();

  final theme = Theme.of(context);
  final colorScheme = theme.colorScheme;
  final accent = explanation.isBlocked
      ? colorScheme.error
      : Colors.amber.shade800;

  return showDialog<void>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      title: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            explanation.isBlocked
                ? Icons.lock_rounded
                : Icons.help_outline_rounded,
            color: accent,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              explanation.title,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(explanation.reason, style: theme.textTheme.bodyMedium),
            const SizedBox(height: 20),
            _ExplanationMeta(
              icon: Icons.source_outlined,
              label: 'Origem',
              value: explanation.sourceLabel,
            ),
            _ExplanationMeta(
              icon: Icons.credit_card_outlined,
              label: 'Crédito',
              value: order.creditStatus.label,
            ),
            if (explanation.decision != null)
              _ExplanationMeta(
                icon: Icons.fact_check_outlined,
                label: 'Decisão',
                value: explanation.decision!.label,
              ),
            if (explanation.reviewerLabel != null)
              _ExplanationMeta(
                icon: Icons.person_outline_rounded,
                label: 'Analista',
                value: explanation.reviewerLabel!,
              ),
            if (explanation.reviewedAt != null)
              _ExplanationMeta(
                icon: Icons.schedule_rounded,
                label: 'Analisado em',
                value: formatDateTime(explanation.reviewedAt!),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext),
          child: const Text('Entendi'),
        ),
      ],
    ),
  );
}

class _ExplanationMeta extends StatelessWidget {
  const _ExplanationMeta({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: colorScheme.onSurfaceVariant),
          const SizedBox(width: 8),
          Expanded(
            child: Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: '$label: ',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  TextSpan(text: value),
                ],
              ),
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Torna um widget (badge, texto de status etc.) clicável e com tooltip.
class OrderBlockExplanationTrigger extends StatelessWidget {
  const OrderBlockExplanationTrigger({
    super.key,
    required this.order,
    required this.child,
    this.showInfoIcon = false,
    this.infoIconSize = 16,
    this.infoIconColor,
  });

  final SalesOrder order;
  final Widget child;
  final bool showInfoIcon;
  final double infoIconSize;
  final Color? infoIconColor;

  @override
  Widget build(BuildContext context) {
    final explanation = OrderBlockExplanation.fromOrder(order);
    if (explanation == null) return child;

    final content = showInfoIcon
        ? Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              child,
              const SizedBox(width: 4),
              Icon(
                Icons.info_outline_rounded,
                size: infoIconSize,
                color: infoIconColor ?? Theme.of(context).colorScheme.primary,
              ),
            ],
          )
        : child;

    return Tooltip(
      message: explanation.tooltipMessage,
      waitDuration: const Duration(milliseconds: 350),
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => showOrderBlockExplanationDialog(context, order),
          child: Semantics(
            button: true,
            label: 'Explicar bloqueio do pedido',
            child: content,
          ),
        ),
      ),
    );
  }
}

/// Ícone compacto de informação para listas que exibem apenas o texto do status.
class OrderBlockInfoIcon extends StatelessWidget {
  const OrderBlockInfoIcon({
    super.key,
    required this.order,
    this.size = 18,
    this.color,
  });

  final SalesOrder order;
  final double size;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final explanation = OrderBlockExplanation.fromOrder(order);
    if (explanation == null) return const SizedBox.shrink();

    return Tooltip(
      message: explanation.tooltipMessage,
      waitDuration: const Duration(milliseconds: 350),
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: Semantics(
          button: true,
          label: 'Explicar bloqueio do pedido',
          child: InkResponse(
            onTap: () => showOrderBlockExplanationDialog(context, order),
            radius: size + 6,
            child: Padding(
              padding: const EdgeInsets.all(4),
              child: Icon(
                Icons.info_outline_rounded,
                size: size,
                color: color ?? Theme.of(context).colorScheme.primary,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Bloco destacado exibido no detalhe do pedido.
class OrderBlockExplanationCard extends StatelessWidget {
  const OrderBlockExplanationCard({super.key, required this.order});

  final SalesOrder order;

  @override
  Widget build(BuildContext context) {
    final explanation = OrderBlockExplanation.fromOrder(order);
    if (explanation == null) return const SizedBox.shrink();

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final accent = explanation.isBlocked
        ? colorScheme.error
        : Colors.amber.shade800;
    final background = explanation.isBlocked
        ? colorScheme.errorContainer.withValues(alpha: 0.35)
        : colorScheme.tertiaryContainer.withValues(alpha: 0.45);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: accent.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                explanation.isBlocked
                    ? Icons.lock_rounded
                    : Icons.help_outline_rounded,
                color: accent,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  explanation.title,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w900,
                    color: accent,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(explanation.reason, style: theme.textTheme.bodyMedium),
          const SizedBox(height: 12),
          Wrap(
            spacing: 16,
            runSpacing: 8,
            children: [
              _CardMeta(
                icon: Icons.source_outlined,
                text: explanation.sourceLabel,
              ),
              _CardMeta(
                icon: Icons.credit_card_outlined,
                text: 'Crédito: ${order.creditStatus.label}',
              ),
              if (explanation.reviewerLabel != null)
                _CardMeta(
                  icon: Icons.person_outline_rounded,
                  text: explanation.reviewerLabel!,
                ),
              if (explanation.reviewedAt != null)
                _CardMeta(
                  icon: Icons.schedule_rounded,
                  text: formatDateTime(explanation.reviewedAt!),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CardMeta extends StatelessWidget {
  const _CardMeta({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: colorScheme.onSurfaceVariant),
        const SizedBox(width: 4),
        Text(
          text,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
