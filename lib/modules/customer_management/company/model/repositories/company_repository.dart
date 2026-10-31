import 'package:ecommerce_b2b/modules/customer_management/company/model/authorized_buyer.dart';
import 'package:ecommerce_b2b/modules/customer_management/company/model/company.dart';
import 'package:ecommerce_b2b/modules/shared_kernel/model/common/ids/company_id.dart';

abstract class CompanyRepository {
  /// Cadastra uma nova empresa (POST /api/companies).
  Future<void> save(Company company);

  Future<Company?> findById(CompanyId id);
  Future<List<Company>> findAll();
  Future<List<Company>> findByRepresentativeId(String representativeId);

  /// Adiciona um comprador autorizado à empresa (POST /api/companies/{id}/buyers)
  /// e devolve a representação criada pela API.
  Future<AuthorizedBuyer> addAuthorizedBuyer({
    required CompanyId companyId,
    required String fullName,
    required String email,
    required String phone,
    required String positionTitle,
  });
}
