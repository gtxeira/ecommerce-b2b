// ignore_for_file: prefer_initializing_formals
import 'package:ecommerce_b2b/modules/customer_management/company/domain/value_objects/cnpj.dart';
import 'package:ecommerce_b2b/modules/customer_management/company/domain/value_objects/inscricao_estadual.dart';
import 'package:ecommerce_b2b/modules/shared_kernel/base/base_entity.dart';
import 'package:ecommerce_b2b/modules/shared_kernel/domain/address/enums/state.dart';
import 'package:ecommerce_b2b/modules/shared_kernel/domain/common/ids/company_id.dart';
import 'package:ecommerce_b2b/modules/shared_kernel/domain/address/value_objects/address.dart';
import 'package:ecommerce_b2b/modules/shared_kernel/domain/contact/value_objects/email_address.dart';
import 'package:ecommerce_b2b/modules/shared_kernel/domain/finance/value_objects/money.dart';
import 'package:ecommerce_b2b/modules/shared_kernel/domain/contact/value_objects/phone_number.dart';
import 'package:ecommerce_b2b/modules/customer_management/company/domain/authorized_buyer.dart';
import 'package:ecommerce_b2b/modules/customer_management/company/domain/customer_credit_account.dart';

/// Raiz do Agregado que representa uma Empresa (Cliente B2B).
class Company extends Entity<CompanyId> {
  /// Razão Social.
  final String legalName;
  /// Nome Fantasia.
  final String tradeName;
  /// CNPJ da empresa.
  final Cnpj cnpj;
  /// Inscrição Estadual.
  final InscricaoEstadual inscricaoEstadual;
  /// E-mail principal de contato.
  final EmailAddress email;
  /// Telefone principal de contato.
  final PhoneNumber phone;
  /// Endereço de faturamento.
  final Address billingAddress;
  /// Endereço de entrega.
  final Address shippingAddress;
  /// Código do Estado (UF).
  final State state;
  /// Limite de crédito total concedido.
  final Money creditLimit;
  /// ID do representante comercial responsável (opcional).
  final String? representativeId;
  
  final List<AuthorizedBuyer> _authorizedBuyers;
  CustomerCreditAccount _creditAccount;

  /// Construtor da Empresa.
  Company({
    required CompanyId id,
    required this.legalName,
    required this.tradeName,
    required this.cnpj,
    required this.inscricaoEstadual,
    required this.email,
    required this.phone,
    required this.billingAddress,
    required this.shippingAddress,
    required this.state,
    required this.creditLimit,
    required List<AuthorizedBuyer> authorizedBuyers,
    required CustomerCreditAccount creditAccount,
    this.representativeId,
  }) : _authorizedBuyers = authorizedBuyers,
       _creditAccount = creditAccount,
       super(id);

  /// Lista de compradores autorizados para esta empresa.
  List<AuthorizedBuyer> get authorizedBuyers => List.unmodifiable(_authorizedBuyers);
  
  /// Conta de crédito associada à empresa.
  CustomerCreditAccount get creditAccount => _creditAccount;

  /// Atualiza os dados da conta de crédito.
  void updateCreditAccount(CustomerCreditAccount newAccount) {
    _creditAccount = newAccount;
  }

  /// Adiciona um novo comprador autorizado.
  void addAuthorizedBuyer(AuthorizedBuyer buyer) {
    _authorizedBuyers.add(buyer);
  }

  /// Remove um comprador autorizado pelo seu ID.
  void removeAuthorizedBuyer(AuthorizedBuyer buyer) {
    _authorizedBuyers.removeWhere((b) => b.id == buyer.id);
  }
}
