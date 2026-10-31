import 'package:ecommerce_b2b/modules/inventory/warehouse/model/warehouse.dart';
import 'package:ecommerce_b2b/modules/shared_kernel/model/common/ids/warehouse_id.dart';
import 'package:ecommerce_b2b/modules/shared_kernel/model/common/ids/product_id.dart';
import 'package:ecommerce_b2b/modules/inventory/warehouse/model/stock_item.dart';

abstract class InventoryRepository {
  Future<void> save(Warehouse warehouse);

  Future<Warehouse?> getById(WarehouseId id);

  Future<List<Warehouse>> getAll();

  /// Gets consolidated stock across all warehouses.
  Future<List<StockItem>> getConsolidatedStock();

  /// Gets stock for a specific product in a warehouse.
  Future<StockItem?> getStock(WarehouseId warehouseId, ProductId productId);

  /// Cadastra um depósito vazio (POST /api/inventory/warehouses).
  Future<Warehouse> createWarehouse({
    required String code,
    required String name,
  });

  /// Ajusta a quantidade física do produto no depósito (PATCH na API).
  Future<void> adjustStock({
    required WarehouseId warehouseId,
    required ProductId productId,
    required int physicalQuantity,
  });
}
