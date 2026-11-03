import 'package:ecommerce_b2b/modules/order_flow/quote/presentation/cubit/buyer_quote_cart_state.dart';
import 'package:ecommerce_b2b/modules/shared_kernel/model/common/ids/product_id.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Carrinho de orçamento do comprador, com escopo da visita ao catálogo.
///
/// A soma de quantidades de um mesmo produto/variante e a repreciação ficam na
/// tela, que conhece o `PricingRepository`; aqui só mora a lista e as operações
/// de escrita.
class BuyerQuoteCartCubit extends Cubit<BuyerQuoteCartState> {
  BuyerQuoteCartCubit() : super(const BuyerQuoteCartState());

  void addOrReplace(BuyerQuoteCartItem item) {
    final items = [...state.items];
    final index = items.indexWhere((i) => i.lineKey == item.lineKey);
    if (index >= 0) {
      items[index] = item;
    } else {
      items.add(item);
    }
    emit(BuyerQuoteCartState(items: List.unmodifiable(items)));
  }

  void remove(ProductId productId, {String? variantId}) {
    emit(
      BuyerQuoteCartState(
        items: List.unmodifiable(
          state.items.where(
            (item) =>
                !(item.productId == productId && item.variantId == variantId),
          ),
        ),
      ),
    );
  }

  void clear() => emit(const BuyerQuoteCartState());
}
