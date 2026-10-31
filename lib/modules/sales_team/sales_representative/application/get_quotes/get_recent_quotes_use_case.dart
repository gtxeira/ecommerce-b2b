import 'package:ecommerce_b2b/app/core/network/api_exception.dart';
import 'package:ecommerce_b2b/modules/identity_access/domain/user_session.dart';
import 'package:ecommerce_b2b/modules/order_flow/quote/domain/quote.dart';
import 'package:ecommerce_b2b/modules/order_flow/quote/domain/repositories/quote_repository.dart';
import 'package:ecommerce_b2b/app/core/errors/app_error.dart';
import 'package:ecommerce_b2b/modules/shared_kernel/domain/common/ids/representative_id.dart';
import 'package:ecommerce_b2b/app/core/result/result.dart';

/// Orçamentos recentes do representante. A API valida a hierarquia.
class GetRecentQuotesUseCase {
  final QuoteRepository _quoteRepository;

  GetRecentQuotesUseCase(this._quoteRepository);

  Future<Result<List<Quote>, AppError>> execute(
    RepresentativeId targetRepId,
    UserSession currentSession,
  ) async {
    try {
      return Success(
        await _quoteRepository.findByRepresentativeId(targetRepId.value),
      );
    } on ApiException catch (error) {
      return Failure(error.toAppError());
    } catch (error) {
      return Failure(AppError(AppErrorCodes.networkError, error.toString()));
    }
  }
}
