import 'package:ecommerce_b2b/app/core/di/service_locator.dart';
import 'package:ecommerce_b2b/app/core/network/api_client.dart';
import 'package:ecommerce_b2b/modules/catalog/product/application/get_products/get_products_use_case.dart';
import 'package:ecommerce_b2b/modules/identity_access/model/repositories/auth_repository.dart';
import 'package:ecommerce_b2b/modules/order_flow/sales_order/model/repositories/sales_order_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';

void main() {
  group('Service Locator Tests', () {
    setUp(() async {
      await GetIt.instance.reset();
    });

    tearDown(() async {
      await GetIt.instance.reset();
    });

    test('should register the API client and migrated dependencies', () async {
      await setupServiceLocator();

      expect(GetIt.instance.isRegistered<ApiClient>(), isTrue);
      expect(GetIt.instance.isRegistered<AuthRepository>(), isTrue);
      expect(GetIt.instance.isRegistered<SalesOrderRepository>(), isTrue);
      expect(GetIt.instance.isRegistered<GetProductsUseCase>(), isTrue);

      expect(GetIt.instance<ApiClient>(), isNotNull);
      expect(GetIt.instance<GetProductsUseCase>(), isNotNull);
    });
  });
}
