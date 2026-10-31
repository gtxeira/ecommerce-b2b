import 'package:ecommerce_b2b/app/core/di/service_locator.dart';
import 'package:ecommerce_b2b/modules/catalog/product/model/product.dart';
import 'package:ecommerce_b2b/modules/catalog/product/model/product_variant.dart';
import 'package:ecommerce_b2b/modules/catalog/product/presentation/cubit/catalog_cubit.dart';
import 'package:ecommerce_b2b/modules/catalog/product/presentation/cubit/catalog_state.dart';
import 'package:ecommerce_b2b/modules/shared_kernel/model/common/ids/product_id.dart';
import 'package:ecommerce_b2b/modules/shared_kernel/model/common/ids/product_variant_id.dart';
import 'package:ecommerce_b2b/modules/shared_kernel/model/finance/value_objects/money.dart';
import 'package:ecommerce_b2b/modules/shared_kernel/model/logistics/value_objects/weight.dart';
import 'package:ecommerce_b2b/app/presentation/formz/money_input.dart';
import 'package:ecommerce_b2b/app/presentation/formz/not_empty_input.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';

class ProductListView extends StatelessWidget {
  const ProductListView({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => getIt<CatalogCubit>()..loadProducts(),
      child: BlocConsumer<CatalogCubit, CatalogState>(
        listener: (context, state) {
          if (state is CatalogProductDeleted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Produto excluído com sucesso!'),
                backgroundColor: Colors.green,
              ),
            );
          } else if (state is CatalogVariantDeleted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Variante excluída com sucesso!'),
                backgroundColor: Colors.green,
              ),
            );
          } else if (state is CatalogError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.red.shade700,
              ),
            );
          }
        },
        builder: (context, state) {
          final theme = Theme.of(context);
          final colorScheme = theme.colorScheme;

          return Scaffold(
            floatingActionButton: FloatingActionButton.extended(
              onPressed: () => _showAddProductDialog(context),
              icon: const Icon(Icons.add_shopping_cart_rounded),
              label: const Text('Novo Produto'),
            ),
            body: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: 'Pesquisar produtos por nome ou SKU...',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onChanged: (query) {
                      context.read<CatalogCubit>().loadProducts(query: query);
                    },
                  ),
                ),
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: () =>
                        context.read<CatalogCubit>().loadProducts(),
                    child: _buildList(context, state, theme, colorScheme),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildList(
    BuildContext context,
    CatalogState state,
    ThemeData theme,
    ColorScheme colorScheme,
  ) {
    if (state is CatalogLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state is CatalogLoaded) {
      final products = state.products;
      if (products.isEmpty) {
        return const Center(
          child: Text('Nenhum produto cadastrado no catálogo.'),
        );
      }

      return ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: products.length,
        itemBuilder: (context, index) {
          final product = products[index];
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: ExpansionTile(
              tilePadding: const EdgeInsets.all(12),
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.inventory_2_outlined,
                  color: colorScheme.onPrimaryContainer,
                ),
              ),
              title: Text(
                product.name,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'SKU: ${product.sku} | Preço Base: ${product.basePrice.formatted}',
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(
                        Icons.inventory_2_outlined,
                        size: 14,
                        color: Colors.blueGrey,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Estoque Disponível: ${state.stockMap[product.id.value] ?? 0} un',
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: (state.stockMap[product.id.value] ?? 0) > 0
                              ? Colors.green.shade700
                              : Colors.red.shade700,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Chip(
                    label: Text(
                      product.active ? 'Ativo' : 'Inativo',
                      style: TextStyle(
                        color: product.active
                            ? Colors.green.shade900
                            : Colors.red.shade900,
                        fontSize: 12,
                      ),
                    ),
                    backgroundColor: product.active
                        ? Colors.green.shade100
                        : Colors.red.shade100,
                    side: BorderSide.none,
                  ),
                  const SizedBox(width: 4),
                  IconButton(
                    icon: Icon(Icons.delete_outline, color: colorScheme.error),
                    tooltip: 'Excluir Produto',
                    onPressed: () => _showDeleteProductDialog(context, product),
                  ),
                ],
              ),
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSectionTitle(theme, 'Descrição'),
                      Text(
                        product.description,
                        style: theme.textTheme.bodyMedium,
                      ),
                      const Divider(height: 32),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _buildSectionTitle(
                            theme,
                            'Variações (${product.variants.length})',
                          ),
                          TextButton.icon(
                            onPressed: () =>
                                _showAddVariantDialog(context, product),
                            icon: const Icon(
                              Icons.add_circle_outline,
                              size: 20,
                            ),
                            label: const Text('Adicionar'),
                          ),
                        ],
                      ),
                      if (product.variants.isEmpty)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 8.0),
                          child: Text('Nenhuma variação cadastrada.'),
                        )
                      else
                        ...product.variants.map(
                          (variant) => Card(
                            color: colorScheme.surfaceContainerHighest
                                .withValues(alpha: 0.3),
                            elevation: 0,
                            margin: const EdgeInsets.only(top: 8),
                            child: ListTile(
                              dense: true,
                              leading: const Icon(Icons.style_outlined),
                              title: Text(
                                'SKU: ${variant.variantSku}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              subtitle: Text(
                                'Cor: ${variant.color} | Tam: ${variant.size} | Voltagem: ${variant.voltage}',
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    variant.sameAsParent
                                        ? product.basePrice.formatted
                                        : (variant.price?.formatted ?? 'N/A'),
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: colorScheme.primary,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  IconButton(
                                    icon: Icon(
                                      Icons.remove_circle_outline,
                                      color: colorScheme.error,
                                      size: 20,
                                    ),
                                    tooltip: 'Excluir Variante',
                                    onPressed: () => _showDeleteVariantDialog(
                                      context,
                                      product,
                                      variant,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      );
    }

    return const SizedBox.shrink();
  }

  Widget _buildSectionTitle(ThemeData theme, String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6.0),
      child: Text(
        title,
        style: theme.textTheme.titleSmall?.copyWith(
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }

  void _showDeleteProductDialog(BuildContext context, Product product) {
    showDialog(
      context: context,
      builder: (diagCtx) => AlertDialog(
        icon: Icon(
          Icons.warning_amber_rounded,
          color: Theme.of(context).colorScheme.error,
          size: 48,
        ),
        title: const Text('Excluir Produto'),
        content: Text(
          'Tem certeza que deseja excluir o produto "${product.name}" (SKU: ${product.sku})?\n\n'
          'Esta ação não poderá ser desfeita. O produto só será excluído se não possuir vínculos '
          'ativos (pedidos, cotações ou estoque).',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(diagCtx),
            child: const Text('Cancelar'),
          ),
          FilledButton.tonal(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.errorContainer,
              foregroundColor: Theme.of(context).colorScheme.onErrorContainer,
            ),
            onPressed: () {
              context.read<CatalogCubit>().deleteProduct(product.id);
              Navigator.pop(diagCtx);
            },
            child: const Text('Excluir'),
          ),
        ],
      ),
    );
  }

  void _showDeleteVariantDialog(
    BuildContext context,
    Product product,
    ProductVariant variant,
  ) {
    showDialog(
      context: context,
      builder: (diagCtx) => AlertDialog(
        icon: Icon(
          Icons.warning_amber_rounded,
          color: Theme.of(context).colorScheme.error,
          size: 48,
        ),
        title: const Text('Excluir Variante'),
        content: Text(
          'Tem certeza que deseja excluir a variante "${variant.variantSku}" do produto "${product.name}"?\n\n'
          'Esta ação não poderá ser desfeita.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(diagCtx),
            child: const Text('Cancelar'),
          ),
          FilledButton.tonal(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.errorContainer,
              foregroundColor: Theme.of(context).colorScheme.onErrorContainer,
            ),
            onPressed: () {
              context.read<CatalogCubit>().deleteVariant(
                product.id,
                variant.id,
              );
              Navigator.pop(diagCtx);
            },
            child: const Text('Excluir'),
          ),
        ],
      ),
    );
  }

  void _showAddProductDialog(BuildContext context) {
    final formKey = GlobalKey<FormState>();
    final nameCtrl = TextEditingController();
    final skuCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    final priceCtrl = TextEditingController();
    bool hasSubmitted = false;

    showDialog(
      context: context,
      builder: (diagCtx) => BlocProvider.value(
        value: context.read<CatalogCubit>(),
        child: StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Cadastrar Novo Produto'),
              content: SizedBox(
                width: 600,
                child: SingleChildScrollView(
                  child: Form(
                    key: formKey,
                    autovalidateMode: hasSubmitted
                        ? AutovalidateMode.onUserInteraction
                        : AutovalidateMode.disabled,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TextFormField(
                          controller: nameCtrl,
                          decoration: const InputDecoration(
                            labelText: 'Nome do Produto *',
                            prefixIcon: Icon(Icons.label_outline),
                          ),
                          validator: (v) => NotEmptyInput.dirty(v ?? '').isValid
                              ? null
                              : 'Obrigatório',
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: skuCtrl,
                          decoration: const InputDecoration(
                            labelText: 'SKU Base *',
                            prefixIcon: Icon(Icons.qr_code_scanner),
                          ),
                          validator: (v) => NotEmptyInput.dirty(v ?? '').isValid
                              ? null
                              : 'Obrigatório',
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: priceCtrl,
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(
                              RegExp(r'^\d*\.?\d*'),
                            ),
                          ],
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          decoration: const InputDecoration(
                            labelText: 'Preço Base *',
                            prefixIcon: Icon(Icons.attach_money_rounded),
                          ),
                          validator: (v) => MoneyInput.dirty(v ?? '').isValid
                              ? null
                              : 'Inválido',
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: descCtrl,
                          maxLines: 3,
                          decoration: const InputDecoration(
                            labelText: 'Descrição',
                            prefixIcon: Icon(Icons.description_outlined),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(diagCtx),
                  child: const Text('Cancelar'),
                ),
                ElevatedButton(
                  onPressed: () {
                    setState(() => hasSubmitted = true);
                    if (formKey.currentState?.validate() ?? false) {
                      final product = Product(
                        id: ProductId(const Uuid().v7()),
                        sku: skuCtrl.text,
                        name: nameCtrl.text,
                        description: descCtrl.text,
                        basePrice: Money.create(
                          double.parse(priceCtrl.text),
                        ).getOrThrow(),
                        active: true,
                      );
                      context.read<CatalogCubit>().saveProduct(product);
                      Navigator.pop(diagCtx);
                    }
                  },
                  child: const Text('Salvar'),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  void _showAddVariantDialog(BuildContext context, Product product) {
    final formKey = GlobalKey<FormState>();
    final skuCtrl = TextEditingController(text: '${product.sku}-');
    final colorCtrl = TextEditingController();
    final sizeCtrl = TextEditingController();
    final voltageCtrl = TextEditingController();
    final weightCtrl = TextEditingController();
    final priceCtrl = TextEditingController();
    bool sameAsParent = true;
    bool hasSubmitted = false;

    showDialog(
      context: context,
      builder: (diagCtx) => BlocProvider.value(
        value: context.read<CatalogCubit>(),
        child: StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text('Nova Variante: ${product.name}'),
              content: SizedBox(
                width: 500,
                child: SingleChildScrollView(
                  child: Form(
                    key: formKey,
                    autovalidateMode: hasSubmitted
                        ? AutovalidateMode.onUserInteraction
                        : AutovalidateMode.disabled,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TextFormField(
                          controller: skuCtrl,
                          decoration: const InputDecoration(
                            labelText: 'SKU da Variante *',
                            prefixIcon: Icon(Icons.qr_code_rounded),
                          ),
                          validator: (v) => NotEmptyInput.dirty(v ?? '').isValid
                              ? null
                              : 'Obrigatório',
                        ),
                        const SizedBox(height: 16),
                        CheckboxListTile(
                          title: const Text('Mesmo preço do produto raiz'),
                          value: sameAsParent,
                          onChanged: (v) =>
                              setState(() => sameAsParent = v ?? true),
                          controlAffinity: ListTileControlAffinity.leading,
                          contentPadding: EdgeInsets.zero,
                        ),
                        if (!sameAsParent)
                          Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: TextFormField(
                              controller: priceCtrl,
                              inputFormatters: [
                                FilteringTextInputFormatter.allow(
                                  RegExp(r'^\d*\.?\d*'),
                                ),
                              ],
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                    decimal: true,
                                  ),
                              decoration: const InputDecoration(
                                labelText: 'Preço da Variante *',
                                prefixIcon: Icon(Icons.attach_money_rounded),
                              ),
                              validator: (v) =>
                                  MoneyInput.dirty(v ?? '').isValid
                                  ? null
                                  : 'Inválido',
                            ),
                          ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: colorCtrl,
                          decoration: const InputDecoration(
                            labelText: 'Cor',
                            prefixIcon: Icon(Icons.color_lens_outlined),
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: sizeCtrl,
                          decoration: const InputDecoration(
                            labelText: 'Tamanho / Dimensão',
                            prefixIcon: Icon(Icons.straighten_rounded),
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: voltageCtrl,
                          decoration: const InputDecoration(
                            labelText: 'Voltagem',
                            prefixIcon: Icon(Icons.bolt_rounded),
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: weightCtrl,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          decoration: const InputDecoration(
                            labelText: 'Peso (kg)',
                            prefixIcon: Icon(Icons.scale_outlined),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(diagCtx),
                  child: const Text('Cancelar'),
                ),
                ElevatedButton(
                  onPressed: () {
                    setState(() => hasSubmitted = true);
                    if (formKey.currentState?.validate() ?? false) {
                      final variant = ProductVariant(
                        id: ProductVariantId(const Uuid().v7()),
                        variantSku: skuCtrl.text,
                        color: colorCtrl.text,
                        size: sizeCtrl.text,
                        voltage: voltageCtrl.text,
                        sameAsParent: sameAsParent,
                        price: sameAsParent
                            ? null
                            : Money.create(
                                double.parse(priceCtrl.text),
                              ).getOrThrow(),
                        weight: Weight.create(
                          double.tryParse(weightCtrl.text) ?? 0,
                        ).getOrThrow(),
                      );
                      product.addVariant(variant);
                      context.read<CatalogCubit>().saveProduct(product);
                      Navigator.pop(diagCtx);
                    }
                  },
                  child: const Text('Adicionar'),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
