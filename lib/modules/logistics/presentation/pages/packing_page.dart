import 'package:ecommerce_b2b/app/core/di/service_locator.dart';
import 'package:ecommerce_b2b/app/presentation/widgets/b2b_app_bar.dart';
import 'package:ecommerce_b2b/modules/order_flow/model/enums/order_status.dart';
import 'package:ecommerce_b2b/modules/order_flow/sales_order/model/repositories/sales_order_repository.dart';
import 'package:ecommerce_b2b/modules/order_flow/sales_order/model/sales_order.dart';
import 'package:ecommerce_b2b/modules/catalog/product/model/repositories/product_repository.dart';
import 'package:ecommerce_b2b/modules/inventory/warehouse/model/repositories/inventory_repository.dart';
import 'package:ecommerce_b2b/modules/inventory/warehouse/model/warehouse.dart';
import 'package:ecommerce_b2b/modules/logistics/application/procces_order/process_order_shipment_use_case.dart';
import 'package:ecommerce_b2b/modules/shared_kernel/model/common/ids/product_id.dart';
import 'package:ecommerce_b2b/modules/shared_kernel/model/common/ids/warehouse_id.dart';
import 'package:ecommerce_b2b/modules/shared_kernel/model/logistics/value_objects/tracking_code.dart';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

class PackingPage extends StatefulWidget {
  const PackingPage({super.key});

  @override
  State<PackingPage> createState() => _PackingPageState();
}

class _PackingPageState extends State<PackingPage> {
  List<SalesOrder> _orders = [];
  Map<String, String> _productNames = {};
  List<Warehouse> _warehouses = [];
  final Map<String, WarehouseId> _selectedWarehouse = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final orderRepo = getIt<SalesOrderRepository>();
    final productRepo = getIt<ProductRepository>();
    final inventoryRepo = getIt<InventoryRepository>();

    try {
      final allOrders = await orderRepo.getAll();
      final allProducts = await productRepo.getAll();
      final allWarehouses = await inventoryRepo.getAll();

      final Map<String, String> names = {
        for (var p in allProducts) p.id.value: p.name,
      };

      setState(() {
        _orders = allOrders
            .where((o) => o.status == OrderStatus.pickingPacking)
            .toList();
        _productNames = names;
        _warehouses = allWarehouses;
        for (final order in _orders) {
          _selectedWarehouse.putIfAbsent(
            order.id.value,
            () => allWarehouses.isNotEmpty
                ? allWarehouses.first.id
                : const WarehouseId(''),
          );
        }
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao carregar a expedição: $error')),
      );
    }
  }

  String _getSourceWarehouses(ProductId productId) {
    final List<String> sources = [];
    for (var wh in _warehouses) {
      final stockItem = wh.getStockItem(productId);
      if (stockItem != null && stockItem.physicalQuantity.value > 0) {
        sources.add('${wh.name} (${stockItem.physicalQuantity.value})');
      }
    }
    return sources.isEmpty ? 'Sem estoque cadastrado' : sources.join(', ');
  }

  Future<void> _shipOrder(SalesOrder order) async {
    final warehouseId = _selectedWarehouse[order.id.value];
    if (warehouseId == null || warehouseId.value.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Selecione um depósito para a separação.'),
        ),
      );
      return;
    }

    try {
      final useCase = getIt<ProcessOrderShipmentUseCase>();

      await useCase.execute(
        order: order,
        warehouseId: warehouseId,
        trackingCode: TrackingCode.create(
          'TRK-${const Uuid().v4().substring(0, 8).toUpperCase()}',
        ).getOrThrow(),
        labelNumber: 'LABEL-${order.id.value.substring(0, 8)}',
        packageDescription: 'Caixa padrão',
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Pedido #${order.id.value.substring(0, 8)} despachado com sucesso!',
          ),
        ),
      );

      _loadData();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Erro ao despachar pedido: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const B2BAppBar(title: 'Expedição (Picking & Packing)'),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadData,
              child: _orders.isEmpty
                  ? const Center(
                      child: Text('Nenhum pedido pendente de expedição.'),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _orders.length,
                      itemBuilder: (context, index) {
                        final order = _orders[index];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 16),
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'Pedido #${order.id.value.substring(0, 8)}',
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleMedium
                                          ?.copyWith(
                                            fontWeight: FontWeight.bold,
                                          ),
                                    ),
                                    ElevatedButton.icon(
                                      onPressed: () => _shipOrder(order),
                                      icon: const Icon(
                                        Icons.local_shipping_rounded,
                                      ),
                                      label: const Text('Despachar'),
                                    ),
                                  ],
                                ),
                                const Divider(),
                                if (_warehouses.isNotEmpty)
                                  DropdownButtonFormField<WarehouseId>(
                                    initialValue:
                                        _selectedWarehouse[order.id.value],
                                    decoration: const InputDecoration(
                                      labelText: 'Depósito da separação',
                                      prefixIcon: Icon(
                                        Icons.warehouse_outlined,
                                      ),
                                    ),
                                    items: _warehouses
                                        .map(
                                          (wh) => DropdownMenuItem(
                                            value: wh.id,
                                            child: Text(wh.name),
                                          ),
                                        )
                                        .toList(),
                                    onChanged: (value) {
                                      if (value != null) {
                                        setState(
                                          () =>
                                              _selectedWarehouse[order
                                                      .id
                                                      .value] =
                                                  value,
                                        );
                                      }
                                    },
                                  ),
                                const SizedBox(height: 12),
                                const Text(
                                  'Itens do Pedido:',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                                ...order.items.map((item) {
                                  final name =
                                      _productNames[item.productId.value] ??
                                      'Produto #${item.productId.value}';
                                  final sources = _getSourceWarehouses(
                                    item.productId,
                                  );
                                  return Padding(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 4,
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            const Icon(
                                              Icons.check_circle_outline,
                                              size: 16,
                                              color: Colors.green,
                                            ),
                                            const SizedBox(width: 8),
                                            Expanded(child: Text(name)),
                                            Text(
                                              'x${item.quantity.value}',
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ],
                                        ),
                                        Padding(
                                          padding: const EdgeInsets.only(
                                            left: 24.0,
                                            bottom: 4.0,
                                          ),
                                          child: Text(
                                            'Origem (Picking): $sources',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.grey.shade600,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                }),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
    );
  }
}
