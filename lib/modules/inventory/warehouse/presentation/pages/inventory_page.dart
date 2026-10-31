import 'package:ecommerce_b2b/app/core/di/service_locator.dart';
import 'package:ecommerce_b2b/app/presentation/widgets/b2b_app_bar.dart';
import 'package:ecommerce_b2b/modules/inventory/warehouse/domain/repositories/inventory_repository.dart';
import 'package:ecommerce_b2b/modules/inventory/warehouse/domain/warehouse.dart';
import 'package:ecommerce_b2b/modules/catalog/product/domain/product.dart';
import 'package:ecommerce_b2b/modules/catalog/product/domain/repositories/product_repository.dart';
import 'package:flutter/material.dart';

class InventoryPage extends StatefulWidget {
  const InventoryPage({super.key});

  @override
  State<InventoryPage> createState() => _InventoryPageState();
}

class _InventoryPageState extends State<InventoryPage> {
  List<Product> _products = [];
  List<Warehouse> _warehouses = [];
  Map<String, int> _consolidatedStock = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final inventoryRepo = getIt<InventoryRepository>();
    final productRepo = getIt<ProductRepository>();

    try {
      final warehouses = await inventoryRepo.getAll();
      final consolidatedStock = await inventoryRepo.getConsolidatedStock();
      final allProducts = await productRepo.getAll();

      final Map<String, int> stockMap = {
        for (var item in consolidatedStock)
          item.productId.value: item.physicalQuantity.value,
      };

      if (!mounted) return;
      setState(() {
        _products = allProducts.where((p) => p.active).toList();
        _warehouses = warehouses;
        _consolidatedStock = stockMap;
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao carregar estoque: $error')),
      );
    }
  }

  Future<void> _showAddWarehouseDialog() async {
    final formKey = GlobalKey<FormState>();
    final codeCtrl = TextEditingController();
    final nameCtrl = TextEditingController();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Novo Depósito'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: nameCtrl,
                decoration: const InputDecoration(
                  labelText: 'Nome do Depósito *',
                  prefixIcon: Icon(Icons.warehouse_outlined),
                ),
                validator: (value) =>
                    (value ?? '').trim().isEmpty ? 'Informe o nome' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: codeCtrl,
                textCapitalization: TextCapitalization.characters,
                decoration: const InputDecoration(
                  labelText: 'Código Identificador *',
                  prefixIcon: Icon(Icons.qr_code_rounded),
                  helperText: 'Até 20 caracteres, único',
                ),
                validator: (value) {
                  final code = (value ?? '').trim();
                  if (code.isEmpty) return 'Informe o código';
                  if (code.length > 20) return 'Máximo de 20 caracteres';
                  return null;
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              if (formKey.currentState?.validate() ?? false) {
                Navigator.pop(dialogContext, true);
              }
            },
            child: const Text('Salvar'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await getIt<InventoryRepository>().createWarehouse(
        code: codeCtrl.text.trim(),
        name: nameCtrl.text.trim(),
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Depósito cadastrado com sucesso!')),
      );
      await _loadData();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao cadastrar depósito: $error')),
      );
    }
  }

  Future<void> _adjustStock(
    Product product, [
    Warehouse? targetWarehouse,
  ]) async {
    Warehouse? selectedWh =
        targetWarehouse ?? (_warehouses.isNotEmpty ? _warehouses.first : null);

    if (selectedWh == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nenhum depósito cadastrado.')),
      );
      return;
    }

    final currentStock =
        selectedWh.getStockItem(product.id)?.physicalQuantity.value ?? 0;
    final TextEditingController controller = TextEditingController(
      text: currentStock.toString(),
    );

    final result = await showDialog<({Warehouse warehouse, int quantity})>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text('Ajustar Estoque: ${product.name}'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<Warehouse>(
                initialValue: selectedWh,
                decoration: const InputDecoration(labelText: 'Depósito'),
                items: _warehouses
                    .map(
                      (wh) => DropdownMenuItem(value: wh, child: Text(wh.name)),
                    )
                    .toList(),
                onChanged: targetWarehouse != null
                    ? null
                    : (wh) {
                        if (wh != null) {
                          setDialogState(() {
                            selectedWh = wh;
                            controller.text =
                                (wh
                                            .getStockItem(product.id)
                                            ?.physicalQuantity
                                            .value ??
                                        0)
                                    .toString();
                          });
                        }
                      },
              ),
              const SizedBox(height: 16),
              TextField(
                controller: controller,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Quantidade Física',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () {
                final qty = int.tryParse(controller.text);
                if (qty != null && selectedWh != null) {
                  Navigator.pop(context, (
                    warehouse: selectedWh!,
                    quantity: qty,
                  ));
                }
              },
              child: const Text('Salvar'),
            ),
          ],
        ),
      ),
    );

    if (result != null) {
      final inventoryRepo = getIt<InventoryRepository>();
      try {
        await inventoryRepo.adjustStock(
          warehouseId: result.warehouse.id,
          productId: product.id,
          physicalQuantity: result.quantity,
        );
      } catch (error) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao ajustar estoque: $error')),
        );
        return;
      }
      _loadData();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const B2BAppBar(title: 'Gestão de Estoque'),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddWarehouseDialog,
        icon: const Icon(Icons.add_business_rounded),
        label: const Text('Novo Depósito'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadData,
              child: _products.isEmpty
                  ? const Center(
                      child: Text('Nenhum produto ativo encontrado.'),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _products.length,
                      itemBuilder: (context, index) {
                        final product = _products[index];
                        final consolidatedQty =
                            _consolidatedStock[product.id.value] ?? 0;

                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          child: ExpansionTile(
                            leading: const Icon(Icons.inventory_2_rounded),
                            title: Text(product.name),
                            subtitle: Text('SKU: ${product.sku}'),
                            trailing: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: Theme.of(
                                  context,
                                ).colorScheme.primaryContainer,
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Text(
                                '$consolidatedQty un (Total)',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onPrimaryContainer,
                                ),
                              ),
                            ),
                            children: [
                              const Divider(height: 1),
                              ..._warehouses.map((wh) {
                                final whStock =
                                    wh
                                        .getStockItem(product.id)
                                        ?.physicalQuantity
                                        .value ??
                                    0;
                                return ListTile(
                                  dense: true,
                                  title: Text(wh.name),
                                  subtitle: Text('Código: ${wh.code}'),
                                  trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        '$whStock un',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      IconButton(
                                        icon: const Icon(
                                          Icons.edit_note_rounded,
                                          size: 20,
                                        ),
                                        onPressed: () =>
                                            _adjustStock(product, wh),
                                      ),
                                    ],
                                  ),
                                );
                              }),
                              Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: TextButton.icon(
                                  onPressed: () => _adjustStock(product),
                                  icon: const Icon(Icons.add_business_rounded),
                                  label: const Text(
                                    'Ajustar em outro depósito',
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
    );
  }
}
