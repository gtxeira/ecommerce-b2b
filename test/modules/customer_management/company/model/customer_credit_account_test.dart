import 'package:ecommerce_b2b/modules/customer_management/company/model/customer_credit_account.dart';
import 'package:ecommerce_b2b/modules/shared_kernel/model/finance/value_objects/money.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('CustomerCreditAccount', () {
    // availableLimit deve calcular corretamente com base nas informações da conta.
    test('availableLimit should calculate correctly', () {
      final account = CustomerCreditAccount(
        preApprovedLimit: Money.create(5000).getOrThrow(),
        openBalance: Money.create(1000).getOrThrow(),
        pendingOrdersBalance: Money.create(500).getOrThrow(),
      );

      expect(account.availableLimit.amount, 3500);
    });

    // availableLimit deve retornar zero se a dívida exceder o limite.
    test('availableLimit should return zero if debt exceeds limit', () {
      final account = CustomerCreditAccount(
        preApprovedLimit: Money.create(1000).getOrThrow(),
        openBalance: Money.create(1200).getOrThrow(),
        pendingOrdersBalance: Money.create(300).getOrThrow(),
      );

      expect(account.availableLimit.amount, 0);
    });
  });
}
