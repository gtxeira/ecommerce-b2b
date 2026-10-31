import 'package:dio/dio.dart';
import 'package:ecommerce_b2b/app/core/network/api_client.dart';
import 'package:ecommerce_b2b/app/core/network/session_events.dart';
import 'package:ecommerce_b2b/app/core/network/token_store.dart';
import 'package:ecommerce_b2b/modules/inventory/warehouse/infrastructure/repositories/api_inventory_repository.dart';
import 'package:ecommerce_b2b/modules/shared_kernel/domain/common/ids/product_id.dart';
import 'package:ecommerce_b2b/modules/shared_kernel/domain/common/ids/warehouse_id.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../support/fake_http_adapter.dart';

void main() {
  late SessionEvents events;

  ApiInventoryRepository buildRepository(FakeHttpAdapter adapter) {
    final dio = Dio()..httpClientAdapter = adapter;
    final client = ApiClient(
      baseUrl: 'http://localhost:5143',
      dio: dio,
      refreshDio: dio,
      tokenStore: InMemoryTokenStore(),
      sessionEvents: events,
    );
    return ApiInventoryRepository(client);
  }

  Map<String, dynamic> stockJson() => {
    'productId': 'p1',
    'physicalQuantity': 150,
    'reservedQuantity': 15,
    'availableQuantity': 135,
    'warehouses': [
      {
        'warehouseId': 'wh-main',
        'warehouseName': 'Depósito Central',
        'physicalQuantity': 100,
        'reservedQuantity': 10,
        'availableQuantity': 90,
      },
      {
        'warehouseId': 'wh-south',
        'warehouseName': 'Depósito Sul',
        'physicalQuantity': 50,
        'reservedQuantity': 5,
        'availableQuantity': 45,
      },
    ],
  };

  setUp(() => events = SessionEvents());
  tearDown(() => events.dispose());

  group('ApiInventoryRepository', () {
    test(
      'should merge warehouses and stock into Warehouse aggregates',
      () async {
        final adapter = FakeHttpAdapter((options) async {
          if (options.path == '/api/inventory/warehouses') {
            return jsonResponse(
              successEnvelope([
                {'id': 'wh-main', 'code': 'MAIN', 'name': 'Depósito Central'},
                {'id': 'wh-south', 'code': 'SOUTH', 'name': 'Depósito Sul'},
              ]),
            );
          }
          return jsonResponse(successEnvelope([stockJson()]));
        });
        final repository = buildRepository(adapter);

        final warehouses = await repository.getAll();

        expect(warehouses, hasLength(2));
        expect(
          warehouses.first
              .getStockItem(const ProductId('p1'))!
              .physicalQuantity
              .value,
          100,
        );
      },
    );

    test('should expose consolidated physical quantities', () async {
      final adapter = FakeHttpAdapter(
        (options) async => jsonResponse(successEnvelope([stockJson()])),
      );
      final repository = buildRepository(adapter);

      final stock = await repository.getConsolidatedStock();

      expect(stock.single.productId.value, 'p1');
      expect(stock.single.physicalQuantity.value, 150);
    });

    test('should PATCH the physical quantity', () async {
      RequestOptions? captured;
      final adapter = FakeHttpAdapter((options) async {
        captured = options;
        return jsonResponse(
          successEnvelope({
            'warehouseId': 'wh-main',
            'warehouseName': 'Depósito Central',
            'physicalQuantity': 80,
            'reservedQuantity': 10,
            'availableQuantity': 70,
          }),
        );
      });
      final repository = buildRepository(adapter);

      await repository.adjustStock(
        warehouseId: const WarehouseId('wh-main'),
        productId: const ProductId('p1'),
        physicalQuantity: 80,
      );

      expect(captured!.method, 'PATCH');
      expect(captured!.path, '/api/inventory/stock/wh-main/products/p1');
      expect((captured!.data as Map)['physicalQuantity'], 80);
    });
  });
}
