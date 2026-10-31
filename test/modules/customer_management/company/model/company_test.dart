import 'package:ecommerce_b2b/modules/customer_management/company/model/authorized_buyer.dart';
import 'package:ecommerce_b2b/modules/customer_management/company/model/company.dart';
import 'package:ecommerce_b2b/modules/customer_management/company/model/customer_credit_account.dart';
import 'package:ecommerce_b2b/modules/customer_management/company/model/value_objects/cnpj.dart';
import 'package:ecommerce_b2b/modules/customer_management/company/model/value_objects/inscricao_estadual.dart';
import 'package:ecommerce_b2b/modules/shared_kernel/model/address/enums/state.dart';
import 'package:ecommerce_b2b/modules/shared_kernel/model/address/value_objects/address.dart';
import 'package:ecommerce_b2b/modules/shared_kernel/model/common/ids/buyer_id.dart';
import 'package:ecommerce_b2b/modules/shared_kernel/model/common/ids/company_id.dart';
import 'package:ecommerce_b2b/modules/shared_kernel/model/contact/value_objects/email_address.dart';
import 'package:ecommerce_b2b/modules/shared_kernel/model/contact/value_objects/phone_number.dart';
import 'package:ecommerce_b2b/modules/shared_kernel/model/finance/value_objects/money.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Company', () {
    late Company company;
    final companyId = const CompanyId('c1');

    setUp(() {
      company = Company(
        id: companyId,
        legalName: 'Legal Name',
        tradeName: 'Trade Name',
        cnpj: Cnpj.create('12345678000195').getOrThrow(),
        inscricaoEstadual: InscricaoEstadual.create('123456789').getOrThrow(),
        email: EmailAddress.create('test@test.com').getOrThrow(),
        phone: PhoneNumber.create('11999999999').getOrThrow(),
        billingAddress: Address.create(street: 'Rua A', number: '1', neighborhood: 'B', city: 'C', state: 'SP', zipCode: '01000000').getOrThrow(),
        shippingAddress: Address.create(street: 'Rua A', number: '1', neighborhood: 'B', city: 'C', state: 'SP', zipCode: '01000000').getOrThrow(),
        state: State.saoPaulo,
        creditLimit: Money.create(5000).getOrThrow(),
        authorizedBuyers: [],
        creditAccount: CustomerCreditAccount(
          preApprovedLimit: Money.create(5000).getOrThrow(),
          openBalance: Money.create(0).getOrThrow(),
          pendingOrdersBalance: Money.create(0).getOrThrow(),
        ),
      );
    });

    // Deve adicionar e remover compradores autorizados corretamente.
    test('should add and remove authorized buyer', () {
      final buyer = AuthorizedBuyer(
        id: const BuyerId('b1'),
        fullName: 'John Doe',
        email: EmailAddress.create('john@doe.com').getOrThrow(),
        phone: PhoneNumber.create('11888888888').getOrThrow(),
        positionTitle: 'Buyer',
        active: true,
      );

      company.addAuthorizedBuyer(buyer);
      expect(company.authorizedBuyers.length, 1);

      company.removeAuthorizedBuyer(buyer);
      expect(company.authorizedBuyers.length, 0);
    });

    // Deve atualizar a conta de crédito corretamente.
    test('should update credit account', () {
      final newAccount = CustomerCreditAccount(
        preApprovedLimit: Money.create(10000).getOrThrow(),
        openBalance: Money.create(1000).getOrThrow(),
        pendingOrdersBalance: Money.create(500).getOrThrow(),
      );

      company.updateCreditAccount(newAccount);
      expect(company.creditAccount, newAccount);
    });
  });
}
