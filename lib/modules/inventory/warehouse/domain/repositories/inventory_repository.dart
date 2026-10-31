import 'package:ecommerce_b2b/modules/inventory/warehouse/domain/warehouse.dart';
import 'package:ecommerce_b2b/modules/shared_kernel/base/base_repository.dart';
import 'package:ecommerce_b2b/modules/shared_kernel/domain/common/ids/warehouse_id.dart';
import 'package:ecommerce_b2b/modules/shared_kernel/domain/common/ids/product_id.dart';
import 'package:ecommerce_b2b/modules/inventory/warehouse/domain/stock_item.dart';

abstract class InventoryRepository implements BaseRepository<Warehouse> {
  @override
  Future<void> save(Warehouse warehouse);

  Future<Warehouse?> getById(WarehouseId id);

  Future<List<Warehouse>> getAll();

  /// Gets consolidated stock across all warehouses.
  Future<List<StockItem>> getConsolidatedStock();

  /// Gets stock for a specific product in a warehouse.
  Future<StockItem?> getStock(WarehouseId warehouseId, ProductId productId);

  /// Ajusta a quantidade física do produto no depósito (PATCH na API).
  Future<void> adjustStock({
    required WarehouseId warehouseId,
    required ProductId productId,
    required int physicalQuantity,
  });
}
