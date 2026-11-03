import 'package:ecommerce_b2b/modules/catalog/product/model/product.dart';
import 'package:ecommerce_b2b/modules/inventory/warehouse/model/warehouse.dart';
import 'package:ecommerce_b2b/modules/inventory/warehouse/presentation/cubit/inventory_cubit.dart';
import 'package:ecommerce_b2b/modules/inventory/warehouse/presentation/widgets/adjust_stock_dialog.dart';
import 'package:ecommerce_b2b/modules/inventory/warehouse/presentation/widgets/inventory_error_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Aba de controle de estoque: saldo consolidado e ajuste por depósito.
class StockControlView extends StatelessWidget {
  const StockControlView({super.key});

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
        return RefreshIndicator(
          onRefresh: () => context.read<InventoryCubit>().load(),
          child: _buildList(context, loaded),
        );
      },
    );
  }

  Widget _buildList(BuildContext context, InventoryLoaded state) {
    final theme = Theme.of(context);

    if (state.products.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(32),
        children: [
          const SizedBox(height: 80),
          Icon(
            Icons.inventory_2_outlined,
            size: 72,
            color: theme.colorScheme.outline,
          ),
          const SizedBox(height: 16),
          Text(
            'Nenhum produto ativo encontrado.',
            textAlign: TextAlign.center,
            style: theme.textTheme.titleMedium,
          ),
        ],
      );
    }

    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      itemCount: state.products.length,
      itemBuilder: (context, index) {
        final product = state.products[index];
        final consolidatedQty = state.consolidatedStock[product.id.value] ?? 0;

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ExpansionTile(
            leading: const Icon(Icons.inventory_2_rounded),
            title: Text(product.name),
            subtitle: Text('SKU: ${product.sku}'),
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                '$consolidatedQty un (Total)',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onPrimaryContainer,
                ),
              ),
            ),
            children: [
              const Divider(height: 1),
              if (state.warehouses.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(16),
                  child: Text('Nenhum depósito cadastrado.'),
                )
              else
                ...state.warehouses.map((warehouse) {
                  final warehouseStock =
                      warehouse
                          .getStockItem(product.id)
                          ?.physicalQuantity
                          .value ??
                      0;
                  return ListTile(
                    dense: true,
                    title: Text(warehouse.name),
                    subtitle: Text('Código: ${warehouse.code}'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '$warehouseStock un',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        IconButton(
                          tooltip: 'Ajustar estoque em ${warehouse.name}',
                          icon: const Icon(Icons.edit_note_rounded, size: 20),
                          onPressed: () =>
                              _adjustStock(context, product, warehouse),
                        ),
                      ],
                    ),
                  );
                }),
              if (state.warehouses.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.all(8),
                  child: TextButton.icon(
                    onPressed: () => _adjustStock(context, product),
                    icon: const Icon(Icons.add_business_rounded),
                    label: const Text('Ajustar em outro depósito'),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _adjustStock(
    BuildContext context,
    Product product, [
    Warehouse? warehouse,
  ]) async {
    final cubit = context.read<InventoryCubit>();
    final state = cubit.state;
    if (state is! InventoryLoaded) return;

    if (state.warehouses.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nenhum depósito cadastrado.')),
      );
      return;
    }

    final result = await showDialog<AdjustStockResult>(
      context: context,
      builder: (_) => AdjustStockDialog(
        product: product,
        warehouses: state.warehouses,
        initialWarehouse: warehouse,
      ),
    );

    if (result == null || !context.mounted) return;

    try {
      await cubit.adjustStock(
        warehouseId: result.warehouse.id.value,
        productId: product.id.value,
        physicalQuantity: result.quantity,
      );
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Estoque de ${product.name} ajustado em ${result.warehouse.name}.',
          ),
        ),
      );
    } catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao ajustar estoque: $error')),
      );
    }
  }
}
