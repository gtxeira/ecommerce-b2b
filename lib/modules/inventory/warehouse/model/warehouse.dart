import 'package:ecommerce_b2b/modules/shared_kernel/model/entity.dart';
import 'package:ecommerce_b2b/modules/shared_kernel/model/common/ids/warehouse_id.dart';
import 'package:ecommerce_b2b/modules/inventory/warehouse/model/stock_item.dart';

/// Raiz do Agregado que representa um Armazém/Depósito.
class Warehouse extends Entity<WarehouseId> {
  /// Código identificador interno do armazém.
  final String code;
  /// Nome do armazém.
  final String name;
  final List<StockItem> _stockItems;

  /// Construtor do Armazém.
  Warehouse({
    required WarehouseId id,
    required this.code,
    required this.name,
    List<StockItem>? stockItems,
  })  : _stockItems = stockItems ?? [],
        super(id);

  /// Lista de itens em estoque neste armazém.
  List<StockItem> get stockItems => List.unmodifiable(_stockItems);

  /// Atualiza ou adiciona um item ao estoque do armazém.
  void updateStock(StockItem item) {
    final index = _stockItems.indexWhere((i) => i.productId == item.productId);
    if (index >= 0) {
      _stockItems[index] = item;
    } else {
      _stockItems.add(item);
    }
  }

  /// Recupera a informação de estoque de um produto específico.
  StockItem? getStockItem(dynamic productId) {
    try {
      return _stockItems.firstWhere((i) => i.productId == productId);
    } catch (_) {
      return null;
    }
  }
}
