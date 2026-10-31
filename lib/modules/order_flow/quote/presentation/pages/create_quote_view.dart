import 'package:ecommerce_b2b/app/core/di/service_locator.dart';
import 'package:ecommerce_b2b/modules/catalog/price_table/model/price_table.dart';
import 'package:ecommerce_b2b/modules/catalog/price_table/model/repositories/price_table_repository.dart';
import 'package:ecommerce_b2b/modules/catalog/product/model/product.dart';
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

  void _addItem(Product product, int quantity) {
    setState(() {
      _items.add(
        QuoteItem(
          productId: product.id,
          quantity: Quantity.create(quantity).getOrThrow(),
          unitPrice: product.basePrice,
          priceTableId: _selectedPriceTable?.id.value,
        ),
      );
    });
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
      representativeId: authState.session.userId.value,
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
            onChanged: (company) => setState(() => _selectedCompany = company),
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
            onChanged: (table) => setState(() => _selectedPriceTable = table),
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
                              child: Text(
                                'Qtd: ${item.quantity.value} • Unitário: ${item.unitPrice.formatted} • Total: ${item.subtotal.formatted}',
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
    showDialog(
      context: context,
      builder: (context) {
        Product? selectedProduct;
        int quantity = 1;
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Adicionar Item'),
              content: SizedBox(
                width: 900,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      DropdownButtonFormField<Product>(
                        initialValue: selectedProduct,
                        isExpanded: true,
                        decoration: const InputDecoration(
                          labelText: 'Produto *',
                          prefixIcon: Icon(Icons.inventory_2_rounded),
                        ),
                        hint: const Text('Selecione um produto'),
                        onChanged: (p) => setState(() => selectedProduct = p),
                        items: _availableProducts.map((p) {
                          return DropdownMenuItem(
                            value: p,
                            child: Text(p.name),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        decoration: const InputDecoration(
                          labelText: 'Quantidade *',
                          prefixIcon: Icon(Icons.onetwothree_rounded),
                        ),
                        keyboardType: TextInputType.number,
                        onChanged: (v) => quantity = int.tryParse(v) ?? 1,
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
                TextButton(
                  onPressed: () {
                    if (selectedProduct != null) {
                      _addItem(selectedProduct!, quantity);
                      Navigator.pop(context);
                    }
                  },
                  child: const Text('Adicionar'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
