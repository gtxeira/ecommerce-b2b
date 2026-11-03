import 'package:ecommerce_b2b/app/core/network/api_exception.dart';
import 'package:ecommerce_b2b/modules/identity_access/model/user_session.dart';
import 'package:ecommerce_b2b/modules/order_flow/quote/model/quote.dart';
import 'package:ecommerce_b2b/modules/order_flow/quote/model/repositories/quote_repository.dart';
import 'package:ecommerce_b2b/app/core/errors/app_error.dart';
import 'package:ecommerce_b2b/modules/shared_kernel/model/common/ids/representative_id.dart';
import 'package:ecommerce_b2b/app/core/result/result.dart';

/// Orçamentos recentes do representante. A API valida a hierarquia.
class GetRecentQuotesUseCase {
  final QuoteRepository _quoteRepository;

  GetRecentQuotesUseCase(this._quoteRepository);

  Future<Result<List<Quote>, AppError>> execute(
    RepresentativeId targetRepId,
    UserSession currentSession, {
    bool teamScope = false,
  }) async {
    try {
      // A API já devolve ordenado por `createdAt`; ordenar aqui também mantém o
      // painel estável se o payload vier sem data ou com ordem diferente.
      final quotes = await _quoteRepository.findByRepresentativeId(
        targetRepId.value,
        teamScope: teamScope,
      );
      quotes.sort((a, b) {
        final aDate = a.createdAt;
        final bDate = b.createdAt;
        if (aDate == null && bDate == null) return 0;
        if (aDate == null) return 1;
        if (bDate == null) return -1;
        return bDate.compareTo(aDate);
      });
      return Success(quotes);
    } on ApiException catch (error) {
      return Failure(error.toAppError());
    } catch (error) {
      return Failure(AppError(AppErrorCodes.networkError, error.toString()));
    }
  }
}
