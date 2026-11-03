import 'package:ecommerce_b2b/modules/identity_access/model/demo_account.dart';
import 'package:ecommerce_b2b/modules/identity_access/model/enums/user_role.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('lista as seis contas do seed com e-mails únicos', () {
    expect(DemoAccounts.builtIn, hasLength(6));
    expect(DemoAccounts.password, 'password123');

    final emails = DemoAccounts.builtIn.map((account) => account.email).toSet();
    expect(emails, hasLength(DemoAccounts.builtIn.length));
  });

  test('cobre todos os papéis usados na demonstração', () {
    final roles = DemoAccounts.builtIn.map((account) => account.role).toSet();

    expect(roles, containsAll(UserRole.values));
  });

  test('compradores têm empresa e posição para exibição', () {
    final buyers = DemoAccounts.builtIn.where(
      (account) => account.role == UserRole.buyer,
    );

    expect(buyers, hasLength(2));
    for (final buyer in buyers) {
      expect(buyer.companyId, isNotNull);
      expect(buyer.companyLabel, isNotNull);
      expect(buyer.positionTitle, isNotNull);
    }
  });

  test('iniciais são derivadas do nome completo', () {
    final carlos = DemoAccounts.builtIn.firstWhere(
      (account) => account.email == 'buyer@test.com',
    );
    expect(carlos.initials, 'CC');
  });
}
