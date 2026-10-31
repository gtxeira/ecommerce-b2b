import 'package:ecommerce_b2b/app/core/network/api_client.dart';
import 'package:ecommerce_b2b/app/core/network/json_read.dart';
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

class ApiCompanyRepository implements CompanyRepository {
  final ApiClient _api;

  ApiCompanyRepository(this._api);

  @override
  Future<List<Company>> findAll() async {
    final data = await _api.get('/api/companies');
    return _mapList(data);
  }

  @override
  Future<List<Company>> findByRepresentativeId(String representativeId) async {
    final data = await _api.get(
      '/api/companies',
      query: {'representativeId': representativeId},
    );
    return _mapList(data);
  }

  @override
  Future<Company?> findById(CompanyId id) async {
    final all = await findAll();
    for (final company in all) {
      if (company.id == id) return company;
    }
    return null;
  }

  @override
  Future<void> save(Company company) async {
    await _api.post('/api/companies', data: _toJson(company));
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
    final data = await _api.post(
      '/api/companies/${companyId.value}/buyers',
      data: {
        'fullName': fullName,
        'email': email,
        'phone': phone,
        'positionTitle': positionTitle,
        'password': password,
      },
    );
    if (data is! Map) {
      throw StateError('Resposta inesperada ao adicionar comprador.');
    }
    return _buyerFromJson(Map<String, dynamic>.from(data));
  }

  List<Company> _mapList(dynamic data) {
    if (data is! List) return const [];
    return data
        .whereType<Map>()
        .map((item) => _fromJson(Map<String, dynamic>.from(item)))
        .toList();
  }

  Map<String, dynamic> _toJson(Company company) {
    final billing = company.billingAddress;
    final shipping = company.shippingAddress;

    return {
      'legalName': company.legalName,
      'tradeName': company.tradeName,
      'cnpj': company.cnpj.value,
      'inscricaoEstadual': company.inscricaoEstadual.value,
      'email': company.email.value,
      'phone': company.phone.value,
      'billingStreet': billing.street.value,
      'billingNumber': billing.number.value,
      'billingComplement': billing.complement?.value,
      'billingNeighborhood': billing.neighborhood.value,
      'billingCity': billing.city.value,
      'billingState': billing.state.code,
      'billingZipCode': billing.zipCode.value,
      'shippingStreet': shipping.street.value,
      'shippingNumber': shipping.number.value,
      'shippingComplement': shipping.complement?.value,
      'shippingNeighborhood': shipping.neighborhood.value,
      'shippingCity': shipping.city.value,
      'shippingState': shipping.state.code,
      'shippingZipCode': shipping.zipCode.value,
      'creditLimit': company.creditLimit.amount,
    };
  }

  Company _fromJson(Map<String, dynamic> json) {
    final creditLimit = Money.create(
      readDouble(json, 'creditLimit'),
    ).getOrThrow();
    final openBalance = Money.create(
      readDouble(json, 'openBalance'),
    ).getOrThrow();
    final pendingBalance = Money.create(
      readDouble(json, 'pendingOrdersBalance'),
    ).getOrThrow();

    final state = State.fromApiName(readString(json, 'state')).getOrThrow();
    final representativeId = readNullableString(json, 'representativeId');

    return Company(
      id: CompanyId(readString(json, 'id')),
      legalName: readString(json, 'legalName'),
      tradeName: readString(json, 'tradeName'),
      cnpj: Cnpj.create(readString(json, 'cnpj')).getOrThrow(),
      inscricaoEstadual: InscricaoEstadual.create(
        readString(json, 'inscricaoEstadual'),
      ).getOrThrow(),
      email: EmailAddress.create(readString(json, 'email')).getOrThrow(),
      phone: PhoneNumber.create(readString(json, 'phone')).getOrThrow(),
      billingAddress: _addressFromJson(readMap(json, 'billingAddress')),
      shippingAddress: _addressFromJson(readMap(json, 'shippingAddress')),
      state: state,
      creditLimit: creditLimit,
      authorizedBuyers: readMapList(
        json,
        'authorizedBuyers',
      ).map(_buyerFromJson).toList(),
      creditAccount: CustomerCreditAccount(
        preApprovedLimit: creditLimit,
        openBalance: openBalance,
        pendingOrdersBalance: pendingBalance,
      ),
      representativeId: representativeId,
    );
  }

  Address _addressFromJson(Map<String, dynamic> json) => Address.create(
    street: readString(json, 'street'),
    number: readString(json, 'number'),
    complement: readNullableString(json, 'complement'),
    neighborhood: readString(json, 'neighborhood'),
    city: readString(json, 'city'),
    state: State.fromApiName(readString(json, 'state')).getOrThrow().code,
    zipCode: readString(json, 'zipCode'),
  ).getOrThrow();

  AuthorizedBuyer _buyerFromJson(Map<String, dynamic> json) {
    final phone = readNullableString(json, 'phone');
    return AuthorizedBuyer(
      id: BuyerId(readString(json, 'id')),
      fullName: readString(json, 'fullName'),
      email: EmailAddress.create(readString(json, 'email')).getOrThrow(),
      phone: phone == null || phone.isEmpty
          ? null
          : PhoneNumber.create(phone).getOrThrow(),
      positionTitle: readString(json, 'positionTitle'),
      active: readBool(json, 'active', true),
    );
  }
}
