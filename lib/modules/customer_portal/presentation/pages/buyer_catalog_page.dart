import 'package:ecommerce_b2b/app/core/di/service_locator.dart';
import 'package:ecommerce_b2b/modules/catalog/product/model/product.dart';
import 'package:ecommerce_b2b/modules/catalog/product/presentation/cubit/catalog_cubit.dart';
import 'package:ecommerce_b2b/modules/catalog/product/presentation/cubit/catalog_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

/// Catálogo somente-leitura para compradores.
///
/// Exibe produtos e variações, mas NÃO permite criar, editar ou excluir
/// produtos, variações ou tabelas de preços.
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

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
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
              onRefresh: () => context.read<CatalogCubit>().loadProducts(
                query: _searchController.text.isEmpty
                    ? null
                    : _searchController.text,
              ),
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: products.length,
                itemBuilder: (context, index) {
                  return _ProductCard(product: products[index]);
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

class _ProductCard extends StatelessWidget {
  final Product product;
  const _ProductCard({required this.product});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

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
          product.name,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(
            'SKU: ${product.sku}',
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
              product.basePrice.formatted,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w900,
                color: colorScheme.primary,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              '${product.variants.length} variações',
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        children: [
          // Descrição
          if (product.description.isNotEmpty) ...[
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                product.description,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Variações
          if (product.variants.isEmpty)
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
            ...product.variants.map(
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
                          ? product.basePrice.formatted
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

          // Botão de contato com representante
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: () => _showContactDialog(context),
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

  void _showContactDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('Solicitar Orçamento'),
        content: Text(
          'Para solicitar um orçamento do produto "${product.name}", entre em contato com seu representante comercial ou aguarde que ele abra um pedido por você.',
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
