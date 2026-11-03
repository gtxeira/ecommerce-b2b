import 'package:ecommerce_b2b/modules/catalog/price_table/model/pricing_explanation.dart';
import 'package:flutter/material.dart';

/// Selo compacto de desconto. O detalhe fica no tooltip (desktop) e no toque
/// (mobile), para não poluir a linha do item.
class DiscountBadge extends StatelessWidget {
  final PricingExplanation pricing;
  final bool compact;

  const DiscountBadge({super.key, required this.pricing, this.compact = false});

  @override
  Widget build(BuildContext context) {
    final percentage = _formatPercentage(pricing.discountPercentage);

    return Tooltip(
      message: explanationText(pricing),
      child: ActionChip(
        avatar: Icon(
          Icons.local_offer_outlined,
          size: 16,
          color: Colors.green.shade800,
        ),
        label: Text(
          compact ? '−$percentage%' : 'Desconto $percentage%',
          style: TextStyle(
            color: Colors.green.shade900,
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
        ),
        backgroundColor: Colors.green.shade50,
        side: BorderSide(color: Colors.green.shade200),
        visualDensity: VisualDensity.compact,
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        onPressed: () => showPricingExplanation(context, pricing),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
        labelPadding: const EdgeInsets.symmetric(horizontal: 2),
        padding: const EdgeInsets.symmetric(horizontal: 6),
      ),
    );
  }
}

String explanationText(PricingExplanation pricing) =>
    '${pricing.priceTableName}: ${pricing.rangeLabel} em ${pricing.locationLabel}. '
    'Catálogo ${pricing.referenceUnitPrice.formatted} → economia de '
    '${pricing.discountPerUnit.formatted}/un. '
    '(${_formatPercentage(pricing.discountPercentage)}%).';

Future<void> showPricingExplanation(
  BuildContext context,
  PricingExplanation pricing,
) {
  final theme = Theme.of(context);

  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
    ),
    builder: (sheetContext) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 48,
                height: 6,
                decoration: BoxDecoration(
                  color: theme.colorScheme.outlineVariant,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Icon(Icons.local_offer_outlined, color: Colors.green.shade700),
                const SizedBox(width: 8),
                Text(
                  'Por que este desconto?',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              explanationText(pricing),
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 20),
            _row('Tabela', pricing.priceTableName),
            _row('Faixa', pricing.rangeLabel),
            _row('Local', pricing.locationLabel),
            _row('Preço de catálogo', pricing.referenceUnitPrice.formatted),
            _row('Desconto por unidade', pricing.discountPerUnit.formatted),
            _row('Desconto total', pricing.discountTotal.formatted),
            _row(
              'Percentual',
              '${_formatPercentage(pricing.discountPercentage)}%',
            ),
          ],
        ),
      ),
    ),
  );
}

Widget _row(String label, String value) => Padding(
  padding: const EdgeInsets.symmetric(vertical: 4),
  child: Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      Text(label),
      const SizedBox(width: 12),
      Flexible(
        child: Text(
          value,
          textAlign: TextAlign.end,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
    ],
  ),
);

String _formatPercentage(double value) {
  final fixed = value.toStringAsFixed(2);
  final trimmed = fixed.replaceFirst(RegExp(r'0+$'), '');
  return trimmed.endsWith(',')
      ? trimmed.substring(0, trimmed.length - 1)
      : trimmed.replaceAll('.', ',');
}
