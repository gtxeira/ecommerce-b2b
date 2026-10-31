import 'package:ecommerce_b2b/modules/customer_portal/return_request/model/return_request.dart';
import 'package:ecommerce_b2b/modules/shared_kernel/model/common/ids/company_id.dart';
import 'package:ecommerce_b2b/modules/shared_kernel/model/common/ids/rma_id.dart';

abstract class ReturnRequestRepository {
  Future<void> save(ReturnRequest request);
  Future<ReturnRequest?> getById(RmaId id);
  Future<List<ReturnRequest>> getAll();

  /// Lista as RMAs da empresa (GET /api/me/return-requests?companyId=...).
  Future<List<ReturnRequest>> findByCompanyId(CompanyId companyId);
}
