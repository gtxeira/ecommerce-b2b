import 'package:ecommerce_b2b/app/core/format/display_labels.dart';
import 'package:ecommerce_b2b/modules/catalog/product/model/product.dart';
import 'package:ecommerce_b2b/modules/inventory/warehouse/presentation/cubit/inventory_cubit.dart';
import 'package:ecommerce_b2b/modules/inventory/warehouse/presentation/widgets/add_warehouse_dialog.dart';
import 'package:ecommerce_b2b/modules/inventory/warehouse/presentation/widgets/inventory_error_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Aba de gestão de depósitos.
///
/// A API atual expõe listagem e cadastro; por isso a "gestão" aqui é a lista
/// detalhada dos depósitos com o botão de cadastro isolado nesta aba.
class WarehouseManagementView extends StatelessWidget {
  const WarehouseManagementView({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<InventoryCubit, InventoryState>(
      builder: (context, state) {
        if (state is InventoryInitial || state is InventoryLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (state is InventoryFailure) {
          return InventoryErrorView(
            message: state.message,
            onRetry: () => context.read<InventoryCubit>().load(),
          );
        }

        final loaded = state as InventoryLoaded;
        return Scaffold(
          backgroundColor: Colors.transparent,
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () => _showAddWarehouseDialog(context),
            icon: const Icon(Icons.add_business_rounded),
            label: const Text('Novo Depósito'),
          ),
          body: RefreshIndicator(
            onRefresh: () => context.read<InventoryCubit>().load(),
            child: _buildList(context, loaded),
          ),
        );
      },
    );
  }

  Widget _buildList(BuildContext context, InventoryLoaded state) {
    final theme = Theme.of(context);
    final warehouses = [...state.warehouses]
      ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    final productsById = <String, Product>{
      for (final product in state.products) product.id.value: product,
    };

    if (warehouses.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(32),
        children: [
          const SizedBox(height: 72),
          Icon(
            Icons.warehouse_outlined,
            size: 72,
            color: theme.colorScheme.outline,
          ),
          const SizedBox(height: 16),
          Text(
            'Nenhum depósito cadastrado.',
            textAlign: TextAlign.center,
            style: theme.textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(
            'Cadastre o primeiro depósito para começar a controlar o estoque.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 20),
          Center(
            child: ElevatedButton.icon(
              onPressed: () => _showAddWarehouseDialog(context),
              icon: const Icon(Icons.add_business_rounded),
              label: const Text('Cadastrar primeiro depósito'),
            ),
          ),
        ],
      );
    }

    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
      itemCount: warehouses.length + 1,
      itemBuilder: (context, index) {
        if (index == 0) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              children: [
                Icon(Icons.warehouse_rounded, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  '${warehouses.length} ${warehouses.length == 1 ? 'depósito cadastrado' : 'depósitos cadastrados'}',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          );
        }

        final warehouse = warehouses[index - 1];
        final stockItems = [...warehouse.stockItems]
          ..sort((a, b) {
            final productA = productsById[a.productId.value];
            final productB = productsById[b.productId.value];
            return (productA?.name ?? a.productId.value).compareTo(
              productB?.name ?? b.productId.value,
            );
          });
        final totalUnits = stockItems.fold<int>(
          0,
          (total, item) => total + item.physicalQuantity.value,
        );
        final productsWithStock = stockItems
            .where((item) => item.physicalQuantity.value > 0)
            .length;

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ExpansionTile(
            leading: CircleAvatar(
              backgroundColor: theme.colorScheme.primaryContainer,
              child: Icon(
                Icons.warehouse_rounded,
                color: theme.colorScheme.onPrimaryContainer,
              ),
            ),
            title: Text(
              warehouse.name,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text(
              'Código: ${warehouse.code} · $productsWithStock ${productsWithStock == 1 ? 'produto' : 'produtos'}',
            ),
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                '$totalUnits un',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onPrimaryContainer,
                ),
              ),
            ),
            children: [
              const Divider(height: 1),
              if (stockItems.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(16),
                  child: Text('Nenhum produto registrado neste depósito.'),
                )
              else
                ...stockItems.map((item) {
                  final product = productsById[item.productId.value];
                  return ListTile(
                    dense: true,
                    leading: const Icon(Icons.inventory_2_outlined, size: 20),
                    title: Text(
                      productLabel(
                        name: product?.name,
                        sku: product?.sku,
                        id: item.productId.value,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    trailing: Text(
                      '${item.physicalQuantity.value} un',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  );
                }),
            ],
          ),
        );
      },
    );
  }

  Future<void> _showAddWarehouseDialog(BuildContext context) async {
    final data = await showDialog<AddWarehouseResult>(
      context: context,
      builder: (_) => const AddWarehouseDialog(),
    );

    if (data == null || !context.mounted) return;

    try {
      await context.read<InventoryCubit>().addWarehouse(
        code: data.code,
        name: data.name,
      );
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Depósito cadastrado com sucesso!')),
      );
    } catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao cadastrar depósito: $error')),
      );
    }
  }
}
