import 'package:ecommerce_b2b/app/core/network/api_exception.dart';
import 'package:ecommerce_b2b/modules/identity_access/domain/user_session.dart';
import 'package:ecommerce_b2b/modules/order_flow/quote/domain/quote.dart';
import 'package:ecommerce_b2b/modules/order_flow/quote/domain/repositories/quote_repository.dart';
import 'package:ecommerce_b2b/modules/shared_kernel/domain/auth/errors/auth_errors.dart';
import 'package:ecommerce_b2b/modules/shared_kernel/domain/common/ids/representative_id.dart';
import 'package:ecommerce_b2b/modules/shared_kernel/functional/result.dart';

/// Orçamentos recentes do representante. A API valida a hierarquia.
class GetRecentQuotesUseCase {
  final QuoteRepository _quoteRepository;

  GetRecentQuotesUseCase(this._quoteRepository);

  Future<Result<List<Quote>, AuthError>> execute(
    RepresentativeId targetRepId,
    UserSession currentSession,
  ) async {
    try {
      return Success(
        await _quoteRepository.findByRepresentativeId(targetRepId.value),
      );
    } on ApiException catch (error) {
      return Failure(UnauthorizedError(error.message));
    } catch (error) {
      return Failure(UnauthorizedError(error.toString()));
    }
  }
}
