// ignore_for_file: prefer_initializing_formals
import 'package:ecommerce_b2b/modules/catalog/product/model/product.dart';
import 'package:ecommerce_b2b/modules/catalog/product/model/repositories/product_repository.dart';
import 'package:ecommerce_b2b/modules/inventory/warehouse/model/repositories/inventory_repository.dart';
import 'package:ecommerce_b2b/modules/inventory/warehouse/model/warehouse.dart';
import 'package:ecommerce_b2b/modules/shared_kernel/model/common/ids/product_id.dart';
import 'package:ecommerce_b2b/modules/shared_kernel/model/common/ids/warehouse_id.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';

part 'inventory_state.dart';

/// Estado compartilhado pelas abas de Controle de Estoque e Depósitos.
class InventoryCubit extends Cubit<InventoryState> {
  final InventoryRepository _inventoryRepository;
  final ProductRepository _productRepository;

  InventoryCubit(this._inventoryRepository, this._productRepository)
    : super(InventoryInitial());

  Future<void> load() async {
    // Mantém os dados atuais durante pull-to-refresh e mutações; o indicador de
    // carregamento só substitui a tela quando ainda não há conteúdo.
    if (state is! InventoryLoaded) emit(InventoryLoading());
    try {
      final warehouses = await _inventoryRepository.getAll();
      final consolidatedStock = await _inventoryRepository
          .getConsolidatedStock();
      final allProducts = await _productRepository.getAll();

      final stockMap = <String, int>{
        for (final item in consolidatedStock)
          item.productId.value: item.physicalQuantity.value,
      };

      if (isClosed) return;
      emit(
        InventoryLoaded(
          products: allProducts.where((product) => product.active).toList(),
          warehouses: warehouses,
          consolidatedStock: stockMap,
        ),
      );
    } catch (error) {
      if (isClosed) return;
      emit(InventoryFailure(error.toString()));
    }
  }

  Future<void> addWarehouse({
    required String code,
    required String name,
  }) async {
    await _inventoryRepository.createWarehouse(code: code, name: name);
    await load();
    _throwIfLoadFailed();
  }

  Future<void> adjustStock({
    required String warehouseId,
    required String productId,
    required int physicalQuantity,
  }) async {
    await _inventoryRepository.adjustStock(
      warehouseId: WarehouseId(warehouseId),
      productId: ProductId(productId),
      physicalQuantity: physicalQuantity,
    );
    await load();
    _throwIfLoadFailed();
  }

  void _throwIfLoadFailed() {
    final current = state;
    if (current is InventoryFailure) {
      throw StateError(current.message);
    }
  }
}
