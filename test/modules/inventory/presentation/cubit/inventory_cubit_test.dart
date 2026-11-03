import 'package:ecommerce_b2b/modules/catalog/product/model/product.dart';
import 'package:ecommerce_b2b/modules/catalog/product/model/repositories/product_repository.dart';
import 'package:ecommerce_b2b/modules/inventory/warehouse/model/repositories/inventory_repository.dart';
import 'package:ecommerce_b2b/modules/inventory/warehouse/model/stock_item.dart';
import 'package:ecommerce_b2b/modules/inventory/warehouse/model/warehouse.dart';
import 'package:ecommerce_b2b/modules/inventory/warehouse/presentation/cubit/inventory_cubit.dart';
import 'package:ecommerce_b2b/modules/shared_kernel/model/common/ids/product_id.dart';
import 'package:ecommerce_b2b/modules/shared_kernel/model/common/ids/warehouse_id.dart';
import 'package:ecommerce_b2b/modules/shared_kernel/model/finance/value_objects/money.dart';
import 'package:ecommerce_b2b/modules/shared_kernel/model/finance/value_objects/quantity.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockInventoryRepository extends Mock implements InventoryRepository {}

class MockProductRepository extends Mock implements ProductRepository {}

Product _product(String id, {bool active = true}) => Product(
  id: ProductId(id),
  sku: 'SKU-$id',
  name: 'Produto $id',
  description: 'Descrição',
  basePrice: Money.create(10).getOrThrow(),
  active: active,
);

Warehouse _warehouse({String id = 'w1', String name = 'Centro'}) => Warehouse(
  id: WarehouseId(id),
  code: 'W-$id',
  name: name,
  stockItems: [
    StockItem(
      productId: const ProductId('p1'),
      physicalQuantity: Quantity.create(7).getOrThrow(),
    ),
  ],
);

void main() {
  late MockInventoryRepository inventory;
  late MockProductRepository products;
  late InventoryCubit cubit;

  setUp(() {
    inventory = MockInventoryRepository();
    products = MockProductRepository();
    cubit = InventoryCubit(inventory, products);

    when(() => inventory.getAll()).thenAnswer((_) async => [_warehouse()]);
    when(() => inventory.getConsolidatedStock()).thenAnswer(
      (_) async => [
        StockItem(
          productId: const ProductId('p1'),
          physicalQuantity: Quantity.create(7).getOrThrow(),
        ),
      ],
    );
    when(
      () => products.getAll(),
    ).thenAnswer((_) async => [_product('p1'), _product('p2', active: false)]);
  });

  tearDown(() => cubit.close());

  test('load mantém apenas produtos ativos e consolida o estoque', () async {
    await cubit.load();

    final state = cubit.state as InventoryLoaded;
    expect(state.products.map((product) => product.id.value), ['p1']);
    expect(state.warehouses, hasLength(1));
    expect(state.consolidatedStock, {'p1': 7});
  });

  test('addWarehouse cadastra e recarrega os dados', () async {
    when(() => inventory.createWarehouse(code: 'W2', name: 'Sul')).thenAnswer(
      (_) async =>
          Warehouse(id: const WarehouseId('w2'), code: 'W2', name: 'Sul'),
    );

    await cubit.addWarehouse(code: 'W2', name: 'Sul');

    expect(cubit.state, isA<InventoryLoaded>());
    verify(() => inventory.createWarehouse(code: 'W2', name: 'Sul')).called(1);
    verify(() => inventory.getAll()).called(1);
  });

  test('adjustStock envia o ajuste e recarrega os dados', () async {
    when(
      () => inventory.adjustStock(
        warehouseId: const WarehouseId('w1'),
        productId: const ProductId('p1'),
        physicalQuantity: 12,
      ),
    ).thenAnswer((_) async {});

    await cubit.adjustStock(
      warehouseId: 'w1',
      productId: 'p1',
      physicalQuantity: 12,
    );

    expect(cubit.state, isA<InventoryLoaded>());
    verify(
      () => inventory.adjustStock(
        warehouseId: const WarehouseId('w1'),
        productId: const ProductId('p1'),
        physicalQuantity: 12,
      ),
    ).called(1);
    verify(() => inventory.getAll()).called(1);
  });

  test('load emite Failure quando a API falha', () async {
    when(() => inventory.getAll()).thenThrow(Exception('API off'));

    await cubit.load();

    expect(cubit.state, isA<InventoryFailure>());
  });
}
