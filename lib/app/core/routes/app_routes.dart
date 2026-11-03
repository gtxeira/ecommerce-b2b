import 'dart:async';
import 'package:ecommerce_b2b/app/core/di/service_locator.dart';
import 'package:ecommerce_b2b/app/core/routes/app_pages.dart';
import 'package:ecommerce_b2b/app/core/routes/commission_routes.dart';
import 'package:ecommerce_b2b/app/core/routes/order_routes.dart';
import 'package:ecommerce_b2b/app/core/routes/quote_routes.dart';
import 'package:ecommerce_b2b/app/presentation/layouts/main_layout.dart';
import 'package:ecommerce_b2b/app/presentation/pages/home_page.dart';
import 'package:ecommerce_b2b/modules/identity_access/model/enums/user_role.dart';
import 'package:ecommerce_b2b/modules/identity_access/presentation/cubit/auth_cubit.dart';
import 'package:ecommerce_b2b/modules/identity_access/presentation/pages/login_page.dart';
import 'package:ecommerce_b2b/modules/identity_access/presentation/pages/users_page.dart';
import 'package:ecommerce_b2b/modules/customer_portal/presentation/pages/buyer_catalog_page.dart';
import 'package:ecommerce_b2b/modules/customer_portal/presentation/pages/buyer_home_page.dart';
import 'package:ecommerce_b2b/modules/customer_portal/presentation/pages/buyer_quotes_page.dart';
import 'package:ecommerce_b2b/modules/sales_team/sales_representative/presentation/pages/commission_list_page.dart';
import 'package:ecommerce_b2b/modules/sales_team/sales_representative/presentation/pages/representative_home_page.dart';
import 'package:ecommerce_b2b/modules/order_flow/model/enums/order_status.dart';
import 'package:ecommerce_b2b/modules/order_flow/sales_order/model/sales_order.dart';
import 'package:ecommerce_b2b/modules/order_flow/sales_order/presentation/finance_review/pages/finance_home_page.dart';
import 'package:ecommerce_b2b/modules/order_flow/sales_order/presentation/finance_review/pages/finance_review_page.dart';
import 'package:ecommerce_b2b/modules/order_flow/sales_order/presentation/pages/order_detail_page.dart';
import 'package:ecommerce_b2b/modules/order_flow/sales_order/presentation/pages/order_list_page.dart';
import 'package:ecommerce_b2b/modules/order_flow/sales_order/presentation/pages/billing_page.dart';
import 'package:ecommerce_b2b/modules/customer_management/company/presentation/pages/company_list_page.dart';
import 'package:ecommerce_b2b/modules/catalog/product/presentation/pages/product_list_page.dart';
import 'package:ecommerce_b2b/modules/order_flow/quote/presentation/pages/quote_page.dart';
import 'package:ecommerce_b2b/modules/logistics/presentation/pages/packing_page.dart';
import 'package:ecommerce_b2b/modules/inventory/warehouse/presentation/pages/inventory_page.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

final appRouter = GoRouter(
  initialLocation: AppPage.home.path,
  refreshListenable: _AuthRefreshListenable(getIt<AuthCubit>()),
  redirect: (context, state) {
    final authState = context.read<AuthCubit>().state;
    final isLoggingIn = state.matchedLocation == AppPage.login.path;

    // Enquanto a sessão persistida é verificada, não redireciona: a rota raiz
    // mostra o splash. Redirecionar aqui faria a tela de login piscar no boot.
    if (authState is AuthInitial) {
      return null;
    }

    if (authState is AuthUnauthenticated) {
      return isLoggingIn ? null : AppPage.login.path;
    }

    if (isLoggingIn && authState is AuthAuthenticated) {
      return AppPage.home.path;
    }

    return null;
  },
  routes: [
    GoRoute(
      path: AppPage.login.path,
      builder: (context, state) => const LoginPage(),
    ),
    ShellRoute(
      builder: (context, state, child) {
        final authState = context.watch<AuthCubit>().state;

        // Se for comprador, não mostra o MainLayout (que parece ser para representantes/admin)
        if (authState is AuthAuthenticated &&
            authState.session.role == UserRole.buyer) {
          return child;
        }

        return MainLayout(child: child);
      },
      routes: [
        GoRoute(
          path: AppPage.home.path,
          builder: (context, state) {
            final authState = context.watch<AuthCubit>().state;
            if (authState is AuthInitial) {
              return const _SplashPage();
            }
            if (authState is AuthAuthenticated) {
              final session = authState.session;
              final homeKey = ValueKey(
                'home-${session.role.name}-${session.userId.value}-${session.companyId?.value}',
              );
              if (session.role == UserRole.buyer) {
                return KeyedSubtree(key: homeKey, child: const BuyerHomePage());
              }
              if (session.role == UserRole.representative ||
                  session.role == UserRole.supervisor) {
                return KeyedSubtree(
                  key: homeKey,
                  child: const RepresentativeHomePage(),
                );
              }
              if (session.role == UserRole.finance) {
                return KeyedSubtree(
                  key: homeKey,
                  child: const FinanceHomePage(),
                );
              }
              if (session.role == UserRole.admin) {
                return KeyedSubtree(key: homeKey, child: const HomePage());
              }
            }
            return const HomePage();
          },
        ),
        GoRoute(
          path: OrderRoutes.list,
          redirect: _buyerGuard,
          builder: (context, state) => OrderListPage(
            initialGroup: switch (state.uri.queryParameters['group']) {
              'closed' => OrderStatusGroup.closed,
              _ => OrderStatusGroup.open,
            },
          ),
        ),
        GoRoute(
          path: OrderRoutes.detailPattern,
          redirect: _buyerGuard,
          builder: (context, state) => OrderDetailPage(
            orderId: state.pathParameters['id']!,
            initialOrder: state.extra is SalesOrder
                ? state.extra! as SalesOrder
                : null,
          ),
        ),
        GoRoute(
          path: AppPage.finance.path,
          builder: (context, state) => const FinanceReviewPage(),
        ),
        GoRoute(
          path: AppPage.billing.path,
          builder: (context, state) => const BillingPage(),
        ),
        GoRoute(
          path: AppPage.companies.path,
          builder: (context, state) => CompanyListPage(
            initialRepresentativeId:
                state.uri.queryParameters['representativeId'],
            initialTeamView: state.uri.queryParameters['scope'] == 'team',
          ),
        ),
        GoRoute(
          path: CommissionRoutes.list,
          redirect: _buyerGuard,
          builder: (context, state) => CommissionListPage(
            initialRepresentativeId:
                state.uri.queryParameters['representativeId'],
            initialTeamView: state.uri.queryParameters['scope'] == 'team',
          ),
        ),
        GoRoute(
          path: AppPage.catalog.path,
          builder: (context, state) => const ProductListPage(),
        ),
        GoRoute(
          path: AppPage.quotes.path,
          builder: (context, state) => QuotePage(
            initialTab: state.uri.queryParameters['tab'] == 'list' ? 1 : 0,
          ),
        ),
        GoRoute(
          path: AppPage.logistics.path,
          builder: (context, state) => const PackingPage(),
        ),
        GoRoute(
          path: AppPage.inventory.path,
          builder: (context, state) => const InventoryPage(),
        ),
        GoRoute(
          path: AppPage.users.path,
          builder: (context, state) => const UsersPage(),
        ),
        GoRoute(
          path: '/buyer-catalog',
          builder: (context, state) => const BuyerCatalogPage(),
        ),
        GoRoute(
          path: QuoteRoutes.buyerList,
          redirect: _nonBuyerGuard,
          builder: (context, state) => const BuyerQuotesPage(),
        ),
      ],
    ),
  ],
);

/// Rotas de pedido são leitura interna: o comprador consulta o próprio
/// histórico pelo portal (`/api/me/purchase-history`).
String? _buyerGuard(BuildContext context, GoRouterState state) {
  final authState = context.read<AuthCubit>().state;
  if (authState is AuthAuthenticated &&
      authState.session.role == UserRole.buyer) {
    return AppPage.home.path;
  }
  return null;
}

/// "Meus orçamentos" é a visão do comprador; os demais papéis usam /quotes.
String? _nonBuyerGuard(BuildContext context, GoRouterState state) {
  final authState = context.read<AuthCubit>().state;
  if (authState is AuthAuthenticated &&
      authState.session.role != UserRole.buyer) {
    return AppPage.home.path;
  }
  return null;
}

/// Enquanto os tokens persistidos são validados, evita exibir a Home ou o Login.
class _SplashPage extends StatelessWidget {
  const _SplashPage();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: CircularProgressIndicator()));
  }
}

/// Helper para notificar o GoRouter quando o estado do Cubit mudar
class _AuthRefreshListenable extends ChangeNotifier {
  late final StreamSubscription _subscription;

  _AuthRefreshListenable(AuthCubit cubit) {
    _subscription = cubit.stream.listen((state) {
      notifyListeners();
    });
  }

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}
