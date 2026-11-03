import 'package:ecommerce_b2b/app/core/routes/app_pages.dart';
import 'package:ecommerce_b2b/app/core/routes/commission_routes.dart';
import 'package:ecommerce_b2b/app/core/routes/order_routes.dart';
import 'package:ecommerce_b2b/modules/identity_access/model/enums/user_role.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AppPage.orders', () {
    test('usa o mesmo path da rota de pedidos', () {
      expect(AppPage.orders.path, OrderRoutes.list);
    });

    test('aparece na sidebar dos papéis internos', () {
      for (final role in [
        UserRole.admin,
        UserRole.finance,
        UserRole.representative,
        UserRole.supervisor,
      ]) {
        expect(
          AppPage.sidebarPagesFor(role),
          contains(AppPage.orders),
          reason: 'papel $role',
        );
      }
    });

    test('não aparece para o comprador (usa o portal)', () {
      expect(AppPage.sidebarPagesFor(UserRole.buyer), isEmpty);
    });

    test('home continua sendo a primeira entrada de todos os papéis', () {
      for (final role in UserRole.values.where(
        (role) => role != UserRole.buyer,
      )) {
        expect(AppPage.sidebarPagesFor(role).first, AppPage.home);
      }
    });
  });

  group('AppPage.quotes', () {
    test('aparece para os papéis que podem ver ou converter orçamentos', () {
      for (final role in [
        UserRole.admin,
        UserRole.representative,
        UserRole.supervisor,
      ]) {
        expect(
          AppPage.sidebarPagesFor(role),
          contains(AppPage.quotes),
          reason: 'papel $role',
        );
      }
    });

    test('não aparece para financeiro nem comprador', () {
      expect(
        AppPage.sidebarPagesFor(UserRole.finance),
        isNot(contains(AppPage.quotes)),
      );
      expect(AppPage.sidebarPagesFor(UserRole.buyer), isEmpty);
    });
  });

  group('AppPage.commissions', () {
    test('usa a rota dedicada de comissões', () {
      expect(AppPage.commissions.path, CommissionRoutes.list);
    });

    test('aparece na sidebar dos papéis internos', () {
      for (final role in [
        UserRole.representative,
        UserRole.supervisor,
        UserRole.finance,
        UserRole.admin,
      ]) {
        expect(
          AppPage.sidebarPagesFor(role),
          contains(AppPage.commissions),
          reason: 'papel $role',
        );
      }
    });

    test('não aparece para o comprador', () {
      expect(
        AppPage.sidebarPagesFor(UserRole.buyer),
        isNot(contains(AppPage.commissions)),
      );
    });
  });
}
