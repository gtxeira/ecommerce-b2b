import 'dart:async';

import 'package:ecommerce_b2b/app/core/di/service_locator.dart';
import 'package:ecommerce_b2b/app/presentation/widgets/discount_badge.dart';
import 'package:ecommerce_b2b/modules/catalog/price_table/model/price_table.dart';
import 'package:ecommerce_b2b/modules/catalog/price_table/model/pricing_preview.dart';
import 'package:ecommerce_b2b/modules/catalog/price_table/model/repositories/price_table_repository.dart';
import 'package:ecommerce_b2b/modules/catalog/price_table/model/repositories/pricing_repository.dart';
import 'package:ecommerce_b2b/modules/catalog/product/model/product.dart';
import 'package:ecommerce_b2b/modules/catalog/product/model/product_variant.dart';
import 'package:ecommerce_b2b/modules/catalog/product/model/repositories/product_repository.dart';
import 'package:ecommerce_b2b/modules/customer_management/company/model/company.dart';
import 'package:ecommerce_b2b/modules/customer_management/company/model/repositories/company_repository.dart';
import 'package:ecommerce_b2b/modules/identity_access/presentation/cubit/auth_cubit.dart';
import 'package:ecommerce_b2b/modules/order_flow/quote/model/quote.dart';
import 'package:ecommerce_b2b/modules/order_flow/quote/model/quote_item.dart';
import 'package:ecommerce_b2b/modules/order_flow/quote/model/enums/quote_status.dart';
import 'package:ecommerce_b2b/modules/order_flow/quote/presentation/cubit/quote_cubit.dart';
import 'package:ecommerce_b2b/modules/shared_kernel/model/common/ids/quote_id.dart';
import 'package:ecommerce_b2b/modules/shared_kernel/model/finance/value_objects/quantity.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';

class CreateQuoteView extends StatefulWidget {
  const CreateQuoteView({super.key});

  @override
  State<CreateQuoteView> createState() => _CreateQuoteViewState();
}

class _CreateQuoteViewState extends State<CreateQuoteView> {
  final List<QuoteItem> _items = [];
  List<Product> _availableProducts = [];
  List<Company> _companies = [];
  List<PriceTable> _priceTables = [];
  Company? _selectedCompany;
  PriceTable? _selectedPriceTable;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  Future<void> _loadProducts() async {
    final products = await getIt<ProductRepository>().getAll();
    List<Company> companies = [];
    List<PriceTable> priceTables = [];
    try {
      companies = await getIt<CompanyRepository>().findAll();
    } catch (_) {
      companies = [];
    }
    try {
      priceTables = await getIt<PriceTableRepository>().findAll();
    } catch (_) {
      priceTables = [];
    }

    if (!mounted) return;
    setState(() {
      _availableProducts = products;
      _companies = companies;
      _priceTables = priceTables;
      _selectedCompany = _companies.isNotEmpty ? _companies.first : null;
      _selectedPriceTable = _priceTables.isNotEmpty ? _priceTables.first : null;
      _isLoading = false;
    });
  }

  void _addItem(
    Product product,
    ProductVariant? variant,
    int quantity,
    PricingPreview preview,
  ) {
    setState(() {
      _items.add(
        QuoteItem(
          productId: product.id,
          variantId: variant?.id.value,
          variantSku: variant?.variantSku,
          variantLabel: variant?.label,
          quantity: Quantity.create(quantity).getOrThrow(),
          unitPrice: preview.unitPrice,
          priceTableId: _selectedPriceTable?.id.value,
          pricing: preview.toExplanation(),
        ),
      );
    });
  }

  // Empresa e tabela definem a UF e a regra; trocar qualquer uma delas invalida
  // o preço já mostrado nos itens.
  Future<void> _repriceItems() async {
    final company = _selectedCompany;
    final table = _selectedPriceTable;
    if (company == null || table == null || _items.isEmpty) return;

    setState(() => _isLoading = true);
    try {
      final repriced = <QuoteItem>[];
      for (final item in _items) {
        final preview = await getIt<PricingRepository>().preview(
          companyId: company.id.value,
          productId: item.productId.value,
          quantity: item.quantity.value,
          priceTableId: table.id.value,
          variantId: item.variantId,
        );

        repriced.add(
          QuoteItem(
            productId: item.productId,
            variantId: item.variantId,
            variantSku: item.variantSku,
            variantLabel: item.variantLabel,
            quantity: item.quantity,
            unitPrice: preview.unitPrice,
            priceTableId: table.id.value,
            pricing: preview.toExplanation(),
          ),
        );
      }

      if (!mounted) return;
      setState(() {
        _items
          ..clear()
          ..addAll(repriced);
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Não foi possível repreficar os itens: $error')),
      );
    }
  }

  Future<void> _saveQuote() async {
    if (_items.isEmpty) return;

    final authState = context.read<AuthCubit>().state;
    if (authState is! AuthAuthenticated) return;

    if (_selectedCompany == null || _selectedPriceTable == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Selecione a empresa e a tabela de preços.'),
        ),
      );
      return;
    }

    final quote = Quote(
      id: QuoteId(const Uuid().v4()),
      companyId: _selectedCompany!.id.value,
      // A API define o dono pelo representante da empresa; o Admin não tem vínculo de
      // representante, então mandar o próprio id aqui só criaria um dado falso.
      representativeId: authState.session.isRepresentative
          ? authState.session.userId.value
          : null,
      status: QuoteStatus.sent,
      items: _items,
    );

    try {
      await context.read<QuoteCubit>().saveQuote(quote, authState.session);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao salvar orçamento: $error')),
      );
      return;
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Orçamento salvo com sucesso!')),
      );

      setState(() {
        _items.clear();
      });

      final tabController = DefaultTabController.of(context);
      tabController.animateTo(1);
    }
  }

  Widget _buildSelectors(ThemeData theme, ColorScheme colorScheme) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Column(
        children: [
          DropdownButtonFormField<Company>(
            initialValue: _selectedCompany,
            decoration: const InputDecoration(
              labelText: 'Empresa *',
              prefixIcon: Icon(Icons.business_rounded),
            ),
            items: _companies
                .map(
                  (company) => DropdownMenuItem(
                    value: company,
                    child: Text(company.tradeName),
                  ),
                )
                .toList(),
            onChanged: (company) {
              setState(() => _selectedCompany = company);
              unawaited(_repriceItems());
            },
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<PriceTable>(
            initialValue: _selectedPriceTable,
            decoration: const InputDecoration(
              labelText: 'Tabela de preços *',
              prefixIcon: Icon(Icons.sell_rounded),
            ),
            items: _priceTables
                .map(
                  (table) =>
                      DropdownMenuItem(value: table, child: Text(table.name)),
                )
                .toList(),
            onChanged: (table) {
              setState(() => _selectedPriceTable = table);
              unawaited(_repriceItems());
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _availableProducts.isEmpty ? null : _showAddProductDialog,
        icon: const Icon(Icons.add_shopping_cart_rounded),
        label: const Text('Adicionar Item'),
      ),
      bottomNavigationBar: _items.isNotEmpty
          ? Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: colorScheme.surface,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, -5),
                  ),
                ],
              ),
              child: ElevatedButton.icon(
                onPressed: _saveQuote,
                icon: const Icon(Icons.save_rounded),
                label: const Text('Salvar Orçamento'),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size.fromHeight(56),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            )
          : null,
      body: Column(
        children: [
          _buildSelectors(theme, colorScheme),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _loadProducts,
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _items.isEmpty
                  ? ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.all(16.0),
                      children: [
                        Card(
                          elevation: 0,
                          color: colorScheme.surfaceContainerLow,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(32.0),
                            child: Column(
                              children: [
                                Icon(
                                  Icons.receipt_long_rounded,
                                  size: 56,
                                  color: colorScheme.primary,
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'Nenhum item adicionado ao orçamento.',
                                  textAlign: TextAlign.center,
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Use o botão “Adicionar Item” para incluir produtos e montar a proposta.',
                                  textAlign: TextAlign.center,
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    )
                  : ListView.builder(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.all(16.0),
                      itemCount: _items.length,
                      itemBuilder: (context, index) {
                        final item = _items[index];
                        final product = _availableProducts.firstWhere(
                          (p) => p.id == item.productId,
                        );

                        return Card(
                          margin: const EdgeInsets.only(bottom: 12.0),
                          elevation: 0,
                          color: colorScheme.surfaceContainerLow,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            leading: Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: colorScheme.primaryContainer,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                Icons.inventory_2_rounded,
                                color: colorScheme.onPrimaryContainer,
                              ),
                            ),
                            title: Text(
                              product.name,
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            subtitle: Padding(
                              padding: const EdgeInsets.only(top: 4.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (item.variantLabel != null &&
                                      item.variantLabel!.isNotEmpty)
                                    Text(
                                      'Variação: ${item.variantLabel}'
                                      '${item.variantSku == null ? '' : ' • ${item.variantSku}'}',
                                    ),
                                  Text(
                                    'Qtd: ${item.quantity.value} • Unitário: ${item.unitPrice.formatted} • Total: ${item.subtotal.formatted}',
                                  ),
                                  if (item.pricing != null)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 6),
                                      child: DiscountBadge(
                                        pricing: item.pricing!,
                                        compact: true,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            trailing: IconButton(
                              tooltip: 'Remover item',
                              icon: const Icon(Icons.delete_outline_rounded),
                              onPressed: () =>
                                  setState(() => _items.removeAt(index)),
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ),
        ],
      ),
    );
  }

  void _showAddProductDialog() {
    final company = _selectedCompany;
    final table = _selectedPriceTable;
    if (company == null || table == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Selecione a empresa e a tabela de preços primeiro.'),
        ),
      );
      return;
    }

    showDialog<_QuoteItemDraft>(
      context: context,
      builder: (_) => _AddQuoteItemDialog(
        products: _availableProducts,
        company: company,
        priceTable: table,
      ),
    ).then((draft) {
      if (draft != null) {
        _addItem(draft.product, draft.variant, draft.quantity, draft.preview);
      }
    });
  }
}

class _QuoteItemDraft {
  final Product product;
  final ProductVariant? variant;
  final int quantity;
  final PricingPreview preview;

  const _QuoteItemDraft({
    required this.product,
    required this.variant,
    required this.quantity,
    required this.preview,
  });
}

/// Diálogo de inclusão com prévia de preço. A simulção é feita pela API:
/// o cliente não replica a precedência de tabela/variante/UF.
class _AddQuoteItemDialog extends StatefulWidget {
  final List<Product> products;
  final Company company;
  final PriceTable priceTable;

  const _AddQuoteItemDialog({
    required this.products,
    required this.company,
    required this.priceTable,
  });

  @override
  State<_AddQuoteItemDialog> createState() => _AddQuoteItemDialogState();
}

class _AddQuoteItemDialogState extends State<_AddQuoteItemDialog> {
  final _quantityController = TextEditingController(text: '1');
  Product? _product;
  ProductVariant? _variant;
  int _quantity = 1;
  PricingPreview? _preview;
  bool _loading = false;
  String? _error;
  Timer? _debounce;
  int _previewRequest = 0;

  @override
  void dispose() {
    _debounce?.cancel();
    _quantityController.dispose();
    super.dispose();
  }

  void _schedulePreview() {
    _debounce?.cancel();
    final product = _product;
    if (product == null || _quantity < 1) {
      setState(() {
        _preview = null;
        _error = null;
        _loading = false;
      });
      return;
    }

    _debounce = Timer(
      const Duration(milliseconds: 300),
      () => _loadPreview(++_previewRequest),
    );
  }

  Future<void> _loadPreview(int request) async {
    final product = _product;
    if (product == null || _quantity < 1) return;

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final preview = await getIt<PricingRepository>().preview(
        companyId: widget.company.id.value,
        productId: product.id.value,
        quantity: _quantity,
        priceTableId: widget.priceTable.id.value,
        variantId: _variant?.id.value,
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
        _error = 'Não foi possível simular o preço: $error';
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
    final preview = _preview;
    final canAdd = _product != null && preview != null && !_loading;

    return AlertDialog(
      title: const Text('Adicionar Item'),
      content: SizedBox(
        width: 520,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              DropdownButtonFormField<Product>(
                initialValue: _product,
                isExpanded: true,
                decoration: const InputDecoration(
                  labelText: 'Produto *',
                  prefixIcon: Icon(Icons.inventory_2_rounded),
                ),
                hint: const Text('Selecione um produto'),
                onChanged: (product) {
                  setState(() {
                    _product = product;
                    _variant = product != null && product.variants.isNotEmpty
                        ? product.variants.first
                        : null;
                  });
                  _schedulePreview();
                },
                items: widget.products
                    .map(
                      (product) => DropdownMenuItem(
                        value: product,
                        child: Text(product.name),
                      ),
                    )
                    .toList(),
              ),
              if (_product != null && _product!.variants.isNotEmpty) ...[
                const SizedBox(height: 16),
                DropdownButtonFormField<ProductVariant>(
                  initialValue: _variant,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: 'Variação *',
                    prefixIcon: Icon(Icons.tune_rounded),
                  ),
                  items: _product!.variants
                      .map(
                        (variant) => DropdownMenuItem(
                          value: variant,
                          child: Text(
                            '${variant.label} • ${variant.variantSku}',
                          ),
                        ),
                      )
                      .toList(),
                  onChanged: (variant) {
                    setState(() => _variant = variant);
                    _schedulePreview();
                  },
                ),
              ],
              const SizedBox(height: 16),
              TextField(
                controller: _quantityController,
                decoration: const InputDecoration(
                  labelText: 'Quantidade *',
                  prefixIcon: Icon(Icons.onetwothree_rounded),
                ),
                keyboardType: TextInputType.number,
                onChanged: (value) {
                  final parsed = int.tryParse(value) ?? 1;
                  setState(() => _quantity = parsed < 1 ? 1 : parsed);
                  _schedulePreview();
                },
              ),
              const SizedBox(height: 20),
              if (_loading)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: LinearProgressIndicator(),
                )
              else if (_error != null)
                Text(_error!, style: TextStyle(color: theme.colorScheme.error))
              else if (preview != null)
                _PreviewCard(
                  preview: preview,
                  onApplyMinQuantity: preview.nextTier == null
                      ? null
                      : () => _setQuantity(preview.nextTier!.minQuantity),
                )
              else
                Text(
                  'Selecione um produto e informe a quantidade.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: canAdd
              ? () => Navigator.pop(
                  context,
                  _QuoteItemDraft(
                    product: _product!,
                    variant: _variant,
                    quantity: _quantity,
                    preview: preview,
                  ),
                )
              : null,
          child: const Text('Adicionar'),
        ),
      ],
    );
  }
}

class _PreviewCard extends StatelessWidget {
  final PricingPreview preview;
  final VoidCallback? onApplyMinQuantity;

  const _PreviewCard({required this.preview, this.onApplyMinQuantity});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final explanation = preview.toExplanation();
    final nextTier = preview.nextTier;

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
              Text('Subtotal', style: theme.textTheme.bodyMedium),
              Text(
                preview.subtotal.formatted,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          if (explanation != null) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                DiscountBadge(pricing: explanation),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    'de ${explanation.referenceUnitPrice.formatted}/un.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      decoration: TextDecoration.lineThrough,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
          ],
          if (nextTier != null) ...[
            const SizedBox(height: 12),
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
                      'Faltam ${nextTier.unitsMissing} un. para '
                      '${nextTier.unitPrice.formatted}/un. '
                      '(economia de ${nextTier.savingsPerUnit.formatted}/un.)',
                      style: TextStyle(
                        color: Colors.amber.shade900,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  if (onApplyMinQuantity != null)
                    TextButton(
                      onPressed: onApplyMinQuantity,
                      child: const Text('Aplicar'),
                    ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
