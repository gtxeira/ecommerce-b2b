import 'package:ecommerce_b2b/app/core/network/api_exception.dart';
import 'package:ecommerce_b2b/modules/identity_access/domain/user_session.dart';
import 'package:ecommerce_b2b/modules/order_flow/sales_order/domain/repositories/sales_order_repository.dart';
import 'package:ecommerce_b2b/modules/order_flow/sales_order/domain/sales_order.dart';
import 'package:ecommerce_b2b/modules/shared_kernel/domain/auth/errors/auth_errors.dart';
import 'package:ecommerce_b2b/modules/shared_kernel/domain/common/ids/company_id.dart';
import 'package:ecommerce_b2b/modules/shared_kernel/functional/result.dart';

/// Histórico de compras (RF18). A autorização é da API; aqui só traduzimos o erro.
class GetPurchaseHistoryUseCase {
  final SalesOrderRepository _orderRepository;

  GetPurchaseHistoryUseCase(this._orderRepository);

  Future<Result<List<SalesOrder>, AuthError>> execute(
    CompanyId companyId,
    UserSession currentSession,
  ) async {
    try {
      return Success(await _orderRepository.findByCompanyId(companyId));
    } on ApiException catch (error) {
      return Failure(UnauthorizedError(error.message));
    } catch (error) {
      return Failure(UnauthorizedError(error.toString()));
    }
  }
}
