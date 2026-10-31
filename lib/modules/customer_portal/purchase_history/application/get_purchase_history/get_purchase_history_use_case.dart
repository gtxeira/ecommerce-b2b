import 'package:ecommerce_b2b/app/core/network/api_exception.dart';
import 'package:ecommerce_b2b/modules/identity_access/model/user_session.dart';
import 'package:ecommerce_b2b/modules/order_flow/sales_order/model/repositories/sales_order_repository.dart';
import 'package:ecommerce_b2b/modules/order_flow/sales_order/model/sales_order.dart';
import 'package:ecommerce_b2b/app/core/errors/app_error.dart';
import 'package:ecommerce_b2b/modules/shared_kernel/model/common/ids/company_id.dart';
import 'package:ecommerce_b2b/app/core/result/result.dart';

/// Histórico de compras (RF18). A autorização é da API; aqui só traduzimos o erro.
class GetPurchaseHistoryUseCase {
  final SalesOrderRepository _orderRepository;

  GetPurchaseHistoryUseCase(this._orderRepository);

  Future<Result<List<SalesOrder>, AppError>> execute(
    CompanyId companyId,
    UserSession currentSession,
  ) async {
    try {
      return Success(await _orderRepository.findByCompanyId(companyId));
    } on ApiException catch (error) {
      return Failure(error.toAppError());
    } catch (error) {
      return Failure(AppError(AppErrorCodes.networkError, error.toString()));
    }
  }
}
