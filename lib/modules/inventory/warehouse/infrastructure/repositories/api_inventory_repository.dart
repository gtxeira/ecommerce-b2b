import 'package:ecommerce_b2b/app/core/network/api_client.dart';
import 'package:ecommerce_b2b/app/core/network/json_read.dart';
import 'package:ecommerce_b2b/modules/inventory/warehouse/model/repositories/inventory_repository.dart';
import 'package:ecommerce_b2b/modules/inventory/warehouse/model/stock_item.dart';
import 'package:ecommerce_b2b/modules/inventory/warehouse/model/warehouse.dart';
import 'package:ecommerce_b2b/modules/shared_kernel/model/common/ids/product_id.dart';
import 'package:ecommerce_b2b/modules/shared_kernel/model/common/ids/warehouse_id.dart';
import 'package:ecommerce_b2b/modules/shared_kernel/model/finance/value_objects/quantity.dart';

class ApiInventoryRepository implements InventoryRepository {
  final ApiClient _api;

  ApiInventoryRepository(this._api);

  @override
  Future<List<Warehouse>> getAll() async {
    final warehousesData = await _api.get('/api/inventory/warehouses');
    final stockData = await _api.get('/api/inventory/stock');

    final stockByProduct = _stockRows(stockData);
    if (warehousesData is! List) return const [];

    return warehousesData.whereType<Map>().map((raw) {
      final json = Map<String, dynamic>.from(raw);
      final id = readString(json, 'id');

      final stockItems = <StockItem>[];
      for (final row in stockByProduct) {
        for (final warehouse in row.warehouses) {
          if (warehouse.warehouseId == id) {
            stockItems.add(
              StockItem(
                productId: row.productId,
                physicalQuantity: Quantity.create(
                  warehouse.physicalQuantity,
                ).getOrThrow(),
              ),
            );
          }
        }
      }

      return Warehouse(
        id: WarehouseId(id),
        code: readString(json, 'code'),
        name: readString(json, 'name'),
        stockItems: stockItems,
      );
    }).toList();
  }

  @override
  Future<Warehouse?> getById(WarehouseId id) async {
    final all = await getAll();
    for (final warehouse in all) {
      if (warehouse.id == id) return warehouse;
    }
    return null;
  }

  @override
  Future<List<StockItem>> getConsolidatedStock() async {
    final data = await _api.get('/api/inventory/stock');
    return _stockRows(data)
        .map(
          (row) => StockItem(
            productId: row.productId,
            physicalQuantity: Quantity.create(
              row.physicalQuantity,
            ).getOrThrow(),
          ),
        )
        .toList();
  }

  @override
  Future<StockItem?> getStock(
    WarehouseId warehouseId,
    ProductId productId,
  ) async {
    final data = await _api.get('/api/inventory/stock/${productId.value}');
    if (data is! Map) return null;
    final json = Map<String, dynamic>.from(data);
    final warehouses = readMapList(json, 'warehouses');
    for (final warehouse in warehouses) {
      if (readString(warehouse, 'warehouseId') == warehouseId.value) {
        return StockItem(
          productId: productId,
          physicalQuantity: Quantity.create(
            readInt(warehouse, 'physicalQuantity'),
          ).getOrThrow(),
        );
      }
    }
    return null;
  }

  @override
  Future<void> save(Warehouse warehouse) async {
    // Contrato legado usado por fluxos que serão substituídos por chamadas
    // diretas à API. Ajusta cada item existente para manter compatibilidade.
    for (final item in warehouse.stockItems) {
      await adjustStock(
        warehouseId: warehouse.id,
        productId: item.productId,
        physicalQuantity: item.physicalQuantity.value,
      );
    }
  }

  @override
  Future<Warehouse> createWarehouse({
    required String code,
    required String name,
  }) async {
    final data = await _api.post(
      '/api/inventory/warehouses',
      data: {'code': code, 'name': name},
    );
    if (data is! Map) {
      throw StateError('Resposta inesperada ao cadastrar depósito.');
    }
    final json = Map<String, dynamic>.from(data);
    return Warehouse(
      id: WarehouseId(readString(json, 'id')),
      code: readString(json, 'code'),
      name: readString(json, 'name'),
    );
  }

  @override
  Future<void> adjustStock({
    required WarehouseId warehouseId,
    required ProductId productId,
    required int physicalQuantity,
  }) async {
    await _api.patch(
      '/api/inventory/stock/${warehouseId.value}/products/${productId.value}',
      data: {'physicalQuantity': physicalQuantity},
    );
  }

  List<_StockRow> _stockRows(dynamic data) {
    if (data is! List) return const [];
    return data.whereType<Map>().map((raw) {
      final json = Map<String, dynamic>.from(raw);
      return _StockRow(
        productId: ProductId(readString(json, 'productId')),
        physicalQuantity: readInt(json, 'physicalQuantity'),
        warehouses: readMapList(json, 'warehouses')
            .map(
              (w) => _WarehouseStockRow(
                warehouseId: readString(w, 'warehouseId'),
                physicalQuantity: readInt(w, 'physicalQuantity'),
              ),
            )
            .toList(),
      );
    }).toList();
  }
}

class _StockRow {
  final ProductId productId;
  final int physicalQuantity;
  final List<_WarehouseStockRow> warehouses;

  const _StockRow({
    required this.productId,
    required this.physicalQuantity,
    required this.warehouses,
  });
}

class _WarehouseStockRow {
  final String warehouseId;
  final int physicalQuantity;

  const _WarehouseStockRow({
    required this.warehouseId,
    required this.physicalQuantity,
  });
}
