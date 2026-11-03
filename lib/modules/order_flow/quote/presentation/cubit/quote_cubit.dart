import 'package:ecommerce_b2b/app/core/events/order_events.dart';
import 'package:ecommerce_b2b/modules/identity_access/model/user_session.dart';
import 'package:ecommerce_b2b/modules/order_flow/quote/model/quote.dart';
import 'package:ecommerce_b2b/modules/order_flow/quote/model/repositories/quote_repository.dart';
import 'package:ecommerce_b2b/modules/order_flow/quote/presentation/cubit/quote_state.dart';
import 'package:ecommerce_b2b/modules/order_flow/sales_order/model/sales_order.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class QuoteCubit extends Cubit<QuoteState> {
  final QuoteRepository _quoteRepository;
  final OrderEvents _orderEvents;

  QuoteCubit(this._quoteRepository, this._orderEvents) : super(QuoteInitial());

  Future<void> loadQuotes(UserSession session) async {
    emit(QuoteLoading());
    try {
      // O Admin não é representante: filtrar pelo próprio id devolveria lista vazia.
      // GET /api/quotes sem filtro devolve todos, que é o que o Admin precisa ver.
      // O comprador vê os orçamentos da própria empresa (a API restringe esse filtro).
      final quotes = session.isAdmin
          ? await _quoteRepository.getAll()
          : session.isBuyer
          ? await _quoteRepository.findByCompanyId(session.companyId!.value)
          : await _quoteRepository.findByRepresentativeId(session.userId.value);
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

  Future<SalesOrder> convertQuote(Quote quote, UserSession session) async {
    try {
      final order = await _quoteRepository.convert(
        quote.id,
        companyId: quote.companyId,
      );
      // O pedido em aberto mudou: o badge da navegação precisa reler a fonte, mesmo que a
      // releitura da lista de orçamentos falhe em seguida.
      _orderEvents.notifyChanged();
      await loadQuotes(session);
      return order;
    } catch (e) {
      emit(QuoteError(e.toString()));
      rethrow;
    }
  }
}
