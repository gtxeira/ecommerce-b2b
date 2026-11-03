import 'dart:async';

import 'package:ecommerce_b2b/app/core/di/service_locator.dart';
import 'package:ecommerce_b2b/app/core/format/display_labels.dart';
import 'package:ecommerce_b2b/app/core/routes/quote_routes.dart';
import 'package:ecommerce_b2b/app/presentation/widgets/discount_badge.dart';
import 'package:ecommerce_b2b/modules/catalog/price_table/model/price_tier.dart';
import 'package:ecommerce_b2b/modules/catalog/price_table/model/pricing_preview.dart';
import 'package:ecommerce_b2b/modules/catalog/price_table/model/repositories/pricing_repository.dart';
import 'package:ecommerce_b2b/modules/catalog/product/model/product.dart';
import 'package:ecommerce_b2b/modules/catalog/product/model/product_variant.dart';
import 'package:ecommerce_b2b/modules/catalog/product/presentation/cubit/catalog_cubit.dart';
import 'package:ecommerce_b2b/modules/catalog/product/presentation/cubit/catalog_state.dart';
import 'package:ecommerce_b2b/modules/identity_access/model/user_session.dart';
import 'package:ecommerce_b2b/modules/identity_access/presentation/cubit/auth_cubit.dart';
import 'package:ecommerce_b2b/modules/order_flow/quote/model/enums/quote_status.dart';
import 'package:ecommerce_b2b/modules/order_flow/quote/model/quote.dart';
import 'package:ecommerce_b2b/modules/order_flow/quote/model/repositories/quote_repository.dart';
import 'package:ecommerce_b2b/modules/order_flow/quote/presentation/cubit/buyer_quote_cart_cubit.dart';
import 'package:ecommerce_b2b/modules/order_flow/quote/presentation/cubit/buyer_quote_cart_state.dart';
import 'package:ecommerce_b2b/modules/shared_kernel/model/common/ids/quote_id.dart';
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
  final _cart = BuyerQuoteCartCubit();

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
    _cart.close();
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
      floatingActionButton: _buildCartButton(context),
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
                    key: ValueKey(product.id.value),
                    product: product,
                    tiers: _tiersFor(product.id.value),
                    session: _session,
                    onAddToCart: (variant, quantity, tier, preview) =>
                        _addToCart(product, variant, quantity, tier, preview),
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

  Widget _buildCartButton(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return BlocBuilder<BuyerQuoteCartCubit, BuyerQuoteCartState>(
      bloc: _cart,
      builder: (context, state) {
        if (state.isEmpty) return const SizedBox.shrink();

        return FloatingActionButton.extended(
          onPressed: _showCartSheet,
          backgroundColor: colorScheme.primary,
          foregroundColor: colorScheme.onPrimary,
          icon: Badge(
            label: Text('${state.itemCount}'),
            child: const Icon(Icons.shopping_cart_checkout_rounded),
          ),
          label: Text('Orçamento • ${state.total.formatted}'),
        );
      },
    );
  }

  Future<void> _addToCart(
    Product product,
    ProductVariant? variant,
    int quantity,
    PriceTier? tier,
    PricingPreview preview,
  ) async {
    final companyId = _session?.companyId;
    if (companyId == null) {
      _showError('Sessão sem empresa associada.');
      return;
    }

    final variantId = variant?.id.value;
    final existing = _cart.state.itemFor(product.id, variantId: variantId);
    if (existing == null) {
      _cart.addOrReplace(_cartItem(product, variant, quantity, tier, preview));
      _notifyAdded(quantity);
      return;
    }

    // A mesma combinação produto+variante entra uma vez só: soma a quantidade e
    // reprecia pela faixa da quantidade total.
    try {
      final mergedQuantity = existing.quantity + quantity;
      final mergedPreview = await getIt<PricingRepository>().preview(
        companyId: companyId.value,
        productId: product.id.value,
        quantity: mergedQuantity,
        priceTableId: tier?.priceTableId,
        variantId: variantId,
      );
      if (!mounted) return;

      _cart.addOrReplace(
        _cartItem(product, variant, mergedQuantity, tier, mergedPreview),
      );
      _notifyAdded(quantity);
    } catch (error) {
      if (!mounted) return;
      _showError('Não foi possível atualizar o orçamento: $error');
    }
  }

  BuyerQuoteCartItem _cartItem(
    Product product,
    ProductVariant? variant,
    int quantity,
    PriceTier? tier,
    PricingPreview preview,
  ) => BuyerQuoteCartItem(
    productId: product.id,
    variantId: variant?.id.value,
    productName: product.name,
    productSku: product.sku,
    variantSku: variant?.variantSku,
    variantLabel: variant?.label,
    quantity: quantity,
    priceTableId: tier?.priceTableId,
    preview: preview,
  );

  void _notifyAdded(int quantity) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$quantity un. adicionadas ao orçamento.'),
        action: SnackBarAction(
          label: 'Ver orçamento',
          onPressed: _showCartSheet,
        ),
      ),
    );
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Theme.of(context).colorScheme.error,
      ),
    );
  }

  Future<void> _showCartSheet() async {
    final session = _session;
    final submitted = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (sheetContext) => _BuyerQuoteCartSheet(
        cart: _cart,
        onSubmit: session == null ? null : () => _submitCart(session),
      ),
    );

    if (submitted == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Orçamento enviado ao seu representante.'),
          action: SnackBarAction(
            label: 'Ver orçamentos',
            onPressed: () => context.push(QuoteRoutes.buyerList),
          ),
        ),
      );
    }
  }

  Future<void> _submitCart(UserSession session) async {
    final items = _cart.state.items;
    final companyId = session.companyId;
    if (items.isEmpty || companyId == null) return;

    await getIt<QuoteRepository>().save(
      Quote(
        id: QuoteId(const Uuid().v4()),
        companyId: companyId.value,
        // O dono do orçamento é o representante da empresa (definido no backend).
        // O comprador não é representante e não deve se passar por um.
        representativeId: null,
        status: QuoteStatus.sent,
        items: items.map((item) => item.toQuoteItem()).toList(),
      ),
    );

    if (mounted) _cart.clear();
  }
}

/// Bottom sheet de revisão e envio do carrinho do comprador.
///
/// Recebe o cubit em vez de um snapshot para que remover um item atualize a
/// lista e o total sem fechar o sheet.
class _BuyerQuoteCartSheet extends StatefulWidget {
  final BuyerQuoteCartCubit cart;

  /// Nulo quando a sessão não tem empresa; nesse caso o envio fica desabilitado.
  final Future<void> Function()? onSubmit;

  const _BuyerQuoteCartSheet({required this.cart, this.onSubmit});

  @override
  State<_BuyerQuoteCartSheet> createState() => _BuyerQuoteCartSheetState();
}

class _BuyerQuoteCartSheetState extends State<_BuyerQuoteCartSheet> {
  bool _submitting = false;
  String? _error;

  Future<void> _submit() async {
    final onSubmit = widget.onSubmit;
    if (onSubmit == null || _submitting) return;

    setState(() {
      _submitting = true;
      _error = null;
    });

    try {
      await onSubmit();
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _submitting = false;
        _error = 'Não foi possível enviar o orçamento: $error';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return BlocBuilder<BuyerQuoteCartCubit, BuyerQuoteCartState>(
      bloc: widget.cart,
      builder: (context, state) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
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
                const SizedBox(height: 16),
                Text(
                  'Orçamento (${state.itemCount} un.)',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Revise os itens antes de enviar ao seu representante.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 16),
                if (state.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 24),
                    child: Text(
                      'Seu orçamento está vazio.',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyMedium,
                    ),
                  )
                else
                  ConstrainedBox(
                    constraints: BoxConstraints(
                      maxHeight: MediaQuery.of(context).size.height * 0.45,
                    ),
                    child: ListView.separated(
                      shrinkWrap: true,
                      itemCount: state.items.length,
                      separatorBuilder: (context, index) =>
                          const Divider(height: 20),
                      itemBuilder: (context, index) {
                        final item = state.items[index];
                        return Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '${item.quantity}x ${productLabel(name: item.productName, sku: item.productSku, variantLabel: item.variantLabel, variantSku: item.variantSku, id: item.productId.value)}',
                                    style: theme.textTheme.bodyMedium,
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '${item.preview.unitPrice.formatted} / un.',
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Text(
                              item.subtotal.formatted,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            IconButton(
                              tooltip: 'Remover',
                              onPressed: _submitting
                                  ? null
                                  : () => widget.cart.remove(
                                      item.productId,
                                      variantId: item.variantId,
                                    ),
                              icon: const Icon(Icons.delete_outline_rounded),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                const Divider(height: 24),
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
                      state.total.formatted,
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w900,
                        color: colorScheme.primary,
                      ),
                    ),
                  ],
                ),
                if (_error != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    _error!,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.error,
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: state.isEmpty || _submitting ? null : _submit,
                  icon: _submitting
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.send_rounded),
                  label: Text(
                    _submitting ? 'Enviando...' : 'Solicitar orçamento',
                  ),
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(52),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _ProductCard extends StatefulWidget {
  final Product product;
  final List<PriceTier> tiers;
  final UserSession? session;
  final void Function(
    ProductVariant? variant,
    int quantity,
    PriceTier? tier,
    PricingPreview preview,
  )
  onAddToCart;

  const _ProductCard({
    super.key,
    required this.product,
    required this.tiers,
    required this.session,
    required this.onAddToCart,
  });

  @override
  State<_ProductCard> createState() => _ProductCardState();
}

class _ProductCardState extends State<_ProductCard> {
  final _quantityController = TextEditingController(text: '1');
  int _quantity = 1;
  ProductVariant? _selectedVariant;
  PricingPreview? _preview;
  bool _loading = false;
  String? _error;
  Timer? _debounce;

  /// Evita que uma resposta antiga de simulação sobrescreva a variante/quantidade
  /// atuais quando o usuário troca de opção rapidamente.
  int _previewRequest = 0;

  /// Faixas que valem para a variante selecionada: regra específica da variante
  /// quando existe; senão a regra de produto (que também se aplica a ela).
  List<PriceTier> get _applicableTiers =>
      applicableTiers(widget.tiers, variantId: _selectedVariant?.id.value);

  PriceTier? get _primaryTier =>
      _applicableTiers.isEmpty ? null : _applicableTiers.first;

  @override
  void initState() {
    super.initState();
    if (widget.product.variants.isNotEmpty) {
      _selectedVariant = widget.product.variants.first;
    }
    _schedulePreview();
  }

  @override
  void didUpdateWidget(covariant _ProductCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.product.id != widget.product.id) {
      _selectedVariant = widget.product.variants.isEmpty
          ? null
          : widget.product.variants.first;
      _quantity = 1;
      _quantityController.text = '1';
      _schedulePreview();
    } else if (oldWidget.tiers.isEmpty && widget.tiers.isNotEmpty) {
      _schedulePreview();
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _quantityController.dispose();
    super.dispose();
  }

  void _selectVariant(ProductVariant variant) {
    if (_selectedVariant?.id == variant.id) return;
    setState(() => _selectedVariant = variant);
    _schedulePreview();
  }

  void _schedulePreview() {
    _debounce?.cancel();
    final companyId = widget.session?.companyId;
    if (companyId == null || _quantity < 1) {
      if (mounted) {
        setState(() {
          _preview = null;
          _loading = false;
        });
      }
      return;
    }

    final request = ++_previewRequest;
    setState(() {
      _loading = true;
      _error = null;
    });
    _debounce = Timer(
      const Duration(milliseconds: 300),
      () => _loadPreview(request),
    );
  }

  Future<void> _loadPreview(int request) async {
    final companyId = widget.session?.companyId;
    if (companyId == null || _quantity < 1) return;

    try {
      final preview = await getIt<PricingRepository>().preview(
        companyId: companyId.value,
        productId: widget.product.id.value,
        quantity: _quantity,
        priceTableId: _primaryTier?.priceTableId,
        variantId: _selectedVariant?.id.value,
      );

      if (!mounted || request != _previewRequest) return;
      setState(() {
        _preview = preview;
        _loading = false;
      });
    } catch (error) {
      if (!mounted || request != _previewRequest) return;
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
    final tiers = _applicableTiers;
    final basePrice = widget.product.basePrice;
    final variants = widget.product.variants;

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
            '${tiers.isEmpty ? ' • preço de catálogo' : ' • atacado a partir de ${tiers.first.minQuantity} un.'}',
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
              variants.isEmpty
                  ? 'sem variação'
                  : '${variants.length} variações',
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
          if (variants.isNotEmpty) ...[
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Escolha a variação',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: variants.map((variant) {
                final selected = _selectedVariant?.id == variant.id;
                final price = variant.sameAsParent
                    ? basePrice
                    : (variant.price ?? basePrice);
                return ChoiceChip(
                  selected: selected,
                  onSelected: (_) => _selectVariant(variant),
                  label: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          variant.label.isEmpty
                              ? variant.variantSku
                              : variant.label,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                        Text(
                          '${variant.variantSku} • ${price.formatted}',
                          style: TextStyle(
                            fontSize: 11,
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
          ] else
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Produto sem variação.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ),
          if (tiers.isNotEmpty) ...[
            _DiscountConditions(tiers: tiers),
            const SizedBox(height: 16),
          ],
          _buildSimulator(theme, colorScheme),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: () => _addToCart(context),
            icon: const Icon(Icons.add_shopping_cart_rounded),
            label: const Text('ADICIONAR AO ORÇAMENTO'),
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
          if (_applicableTiers.isEmpty) ...[
            const SizedBox(height: 4),
            Text(
              'Preço de catálogo: não há faixa de desconto elegível para esta empresa.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
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

  void _addToCart(BuildContext context) {
    final preview = _preview;
    if (preview == null || _loading) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Aguarde a simulação do preço.')),
      );
      return;
    }

    widget.onAddToCart(_selectedVariant, _quantity, _primaryTier, preview);
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
