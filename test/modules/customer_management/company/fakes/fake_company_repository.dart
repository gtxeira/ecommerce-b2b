import 'package:ecommerce_b2b/modules/customer_management/company/model/authorized_buyer.dart';
import 'package:ecommerce_b2b/modules/customer_management/company/model/company.dart';
import 'package:ecommerce_b2b/modules/customer_management/company/model/customer_credit_account.dart';
import 'package:ecommerce_b2b/modules/customer_management/company/model/repositories/company_repository.dart';
import 'package:ecommerce_b2b/modules/customer_management/company/model/value_objects/cnpj.dart';
import 'package:ecommerce_b2b/modules/customer_management/company/model/value_objects/inscricao_estadual.dart';
import 'package:ecommerce_b2b/modules/shared_kernel/model/address/enums/state.dart';
import 'package:ecommerce_b2b/modules/shared_kernel/model/address/value_objects/address.dart';
import 'package:ecommerce_b2b/modules/shared_kernel/model/common/ids/buyer_id.dart';
import 'package:ecommerce_b2b/modules/shared_kernel/model/common/ids/company_id.dart';
import 'package:ecommerce_b2b/modules/shared_kernel/model/contact/value_objects/email_address.dart';
import 'package:ecommerce_b2b/modules/shared_kernel/model/contact/value_objects/phone_number.dart';
import 'package:ecommerce_b2b/modules/shared_kernel/model/finance/value_objects/money.dart';

class FakeCompanyRepository implements CompanyRepository {
  final List<Company> _companies = [];

  FakeCompanyRepository() {
    _initializeMockData();
  }

  void _initializeMockData() {
    // Empresa 1: Acme Corp
    final company1 = Company(
      id: const CompanyId('c1'),
      legalName: 'Acme Corporation Ltda',
      tradeName: 'Acme Corp',
      cnpj: Cnpj.create('12345678000195').getOrThrow(),
      inscricaoEstadual: InscricaoEstadual.create('123456789').getOrThrow(),
      email: EmailAddress.create('contato@acme.com').getOrThrow(),
      phone: PhoneNumber.create('+5511999999999').getOrThrow(),
      billingAddress: Address.create(
        street: 'Avenida Paulista',
        number: '1000',
        neighborhood: 'Bela Vista',
        city: 'São Paulo',
        state: 'SP',
        zipCode: '01310100',
      ).getOrThrow(),
      shippingAddress: Address.create(
        street: 'Avenida Paulista',
        number: '1000',
        neighborhood: 'Bela Vista',
        city: 'São Paulo',
        state: 'SP',
        zipCode: '01310100',
      ).getOrThrow(),
      state: State.saoPaulo,
      creditLimit: Money.create(100000).getOrThrow(),
      authorizedBuyers: [
        AuthorizedBuyer(
          id: const BuyerId('buyer-1'),
          fullName: 'Carlos Comprador',
          email: EmailAddress.create('carlos@acme.com').getOrThrow(),
          phone: PhoneNumber.create('+5511988888888').getOrThrow(),
          positionTitle: 'Diretor de Compras',
          active: true,
        ),
      ],
      creditAccount: CustomerCreditAccount(
        preApprovedLimit: Money.create(100000).getOrThrow(),
        openBalance: Money.create(15000).getOrThrow(),
        pendingOrdersBalance: Money.create(5000).getOrThrow(),
      ),
    );

    // Empresa 2: Stark Industries
    final company2 = Company(
      id: const CompanyId('c2'),
      legalName: 'Indústrias Stark S.A.',
      tradeName: 'Stark Industries',
      cnpj: Cnpj.create('60746948000112').getOrThrow(),
      inscricaoEstadual: InscricaoEstadual.create('987654321').getOrThrow(),
      email: EmailAddress.create('contact@stark.com').getOrThrow(),
      phone: PhoneNumber.create('+5521999999999').getOrThrow(),
      billingAddress: Address.create(
        street: 'Avenida Atlântica',
        number: '400',
        neighborhood: 'Copacabana',
        city: 'Rio de Janeiro',
        state: 'RJ',
        zipCode: '22010000',
      ).getOrThrow(),
      shippingAddress: Address.create(
        street: 'Avenida Atlântica',
        number: '400',
        neighborhood: 'Copacabana',
        city: 'Rio de Janeiro',
        state: 'RJ',
        zipCode: '22010000',
      ).getOrThrow(),
      state: State.rioDeJaneiro,
      creditLimit: Money.create(500000).getOrThrow(),
      authorizedBuyers: [
        AuthorizedBuyer(
          id: const BuyerId('buyer-2'),
          fullName: 'Pepper Potts',
          email: EmailAddress.create('pepper@stark.com').getOrThrow(),
          phone: PhoneNumber.create('+5521988888888').getOrThrow(),
          positionTitle: 'CEO',
          active: true,
        ),
      ],
      creditAccount: CustomerCreditAccount(
        preApprovedLimit: Money.create(500000).getOrThrow(),
        openBalance: Money.create(0).getOrThrow(),
        pendingOrdersBalance: Money.create(45000).getOrThrow(),
      ),
    );

    _companies.add(company1);
    _companies.add(company2);
  }

  @override
  Future<void> save(Company company) async {
    final index = _companies.indexWhere((c) => c.id == company.id);
    if (index != -1) {
      _companies[index] = company;
    } else {
      _companies.add(company);
    }
  }

  @override
  Future<Company?> findById(CompanyId id) async {
    try {
      return _companies.firstWhere((c) => c.id == id);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<List<Company>> findAll() async {
    return List.from(_companies);
  }

  @override
  Future<List<Company>> findByRepresentativeId(
    String representativeId, {
    bool teamScope = false,
  }) async {
    if (teamScope || representativeId == 'rep-456') {
      return List.from(_companies);
    }
    return [];
  }

  @override
  Future<AuthorizedBuyer> addAuthorizedBuyer({
    required CompanyId companyId,
    required String fullName,
    required String email,
    required String phone,
    required String positionTitle,
    required String password,
  }) async {
    return AuthorizedBuyer(
      id: BuyerId('buyer-${DateTime.now().microsecondsSinceEpoch}'),
      fullName: fullName,
      email: EmailAddress.create(email).getOrThrow(),
      phone: PhoneNumber.create(phone).getOrThrow(),
      positionTitle: positionTitle,
      active: true,
    );
  }
}
