import 'dart:async';

import 'package:ecommerce_b2b/app/core/di/service_locator.dart';
import 'package:ecommerce_b2b/app/presentation/widgets/discount_badge.dart';
import 'package:ecommerce_b2b/modules/catalog/price_table/model/price_tier.dart';
import 'package:ecommerce_b2b/modules/catalog/price_table/model/pricing_preview.dart';
import 'package:ecommerce_b2b/modules/catalog/price_table/model/repositories/pricing_repository.dart';
import 'package:ecommerce_b2b/modules/catalog/product/model/product.dart';
import 'package:ecommerce_b2b/modules/catalog/product/presentation/cubit/catalog_cubit.dart';
import 'package:ecommerce_b2b/modules/catalog/product/presentation/cubit/catalog_state.dart';
import 'package:ecommerce_b2b/modules/identity_access/model/user_session.dart';
import 'package:ecommerce_b2b/modules/identity_access/presentation/cubit/auth_cubit.dart';
import 'package:ecommerce_b2b/modules/order_flow/quote/model/enums/quote_status.dart';
import 'package:ecommerce_b2b/modules/order_flow/quote/model/quote.dart';
import 'package:ecommerce_b2b/modules/order_flow/quote/model/quote_item.dart';
import 'package:ecommerce_b2b/modules/order_flow/quote/model/repositories/quote_repository.dart';
import 'package:ecommerce_b2b/modules/shared_kernel/model/common/ids/quote_id.dart';
import 'package:ecommerce_b2b/modules/shared_kernel/model/finance/value_objects/quantity.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';

/// Catálogo somente-leitura para compradores.
///
/// Exibe produtos, variações e as condições de desconto elegíveis para a UF da
/// empresa. A simulação de preço é resolvida pela API; o cliente só apresenta.
class BuyerCatalogPage extends StatelessWidget {
  const BuyerCatalogPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<CatalogCubit>()..loadProducts(),
      child: const _BuyerCatalogView(),
    );
  }
}

class _BuyerCatalogView extends StatefulWidget {
  const _BuyerCatalogView();

  @override
  State<_BuyerCatalogView> createState() => _BuyerCatalogViewState();
}

class _BuyerCatalogViewState extends State<_BuyerCatalogView> {
  final _searchController = TextEditingController();

  List<PriceTier> _priceTiers = const [];
  bool _pricingLoading = true;
  UserSession? _session;

  @override
  void initState() {
    super.initState();
    _loadPriceTiers();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadPriceTiers() async {
    final authState = context.read<AuthCubit>().state;
    if (authState is! AuthAuthenticated ||
        authState.session.companyId == null) {
      setState(() {
        _session = authState is AuthAuthenticated ? authState.session : null;
        _pricingLoading = false;
      });
      return;
    }

    setState(() {
      _session = authState.session;
      _pricingLoading = true;
    });

    try {
      final tiers = await getIt<PricingRepository>().findPriceTiers();
      if (!mounted) return;
      setState(() {
        _priceTiers = tiers;
        _pricingLoading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() => _pricingLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Não foi possível carregar as condições de desconto: $error',
          ),
        ),
      );
    }
  }

  List<PriceTier> _tiersFor(String productId) =>
      _priceTiers.where((tier) => tier.productId == productId).toList();

  Future<void> _refreshAll() async {
    await Future.wait([
      context.read<CatalogCubit>().loadProducts(
        query: _searchController.text.isEmpty ? null : _searchController.text,
      ),
      _loadPriceTiers(),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.canPop() ? context.pop() : context.go('/'),
          tooltip: 'Voltar para Home',
        ),
        title: const Text(
          'Catálogo de Produtos',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(72),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: SearchBar(
              controller: _searchController,
              hintText: 'Pesquisar produtos por nome ou SKU...',
              leading: const Icon(Icons.search),
              trailing: [
                if (_searchController.text.isNotEmpty)
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () {
                      _searchController.clear();
                      context.read<CatalogCubit>().loadProducts();
                    },
                  ),
              ],
              onChanged: (query) {
                setState(() {}); // Atualiza botão X
                context.read<CatalogCubit>().loadProducts(
                  query: query.isEmpty ? null : query,
                );
              },
              elevation: const WidgetStatePropertyAll(0),
            ),
          ),
        ),
      ),
      body: BlocBuilder<CatalogCubit, CatalogState>(
        builder: (context, state) {
          if (state is CatalogLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is CatalogError) {
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
                    'Erro ao carregar catálogo',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(state.message, textAlign: TextAlign.center),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () =>
                        context.read<CatalogCubit>().loadProducts(),
                    icon: const Icon(Icons.refresh_rounded),
                    label: const Text('Tentar Novamente'),
                  ),
                ],
              ),
            );
          }

          if (state is CatalogLoaded) {
            final products = state.products.where((p) => p.active).toList();

            if (products.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.inventory_2_outlined,
                      size: 80,
                      color: colorScheme.primary.withValues(alpha: 0.4),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Nenhum produto encontrado',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Tente ajustar a busca ou contate seu representante.',
                    ),
                  ],
                ),
              );
            }

            return RefreshIndicator(
              onRefresh: _refreshAll,
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: products.length + (_pricingLoading ? 1 : 0),
                itemBuilder: (context, index) {
                  if (_pricingLoading && index == products.length) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(vertical: 16),
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }

                  final product = products[index];
                  return _ProductCard(
                    product: product,
                    tiers: _tiersFor(product.id.value),
                    session: _session,
                  );
                },
              ),
            );
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }
}

class _ProductCard extends StatefulWidget {
  final Product product;
  final List<PriceTier> tiers;
  final UserSession? session;

  const _ProductCard({
    required this.product,
    required this.tiers,
    required this.session,
  });

  @override
  State<_ProductCard> createState() => _ProductCardState();
}

class _ProductCardState extends State<_ProductCard> {
  final _quantityController = TextEditingController(text: '1');
  int _quantity = 1;
  PricingPreview? _preview;
  bool _loading = false;
  String? _error;
  Timer? _debounce;

  PriceTier? get _primaryTier =>
      widget.tiers.isEmpty ? null : widget.tiers.first;

  @override
  void initState() {
    super.initState();
    if (_primaryTier != null) {
      _schedulePreview();
    }
  }

  @override
  void didUpdateWidget(covariant _ProductCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.tiers.isEmpty && widget.tiers.isNotEmpty) {
      _schedulePreview();
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _quantityController.dispose();
    super.dispose();
  }

  void _schedulePreview() {
    _debounce?.cancel();
    final tier = _primaryTier;
    final session = widget.session;
    if (tier == null || session?.companyId == null || _quantity < 1) {
      if (mounted) {
        setState(() {
          _preview = null;
          _loading = false;
        });
      }
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });
    _debounce = Timer(const Duration(milliseconds: 300), _loadPreview);
  }

  Future<void> _loadPreview() async {
    final tier = _primaryTier;
    final session = widget.session;
    final companyId = session?.companyId;
    if (tier == null || companyId == null || _quantity < 1) return;

    try {
      final preview = await getIt<PricingRepository>().preview(
        companyId: companyId.value,
        productId: widget.product.id.value,
        quantity: _quantity,
        priceTableId: tier.priceTableId,
      );

      if (!mounted) return;
      setState(() {
        _preview = preview;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _preview = null;
        _error = error.toString();
        _loading = false;
      });
    }
  }

  void _setQuantity(int value) {
    final normalized = value < 1 ? 1 : value;
    _quantityController.text = normalized.toString();
    _quantityController.selection = TextSelection.collapsed(
      offset: _quantityController.text.length,
    );
    setState(() => _quantity = normalized);
    _schedulePreview();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final tiers = widget.tiers;
    final basePrice = widget.product.basePrice;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 0,
      color: colorScheme.surfaceContainerLow,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.all(16),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
        leading: Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            color: colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Icon(
            Icons.inventory_2_outlined,
            color: colorScheme.onPrimaryContainer,
          ),
        ),
        title: Text(
          widget.product.name,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(
            'SKU: ${widget.product.sku}'
            '${tiers.isEmpty ? '' : ' • atacado a partir de ${tiers.first.minQuantity} un.'}',
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              basePrice.formatted,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w900,
                color: colorScheme.primary,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              '${widget.product.variants.length} variações',
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        children: [
          if (widget.product.description.isNotEmpty) ...[
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                widget.product.description,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
          if (tiers.isNotEmpty) ...[
            _DiscountConditions(tiers: tiers),
            const SizedBox(height: 16),
            _buildSimulator(theme, colorScheme),
            const SizedBox(height: 16),
          ],
          if (widget.product.variants.isEmpty)
            const Text('Nenhuma variação disponível.')
          else ...[
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Variações disponíveis',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 8),
            ...widget.product.variants.map(
              (v) => Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest.withValues(
                    alpha: 0.5,
                  ),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'SKU: ${v.variantSku}',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                          Text(
                            [
                              if (v.color.isNotEmpty) v.color,
                              if (v.size.isNotEmpty) v.size,
                              if (v.voltage.isNotEmpty) v.voltage,
                            ].join(' · '),
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      v.sameAsParent
                          ? basePrice.formatted
                          : (v.price?.formatted ?? '—'),
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        color: colorScheme.primary,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: tiers.isEmpty
                ? () => _showContactDialog(context)
                : () => _requestQuote(context),
            icon: const Icon(Icons.support_agent_rounded),
            label: const Text('SOLICITAR ORÇAMENTO'),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(44),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSimulator(ThemeData theme, ColorScheme colorScheme) {
    final preview = _preview;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Simule a quantidade',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              IconButton(
                onPressed: _quantity > 1
                    ? () => _setQuantity(_quantity - 1)
                    : null,
                icon: const Icon(Icons.remove_circle_outline),
                tooltip: 'Diminuir',
              ),
              SizedBox(
                width: 64,
                child: TextField(
                  controller: _quantityController,
                  textAlign: TextAlign.center,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    isDense: true,
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (value) {
                    final parsed = int.tryParse(value) ?? 1;
                    setState(() => _quantity = parsed < 1 ? 1 : parsed);
                    _schedulePreview();
                  },
                ),
              ),
              IconButton(
                onPressed: () => _setQuantity(_quantity + 1),
                icon: const Icon(Icons.add_circle_outline),
                tooltip: 'Aumentar',
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'unidades',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (_loading)
            const LinearProgressIndicator()
          else if (_error != null)
            Text(
              'Não foi possível simular: $_error',
              style: TextStyle(color: colorScheme.error, fontSize: 12),
            )
          else if (preview != null) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Preço unitário', style: theme.textTheme.bodyMedium),
                Text(
                  preview.unitPrice.formatted,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                    color: colorScheme.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Total', style: theme.textTheme.bodyMedium),
                Text(
                  preview.subtotal.formatted,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            if (preview.toExplanation() != null) ...[
              const SizedBox(height: 8),
              DiscountBadge(pricing: preview.toExplanation()!),
            ],
            if (preview.nextTier != null) ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.amber.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.amber.shade200),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.trending_down_rounded,
                      color: Colors.amber.shade900,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Faltam ${preview.nextTier!.unitsMissing} un. para '
                        '${preview.nextTier!.unitPrice.formatted}/un. '
                        '(economize ${preview.nextTier!.savingsPerUnit.formatted}/un.)',
                        style: TextStyle(
                          color: Colors.amber.shade900,
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }

  Future<void> _requestQuote(BuildContext context) async {
    final preview = _preview;
    final session = widget.session;
    final tier = _primaryTier;
    final companyId = session?.companyId;
    final userId = session?.userId;
    if (preview == null ||
        companyId == null ||
        userId == null ||
        tier == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Aguarde a simulação do preço.')),
      );
      return;
    }

    final explanation = preview.toExplanation();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Solicitar orçamento'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Produto: ${widget.product.name}'),
            const SizedBox(height: 4),
            Text('Quantidade: $_quantity un.'),
            const SizedBox(height: 4),
            Text('Preço unitário: ${preview.unitPrice.formatted}'),
            const SizedBox(height: 4),
            Text('Total dos itens: ${preview.subtotal.formatted}'),
            if (explanation != null) ...[
              const SizedBox(height: 12),
              DiscountBadge(pricing: explanation),
              const SizedBox(height: 8),
              Text(
                'Condição: ${tier.rangeLabel} em ${tier.locationLabel}.',
                style: Theme.of(dialogContext).textTheme.bodySmall,
              ),
            ],
            const SizedBox(height: 12),
            const Text(
              'O orçamento será enviado ao seu representante para confirmação.',
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
            child: const Text('Enviar solicitação'),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) return;

    try {
      await getIt<QuoteRepository>().save(
        Quote(
          id: QuoteId(const Uuid().v4()),
          companyId: companyId.value,
          representativeId: userId.value,
          status: QuoteStatus.sent,
          items: [
            QuoteItem(
              productId: widget.product.id,
              quantity: Quantity.create(_quantity).getOrThrow(),
              unitPrice: preview.unitPrice,
              priceTableId: tier.priceTableId,
              pricing: explanation,
            ),
          ],
        ),
      );

      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Solicitação de orçamento enviada!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Não foi possível solicitar o orçamento: $error'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  void _showContactDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('Solicitar Orçamento'),
        content: Text(
          'Para solicitar um orçamento do produto "${widget.product.name}", entre em contato com seu representante comercial ou aguarde que ele abra um pedido por você.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('ENTENDIDO'),
          ),
        ],
      ),
    );
  }
}

class _DiscountConditions extends StatelessWidget {
  final List<PriceTier> tiers;

  const _DiscountConditions({required this.tiers});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.percent_rounded, size: 18, color: Colors.green.shade700),
            const SizedBox(width: 6),
            Text(
              'Condições de desconto',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ...tiers.map(
          (tier) => Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.green.shade100),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${tier.priceTableName} • ${tier.rangeLabel} • ${tier.locationLabel}',
                        style: TextStyle(
                          color: Colors.green.shade900,
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${tier.unitPrice.formatted}/un. — economize '
                        '${tier.discountPerUnit.formatted}/un.',
                        style: TextStyle(
                          color: Colors.green.shade900,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.green.shade700,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    '−${tier.discountPercentage.toStringAsFixed(2).replaceAll('.', ',')}%',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 11,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        Text(
          'Preço de catálogo: ${tiers.first.referenceUnitPrice.formatted}/un. '
          'A condição vale para ${tiers.first.locationLabel}.',
          style: theme.textTheme.bodySmall?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}
