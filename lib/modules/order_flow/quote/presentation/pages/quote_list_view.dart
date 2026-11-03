import 'package:ecommerce_b2b/app/core/format/date_format.dart';
import 'package:ecommerce_b2b/app/core/format/display_labels.dart';
import 'package:ecommerce_b2b/app/core/routes/order_routes.dart';
import 'package:ecommerce_b2b/app/presentation/widgets/discount_badge.dart';
import 'package:ecommerce_b2b/modules/identity_access/model/user_session.dart';
import 'package:ecommerce_b2b/modules/identity_access/presentation/cubit/auth_cubit.dart';
import 'package:ecommerce_b2b/modules/order_flow/model/enums/order_status.dart';
import 'package:ecommerce_b2b/modules/order_flow/quote/model/enums/quote_status.dart';
import 'package:ecommerce_b2b/modules/order_flow/quote/model/quote.dart';
import 'package:ecommerce_b2b/modules/order_flow/quote/model/quote_item.dart';
import 'package:ecommerce_b2b/modules/order_flow/quote/presentation/cubit/quote_cubit.dart';
import 'package:ecommerce_b2b/modules/order_flow/quote/presentation/cubit/quote_state.dart';
import 'package:ecommerce_b2b/modules/shared_kernel/model/finance/value_objects/money.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

class QuoteListView extends StatefulWidget {
  const QuoteListView({super.key});

  @override
  State<QuoteListView> createState() => _QuoteListViewState();
}

class _QuoteListViewState extends State<QuoteListView> {
  @override
  void initState() {
    super.initState();
    _loadQuotes();
  }

  void _loadQuotes() {
    final authState = context.read<AuthCubit>().state;
    if (authState is AuthAuthenticated) {
      context.read<QuoteCubit>().loadQuotes(authState.session);
    }
  }

  Future<void> _convertQuote(
    BuildContext context,
    Quote quote,
    UserSession session,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Converter em pedido'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Orçamento #${quote.id.displayCode}'),
            const SizedBox(height: 4),
            Text('Total: ${quote.total.formatted}'),
            const SizedBox(height: 12),
            const Text(
              'O pedido pode nascer bloqueado se o valor exceder o limite de crédito da empresa.',
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Converter'),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) return;

    try {
      final order = await context.read<QuoteCubit>().convertQuote(quote, session);
      if (!context.mounted) return;

      final waitingFinance = order.status == OrderStatus.blockedByFinance ||
          order.status == OrderStatus.pendingFinanceApproval ||
          order.status == OrderStatus.awaitingInfo;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            waitingFinance
                ? 'Pedido criado e enviado para análise financeira.'
                : 'Pedido criado em separação e embalagem.',
          ),
          action: SnackBarAction(
            label: 'Ver pedido',
            onPressed: () => context.push(OrderRoutes.detail(order.id.value)),
          ),
        ),
      );
    } catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Não foi possível converter o orçamento: $error'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final authState = context.read<AuthCubit>().state;
    final session = authState is AuthAuthenticated ? authState.session : null;

    return BlocBuilder<QuoteCubit, QuoteState>(
      builder: (context, state) {
        if (state is QuoteLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (state is QuoteError) {
          return Center(child: Text(state.message));
        }

        if (state is QuoteLoaded) {
          final quotes = state.quotes;
          if (quotes.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.history_rounded,
                    size: 64,
                    color: colorScheme.outline,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Nenhum orçamento encontrado.',
                    style: theme.textTheme.titleMedium,
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async => _loadQuotes(),
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: quotes.length,
              itemBuilder: (context, index) {
                final quote = quotes[index];
                final savings = quoteSavings(quote);
                final canConvert = session != null
                    && (session.isRepresentative || session.isAdmin)
                    && quote.status == QuoteStatus.sent;

                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  elevation: 0,
                  color: colorScheme.surfaceContainerLow,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ListTile(
                    title: Text(
                      'Orçamento #${quote.id.displayCode}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      [
                        'Status: ${quote.status.label} • Itens: ${quote.items.length}',
                        'Total: ${quote.total.formatted}',
                        if (savings != null)
                          'Desconto aplicado: ${savings.formatted}',
                        if (quote.companyId != null)
                          'Empresa: ${companyLabel(tradeName: quote.companyName, legalName: quote.companyLegalName, id: quote.companyId!)}',
                        if (quote.representativeId != null)
                          'Representante: ${personLabel(name: quote.representativeName, role: 'Representative', id: quote.representativeId!)}',
                        if (quote.expiresAt != null)
                          'Válido até ${formatDate(quote.expiresAt!)}',
                      ].join('\n'),
                    ),
                    isThreeLine: true,
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: () => showQuoteDetailsSheet(
                      context,
                      quote,
                      onConvert: canConvert
                          ? () => _convertQuote(context, quote, session)
                          : null,
                    ),
                  ),
                );
              },
            ),
          );
        }

        return const SizedBox.shrink();
      },
    );
  }
}

/// Soma da economia congelada nos itens. Nulo quando nenhum item tem desconto.
Money? quoteSavings(Quote quote) {
  var cents = 0;
  for (final item in quote.items) {
    cents += item.pricing?.discountTotal.amountInCents ?? 0;
  }
  if (cents == 0) return null;
  return Money.create(cents / 100).getOrThrow();
}

Future<void> showQuoteDetailsSheet(
  BuildContext context,
  Quote quote, {
  Future<void> Function()? onConvert,
}) {
  final theme = Theme.of(context);
  final colorScheme = theme.colorScheme;
  final savings = quoteSavings(quote);

  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
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
                    color: colorScheme.outlineVariant,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Orçamento #${quote.id.displayCode}',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Status: ${quote.status.label}'
                '${quote.companyId == null ? '' : ' • ${companyLabel(tradeName: quote.companyName, legalName: quote.companyLegalName, id: quote.companyId!)}'}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              if (quote.expiresAt != null) ...[
                const SizedBox(height: 4),
                Text(
                  'Válido até ${formatDate(quote.expiresAt!)}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
              const Divider(height: 32),
              Text(
                'Itens',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              if (quote.items.isEmpty)
                const Text('Nenhum item registrado.')
              else
                ...quote.items.map((item) => _quoteItemRow(context, item)),
              const Divider(height: 32),
              _amountRow(
                context,
                'Itens',
                (quote.total - quote.shippingCost).formatted,
              ),
              const SizedBox(height: 4),
              _amountRow(context, 'Frete', quote.shippingCost.formatted),
              if (savings != null) ...[
                const SizedBox(height: 4),
                _amountRow(
                  context,
                  'Economia',
                  savings.formatted,
                  highlight: true,
                ),
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
                    quote.total.formatted,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w900,
                      color: colorScheme.primary,
                    ),
                  ),
                ],
              ),
              if (onConvert != null) ...[
                const SizedBox(height: 20),
                FilledButton.icon(
                  onPressed: () {
                    Navigator.of(sheetContext).pop();
                    onConvert();
                  },
                  icon: const Icon(Icons.shopping_cart_checkout_rounded),
                  label: const Text('Converter em pedido'),
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(52),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    ),
  );
}

Widget _quoteItemRow(BuildContext context, QuoteItem item) {
  final theme = Theme.of(context);
  final colorScheme = theme.colorScheme;

  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 6),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${item.quantity.value}x produto #${item.productId.value}',
                style: theme.textTheme.bodyMedium,
              ),
              if (item.pricing != null)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: DiscountBadge(pricing: item.pricing!, compact: true),
                ),
            ],
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
              '${item.unitPrice.formatted} / un.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ],
    ),
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
