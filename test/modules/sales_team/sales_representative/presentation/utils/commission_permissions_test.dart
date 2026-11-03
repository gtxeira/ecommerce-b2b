import 'package:ecommerce_b2b/modules/identity_access/model/enums/user_role.dart';
import 'package:ecommerce_b2b/modules/identity_access/model/user_session.dart';
import 'package:ecommerce_b2b/modules/sales_team/sales_representative/model/commission.dart';
import 'package:ecommerce_b2b/modules/sales_team/sales_representative/model/enums/commission_status.dart';
import 'package:ecommerce_b2b/modules/sales_team/sales_representative/presentation/utils/commission_permissions.dart';
import 'package:ecommerce_b2b/modules/shared_kernel/model/common/ids/company_id.dart';
import 'package:ecommerce_b2b/modules/shared_kernel/model/common/ids/user_id.dart';
import 'package:ecommerce_b2b/modules/shared_kernel/model/finance/value_objects/money.dart';
import 'package:ecommerce_b2b/modules/shared_kernel/model/finance/value_objects/percentage.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  UserSession session(UserRole role, String id) =>
      UserSession(userId: UserId(id), role: role);

  Commission commission(String? ownerId) => Commission(
    id: 10,
    baseAmount: Money.create(1000).getOrThrow(),
    rate: Percentage.create(5).getOrThrow(),
    amount: Money.create(50).getOrThrow(),
    status: CommissionStatus.pending,
    representativeId: ownerId,
  );

  test('representante não gerencia nem a própria comissão', () {
    expect(
      canManageCommissionStatus(
        session(UserRole.representative, 'rep-1'),
        commission('rep-1'),
      ),
      isFalse,
    );
  });

  test('supervisor não gerencia a própria comissão', () {
    expect(
      canManageCommissionStatus(
        session(UserRole.supervisor, 'sup-1'),
        commission('sup-1'),
      ),
      isFalse,
    );
  });

  test('supervisor gerencia a comissão de um subordinado', () {
    expect(
      canManageCommissionStatus(
        session(UserRole.supervisor, 'sup-1'),
        commission('rep-1'),
      ),
      isTrue,
    );
  });

  test('supervisor nega quando o dono não veio no payload', () {
    expect(
      canManageCommissionStatus(
        session(UserRole.supervisor, 'sup-1'),
        commission(null),
      ),
      isFalse,
    );
  });

  test('finance e admin gerenciam qualquer comissão', () {
    for (final role in [UserRole.finance, UserRole.admin]) {
      expect(
        canManageCommissionStatus(
          session(role, 'backoffice-1'),
          commission('rep-1'),
        ),
        isTrue,
        reason: 'papel $role',
      );
    }
  });

  test('comprador não gerencia comissão', () {
    expect(
      canManageCommissionStatus(
        UserSession(
          userId: const UserId('buyer-1'),
          role: UserRole.buyer,
          companyId: const CompanyId('c1'),
        ),
        commission('rep-1'),
      ),
      isFalse,
    );
  });
}
