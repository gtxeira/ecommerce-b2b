import 'package:get_it/get_it.dart';

import 'package:ecommerce_b2b/app/core/events/order_events.dart';
import 'package:ecommerce_b2b/app/core/network/api_client.dart';
import 'package:ecommerce_b2b/app/core/network/session_events.dart';
import 'package:ecommerce_b2b/app/core/network/token_store.dart';

// Repositórios (interfaces)
import 'package:ecommerce_b2b/modules/catalog/price_table/model/repositories/price_table_repository.dart';
import 'package:ecommerce_b2b/modules/catalog/price_table/model/repositories/pricing_repository.dart';
import 'package:ecommerce_b2b/modules/catalog/product/model/repositories/product_repository.dart';
import 'package:ecommerce_b2b/modules/customer_management/company/model/repositories/company_repository.dart';
import 'package:ecommerce_b2b/modules/customer_portal/boleto/model/repositories/boleto_repository.dart';
import 'package:ecommerce_b2b/modules/customer_portal/return_request/model/repositories/return_request_repository.dart';
import 'package:ecommerce_b2b/modules/identity_access/model/repositories/auth_repository.dart';
import 'package:ecommerce_b2b/modules/identity_access/model/repositories/user_repository.dart';
import 'package:ecommerce_b2b/modules/inventory/warehouse/model/repositories/inventory_repository.dart';
import 'package:ecommerce_b2b/modules/logistics/shipment/model/repositories/shipment_repository.dart';
import 'package:ecommerce_b2b/modules/logistics/shipment/model/repositories/tracking_repository.dart';
import 'package:ecommerce_b2b/modules/order_flow/quote/model/repositories/quote_repository.dart';
import 'package:ecommerce_b2b/modules/order_flow/sales_order/model/repositories/sales_order_repository.dart';
import 'package:ecommerce_b2b/modules/sales_team/sales_representative/model/repositories/sales_representative_repository.dart';

// Implementações HTTP
import 'package:ecommerce_b2b/modules/catalog/price_table/infrastructure/repositories/api_price_table_repository.dart';
import 'package:ecommerce_b2b/modules/catalog/price_table/infrastructure/repositories/api_pricing_repository.dart';
import 'package:ecommerce_b2b/modules/catalog/product/infrastructure/repositories/api_product_repository.dart';
import 'package:ecommerce_b2b/modules/customer_management/company/infrastructure/repositories/api_company_repository.dart';
import 'package:ecommerce_b2b/modules/customer_portal/boleto/infrastructure/repositories/api_boleto_repository.dart';
import 'package:ecommerce_b2b/modules/customer_portal/return_request/infrastructure/repositories/api_return_request_repository.dart';
import 'package:ecommerce_b2b/modules/identity_access/infrastructure/repositories/api_auth_repository.dart';
import 'package:ecommerce_b2b/modules/identity_access/infrastructure/repositories/api_user_repository.dart';
import 'package:ecommerce_b2b/modules/inventory/warehouse/infrastructure/repositories/api_inventory_repository.dart';
import 'package:ecommerce_b2b/modules/logistics/shipment/infrastructure/repositories/api_shipment_repository.dart';
import 'package:ecommerce_b2b/modules/logistics/shipment/infrastructure/repositories/api_tracking_repository.dart';
import 'package:ecommerce_b2b/modules/order_flow/quote/infrastructure/repositories/api_quote_repository.dart';
import 'package:ecommerce_b2b/modules/order_flow/sales_order/infrastructure/repositories/api_sales_order_repository.dart';
import 'package:ecommerce_b2b/modules/sales_team/sales_representative/infrastructure/repositories/api_sales_representative_repository.dart';

// APIs de fluxo
import 'package:ecommerce_b2b/modules/logistics/infrastructure/api/fulfillment_api.dart';
import 'package:ecommerce_b2b/modules/order_flow/sales_order/infrastructure/api/finance_api.dart';

// Casos de uso
import 'package:ecommerce_b2b/modules/catalog/price_table/application/get_price_tables/get_price_tables_use_case.dart';
import 'package:ecommerce_b2b/modules/catalog/price_table/application/save_price_table/save_price_table_use_case.dart';
import 'package:ecommerce_b2b/modules/catalog/product/application/delete_product/delete_product_use_case.dart';
import 'package:ecommerce_b2b/modules/catalog/product/application/delete_product_variant/delete_product_variant_use_case.dart';
import 'package:ecommerce_b2b/modules/catalog/product/application/get_products/get_products_use_case.dart';
import 'package:ecommerce_b2b/modules/catalog/product/application/save_product/save_product_use_case.dart';
import 'package:ecommerce_b2b/modules/customer_management/company/application/add_authorized_buyer/add_authorized_buyer_use_case.dart';
import 'package:ecommerce_b2b/modules/customer_management/company/application/get_companies/get_companies_use_case.dart';
import 'package:ecommerce_b2b/modules/customer_management/company/application/register_company/register_company_use_case.dart';
import 'package:ecommerce_b2b/modules/customer_portal/boleto/application/download_boleto/download_boleto_use_case.dart';
import 'package:ecommerce_b2b/modules/customer_portal/purchase_history/application/get_purchase_history/get_purchase_history_use_case.dart';
import 'package:ecommerce_b2b/modules/customer_portal/return_request/application/get_return_requests/get_return_requests_use_case.dart';
import 'package:ecommerce_b2b/modules/customer_portal/return_request/application/open_return_request/open_return_request_use_case.dart';
import 'package:ecommerce_b2b/modules/identity_access/application/login/login_use_case.dart';
import 'package:ecommerce_b2b/modules/logistics/application/procces_order/process_order_shipment_use_case.dart';
import 'package:ecommerce_b2b/modules/order_flow/sales_order/application/get_finance_summary/get_finance_summary_use_case.dart';
import 'package:ecommerce_b2b/modules/order_flow/sales_order/application/get_pending_finance_reviews/get_pending_finance_reviews_use_case.dart';
import 'package:ecommerce_b2b/modules/order_flow/sales_order/application/process_finance_review/process_finance_review_use_case.dart';
import 'package:ecommerce_b2b/modules/sales_team/sales_representative/application/get_commissions/get_representative_commissions_use_case.dart';
import 'package:ecommerce_b2b/modules/sales_team/sales_representative/application/get_customers/get_customer_portfolio_use_case.dart';
import 'package:ecommerce_b2b/modules/sales_team/sales_representative/application/get_quotes/get_recent_quotes_use_case.dart';
import 'package:ecommerce_b2b/modules/sales_team/sales_representative/application/update_commission_status/update_commission_status_use_case.dart';

// Cubits
import 'package:ecommerce_b2b/modules/catalog/price_table/presentation/cubit/price_table_cubit.dart';
import 'package:ecommerce_b2b/modules/catalog/product/presentation/cubit/catalog_cubit.dart';
import 'package:ecommerce_b2b/modules/customer_management/company/presentation/cubit/company_management_cubit.dart';
import 'package:ecommerce_b2b/modules/customer_portal/presentation/cubit/customer_portal_cubit.dart';
import 'package:ecommerce_b2b/modules/identity_access/presentation/cubit/auth_cubit.dart';
import 'package:ecommerce_b2b/modules/identity_access/presentation/cubit/user_management_cubit.dart';
import 'package:ecommerce_b2b/modules/inventory/warehouse/presentation/cubit/inventory_cubit.dart';
import 'package:ecommerce_b2b/modules/order_flow/quote/presentation/cubit/quote_cubit.dart';
import 'package:ecommerce_b2b/modules/order_flow/sales_order/presentation/cubit/open_orders_cubit.dart';
import 'package:ecommerce_b2b/modules/order_flow/sales_order/presentation/cubit/order_list_cubit.dart';
import 'package:ecommerce_b2b/modules/order_flow/sales_order/presentation/finance_review/cubit/finance_review_cubit.dart';
import 'package:ecommerce_b2b/modules/order_flow/sales_order/presentation/finance_review/cubit/finance_summary_cubit.dart';
import 'package:ecommerce_b2b/modules/sales_team/sales_representative/presentation/cubit/commission_list_cubit.dart';
import 'package:ecommerce_b2b/modules/sales_team/sales_representative/presentation/cubit/representative_dashboard_cubit.dart';

final getIt = GetIt.instance;

Future<void> setupServiceLocator() async {
  // --- Rede / sessão ---
  final tokenStore = SecureTokenStore();
  final sessionEvents = SessionEvents();
  final apiClient = ApiClient(
    tokenStore: tokenStore,
    sessionEvents: sessionEvents,
  );

  final orderEvents = OrderEvents();

  getIt.registerSingleton<TokenStore>(tokenStore);
  getIt.registerSingleton<SessionEvents>(sessionEvents);
  getIt.registerSingleton<OrderEvents>(orderEvents);
  getIt.registerSingleton<ApiClient>(apiClient);

  // --- Repositórios HTTP ---
  getIt.registerLazySingleton<AuthRepository>(
    () => ApiAuthRepository(getIt<ApiClient>(), getIt<TokenStore>()),
  );
  getIt.registerLazySingleton<UserRepository>(
    () => ApiUserRepository(getIt<ApiClient>()),
  );
  getIt.registerLazySingleton<ProductRepository>(
    () => ApiProductRepository(getIt<ApiClient>()),
  );
  getIt.registerLazySingleton<PriceTableRepository>(
    () => ApiPriceTableRepository(getIt<ApiClient>()),
  );
  getIt.registerLazySingleton<PricingRepository>(
    () => ApiPricingRepository(getIt<ApiClient>()),
  );
  getIt.registerLazySingleton<CompanyRepository>(
    () => ApiCompanyRepository(getIt<ApiClient>()),
  );
  getIt.registerLazySingleton<SalesRepresentativeRepository>(
    () => ApiSalesRepresentativeRepository(getIt<ApiClient>()),
  );
  getIt.registerLazySingleton<SalesOrderRepository>(
    () => ApiSalesOrderRepository(getIt<ApiClient>()),
  );
  getIt.registerLazySingleton<InventoryRepository>(
    () => ApiInventoryRepository(getIt<ApiClient>()),
  );
  getIt.registerLazySingleton<QuoteRepository>(
    () => ApiQuoteRepository(getIt<ApiClient>()),
  );
  getIt.registerLazySingleton<ShipmentRepository>(
    () => ApiShipmentRepository(getIt<ApiClient>()),
  );
  getIt.registerLazySingleton<TrackingRepository>(
    () => ApiTrackingRepository(getIt<ApiClient>()),
  );
  getIt.registerLazySingleton<ReturnRequestRepository>(
    () => ApiReturnRequestRepository(getIt<ApiClient>()),
  );
  getIt.registerLazySingleton<BoletoRepository>(
    () => ApiBoletoRepository(getIt<ApiClient>()),
  );

  // --- APIs de fluxo ---
  getIt.registerLazySingleton(() => FinanceApi(getIt<ApiClient>()));
  getIt.registerLazySingleton(() => FulfillmentApi(getIt<ApiClient>()));

  // --- Casos de uso ---
  getIt.registerLazySingleton(() => LoginUseCase(getIt<AuthRepository>()));
  getIt.registerLazySingleton(
    () => GetRepresentativeCommissionsUseCase(
      getIt<SalesRepresentativeRepository>(),
    ),
  );
  getIt.registerLazySingleton(
    () => GetCustomerPortfolioUseCase(getIt<SalesRepresentativeRepository>()),
  );
  getIt.registerLazySingleton(
    () => GetRecentQuotesUseCase(getIt<QuoteRepository>()),
  );
  getIt.registerLazySingleton(
    () => UpdateCommissionStatusUseCase(getIt<SalesRepresentativeRepository>()),
  );
  getIt.registerLazySingleton(
    () => GetProductsUseCase(getIt<ProductRepository>()),
  );
  getIt.registerLazySingleton(
    () => SaveProductUseCase(getIt<ProductRepository>()),
  );
  getIt.registerLazySingleton(
    () => DeleteProductUseCase(getIt<ProductRepository>()),
  );
  getIt.registerLazySingleton(
    () => DeleteProductVariantUseCase(getIt<ProductRepository>()),
  );
  getIt.registerLazySingleton(
    () => GetPriceTablesUseCase(getIt<PriceTableRepository>()),
  );
  getIt.registerLazySingleton(
    () => SavePriceTableUseCase(getIt<PriceTableRepository>()),
  );
  getIt.registerLazySingleton(
    () => GetCompaniesUseCase(getIt<CompanyRepository>()),
  );
  getIt.registerLazySingleton(
    () => RegisterCompanyUseCase(getIt<CompanyRepository>()),
  );
  getIt.registerLazySingleton(
    () => AddAuthorizedBuyerUseCase(getIt<CompanyRepository>()),
  );
  getIt.registerLazySingleton(
    () => ProcessFinanceReviewUseCase(getIt<FinanceApi>()),
  );
  getIt.registerLazySingleton(
    () => ProcessOrderShipmentUseCase(getIt<FulfillmentApi>()),
  );
  getIt.registerLazySingleton(
    () => OpenReturnRequestUseCase(getIt<ReturnRequestRepository>()),
  );
  getIt.registerLazySingleton(
    () => DownloadBoletoUseCase(getIt<BoletoRepository>()),
  );
  getIt.registerLazySingleton(
    () => GetPurchaseHistoryUseCase(getIt<SalesOrderRepository>()),
  );
  getIt.registerLazySingleton(
    () => GetReturnRequestsUseCase(getIt<ReturnRequestRepository>()),
  );
  getIt.registerLazySingleton(
    () => GetPendingFinanceReviewsUseCase(getIt<FinanceApi>()),
  );
  getIt.registerLazySingleton(
    () => GetFinanceSummaryUseCase(getIt<FinanceApi>()),
  );

  // --- Cubits ---
  getIt.registerLazySingleton(
    () => AuthCubit(
      loginUseCase: getIt<LoginUseCase>(),
      authRepository: getIt<AuthRepository>(),
      sessionEvents: getIt<SessionEvents>(),
    ),
  );

  getIt.registerFactory(() => UserManagementCubit(getIt<UserRepository>()));

  getIt.registerFactory(
    () => RepresentativeDashboardCubit(
      getCommissionsUseCase: getIt<GetRepresentativeCommissionsUseCase>(),
      getCustomerPortfolioUseCase: getIt<GetCustomerPortfolioUseCase>(),
      getRecentQuotesUseCase: getIt<GetRecentQuotesUseCase>(),
      representativeRepository: getIt<SalesRepresentativeRepository>(),
      updateCommissionStatusUseCase: getIt<UpdateCommissionStatusUseCase>(),
    ),
  );

  getIt.registerFactory(
    () => CommissionListCubit(
      getCommissionsUseCase: getIt<GetRepresentativeCommissionsUseCase>(),
      representativeRepository: getIt<SalesRepresentativeRepository>(),
      updateCommissionStatusUseCase: getIt<UpdateCommissionStatusUseCase>(),
    ),
  );

  getIt.registerFactory(
    () => FinanceReviewCubit(
      getPendingReviews: getIt<GetPendingFinanceReviewsUseCase>(),
      processReview: getIt<ProcessFinanceReviewUseCase>(),
      orderRepository: getIt<SalesOrderRepository>(),
      orderEvents: getIt<OrderEvents>(),
    ),
  );

  getIt.registerFactory(
    () => FinanceSummaryCubit(
      getIt<GetFinanceSummaryUseCase>(),
      getIt<OrderEvents>(),
    ),
  );

  getIt.registerFactory(
    () => OpenOrdersCubit(getIt<SalesOrderRepository>(), getIt<OrderEvents>()),
  );

  getIt.registerFactory(
    () => CompanyManagementCubit(
      getCompaniesUseCase: getIt<GetCompaniesUseCase>(),
      registerCompanyUseCase: getIt<RegisterCompanyUseCase>(),
      addAuthorizedBuyerUseCase: getIt<AddAuthorizedBuyerUseCase>(),
      representativeRepository: getIt<SalesRepresentativeRepository>(),
    ),
  );

  getIt.registerFactory(
    () => CatalogCubit(
      getIt<GetProductsUseCase>(),
      getIt<SaveProductUseCase>(),
      getIt<DeleteProductUseCase>(),
      getIt<DeleteProductVariantUseCase>(),
      getIt<InventoryRepository>(),
    ),
  );

  getIt.registerFactory(
    () => PriceTableCubit(
      getIt<GetPriceTablesUseCase>(),
      getIt<SavePriceTableUseCase>(),
    ),
  );

  getIt.registerFactory(
    () => InventoryCubit(
      getIt<InventoryRepository>(),
      getIt<ProductRepository>(),
    ),
  );

  getIt.registerFactory(
    () => QuoteCubit(getIt<QuoteRepository>(), getIt<OrderEvents>()),
  );

  getIt.registerFactory(
    () => OrderListCubit(
      getIt<SalesOrderRepository>(),
      getIt<CompanyRepository>(),
    ),
  );

  getIt.registerFactory(
    () => CustomerPortalCubit(
      getPurchaseHistoryUseCase: getIt<GetPurchaseHistoryUseCase>(),
      getReturnRequestsUseCase: getIt<GetReturnRequestsUseCase>(),
      downloadBoletoUseCase: getIt<DownloadBoletoUseCase>(),
      openReturnRequestUseCase: getIt<OpenReturnRequestUseCase>(),
    ),
  );
}
