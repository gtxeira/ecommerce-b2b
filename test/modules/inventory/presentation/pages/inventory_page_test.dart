import 'package:ecommerce_b2b/modules/catalog/product/model/product.dart';
import 'package:ecommerce_b2b/modules/catalog/product/model/repositories/product_repository.dart';
import 'package:ecommerce_b2b/modules/inventory/warehouse/model/repositories/inventory_repository.dart';
import 'package:ecommerce_b2b/modules/inventory/warehouse/model/stock_item.dart';
import 'package:ecommerce_b2b/modules/inventory/warehouse/model/warehouse.dart';
import 'package:ecommerce_b2b/modules/inventory/warehouse/presentation/cubit/inventory_cubit.dart';
import 'package:ecommerce_b2b/modules/inventory/warehouse/presentation/pages/stock_control_view.dart';
import 'package:ecommerce_b2b/modules/inventory/warehouse/presentation/pages/warehouse_management_view.dart';
import 'package:ecommerce_b2b/modules/shared_kernel/model/common/ids/product_id.dart';
import 'package:ecommerce_b2b/modules/shared_kernel/model/common/ids/warehouse_id.dart';
import 'package:ecommerce_b2b/modules/shared_kernel/model/finance/value_objects/money.dart';
import 'package:ecommerce_b2b/modules/shared_kernel/model/finance/value_objects/quantity.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockInventoryRepository extends Mock implements InventoryRepository {}

class MockProductRepository extends Mock implements ProductRepository {}

void main() {
  testWidgets('o FAB de novo depósito só aparece na aba de depósitos', (
    tester,
  ) async {
    final inventory = MockInventoryRepository();
    final products = MockProductRepository();

    when(() => inventory.getAll()).thenAnswer(
      (_) async => [
        Warehouse(
          id: const WarehouseId('w1'),
          code: 'W1',
          name: 'Centro',
          stockItems: [
            StockItem(
              productId: const ProductId('p1'),
              physicalQuantity: Quantity.create(4).getOrThrow(),
            ),
          ],
        ),
      ],
    );
    when(() => inventory.getConsolidatedStock()).thenAnswer(
      (_) async => [
        StockItem(
          productId: const ProductId('p1'),
          physicalQuantity: Quantity.create(4).getOrThrow(),
        ),
      ],
    );
    when(() => products.getAll()).thenAnswer(
      (_) async => [
        Product(
          id: const ProductId('p1'),
          sku: 'SKU-1',
          name: 'Produto 1',
          description: 'Descrição',
          basePrice: Money.create(10).getOrThrow(),
          active: true,
        ),
      ],
    );

    final cubit = InventoryCubit(inventory, products);
    await cubit.load();
    addTearDown(cubit.close);

    await tester.pumpWidget(
      BlocProvider.value(
        value: cubit,
        child: MaterialApp(
          home: DefaultTabController(
            length: 2,
            child: Scaffold(
              appBar: AppBar(
                bottom: const TabBar(
                  tabs: [
                    Tab(text: 'Controle de Estoque'),
                    Tab(text: 'Depósitos'),
                  ],
                ),
              ),
              body: const TabBarView(
                children: [StockControlView(), WarehouseManagementView()],
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(FloatingActionButton), findsNothing);

    await tester.tap(find.text('Depósitos'));
    await tester.pumpAndSettle();

    expect(find.byType(FloatingActionButton), findsOneWidget);
    expect(find.text('Novo Depósito'), findsOneWidget);
  });
}
