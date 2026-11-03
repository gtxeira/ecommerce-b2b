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
  const both = {CommissionStatus.paid, CommissionStatus.cancelled};
  const cancelOnly = {CommissionStatus.cancelled};
  const none = <CommissionStatus>{};

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

  test('representante é somente leitura', () {
    expect(
      allowedCommissionStatusActions(
        session(UserRole.representative, 'rep-1'),
        commission('rep-1'),
      ),
      none,
    );
  });

  test('representante não altera a comissão de outra pessoa', () {
    expect(
      allowedCommissionStatusActions(
        session(UserRole.representative, 'rep-1'),
        commission('rep-2'),
      ),
      none,
    );
  });

  test('supervisor não altera a própria comissão', () {
    expect(
      allowedCommissionStatusActions(
        session(UserRole.supervisor, 'sup-1'),
        commission('sup-1'),
      ),
      none,
    );
  });

  test('supervisor apenas cancela a comissão de um subordinado', () {
    expect(
      allowedCommissionStatusActions(
        session(UserRole.supervisor, 'sup-1'),
        commission('rep-1'),
      ),
      cancelOnly,
    );
  });

  test('supervisor nega quando o dono não veio no payload', () {
    expect(
      allowedCommissionStatusActions(
        session(UserRole.supervisor, 'sup-1'),
        commission(null),
      ),
      none,
    );
  });

  test('finance e admin pagam e cancelam qualquer comissão', () {
    for (final role in [UserRole.finance, UserRole.admin]) {
      expect(
        allowedCommissionStatusActions(
          session(role, 'backoffice-1'),
          commission('rep-1'),
        ),
        both,
        reason: 'papel $role',
      );
    }
  });

  test('comprador não altera comissão', () {
    expect(
      allowedCommissionStatusActions(
        UserSession(
          userId: const UserId('buyer-1'),
          role: UserRole.buyer,
          companyId: const CompanyId('c1'),
        ),
        commission('rep-1'),
      ),
      none,
    );
  });
}
