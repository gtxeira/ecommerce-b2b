import 'package:ecommerce_b2b/modules/identity_access/domain/user_session.dart';
import 'package:ecommerce_b2b/modules/order_flow/quote/domain/quote.dart';
import 'package:ecommerce_b2b/modules/order_flow/quote/domain/repositories/quote_repository.dart';
import 'package:ecommerce_b2b/modules/order_flow/quote/presentation/cubit/quote_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class QuoteCubit extends Cubit<QuoteState> {
  final QuoteRepository _quoteRepository;

  QuoteCubit(this._quoteRepository) : super(QuoteInitial());

  Future<void> loadQuotes(UserSession session) async {
    emit(QuoteLoading());
    try {
      final quotes = await _quoteRepository.findByRepresentativeId(
        session.userId.value,
      );
      emit(QuoteLoaded(quotes));
    } catch (e) {
      emit(QuoteError(e.toString()));
    }
  }

  Future<void> saveQuote(Quote quote, UserSession session) async {
    try {
      await _quoteRepository.save(quote);
      await loadQuotes(session);
    } catch (e) {
      emit(QuoteError(e.toString()));
      rethrow;
    }
  }
}
