import 'package:ecommerce_b2b/modules/identity_access/model/enums/user_role.dart';
import 'package:ecommerce_b2b/modules/identity_access/model/user_session.dart';
import 'package:ecommerce_b2b/modules/shared_kernel/model/common/ids/company_id.dart';
import 'package:ecommerce_b2b/modules/shared_kernel/model/common/ids/user_id.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('UserSession', () {
    // Deve criar uma sessão válida para um comprador com companyId
    test('should create a valid session for buyer with companyId', () {
      final session = UserSession(
        userId: const UserId('user-1'),
        role: UserRole.buyer,
        companyId: const CompanyId('company-1'),
      );

      expect(session.isBuyer, isTrue);
      expect(session.companyId, const CompanyId('company-1'));
    });

    // Deve lançar erro ao criar sessão de comprador sem o companyId
    test(
      'should throw error when creating buyer session without companyId',
      () {
        expect(
          () =>
              UserSession(userId: const UserId('user-1'), role: UserRole.buyer),
          throwsArgumentError,
        );
      },
    );

    // Deve criar uma sessão válida para o representante sem o ID da empresa
    test(
      'should create valid session for representative without companyId',
      () {
        final session = UserSession(
          userId: const UserId('user-1'),
          role: UserRole.representative,
        );

        expect(session.isRepresentative, isTrue);
        expect(session.companyId, isNull);
      },
    );
  });
}
