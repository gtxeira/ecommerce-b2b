import 'package:ecommerce_b2b/modules/catalog/price_table/model/pricing_preview.dart';
import 'package:ecommerce_b2b/modules/order_flow/quote/presentation/cubit/buyer_quote_cart_cubit.dart';
import 'package:ecommerce_b2b/modules/order_flow/quote/presentation/cubit/buyer_quote_cart_state.dart';
import 'package:ecommerce_b2b/modules/shared_kernel/model/common/ids/product_id.dart';
import 'package:ecommerce_b2b/modules/shared_kernel/model/finance/value_objects/money.dart';
import 'package:flutter_test/flutter_test.dart';

PricingPreview _preview(
  String productId, {
  int quantity = 1,
  String? variantId,
}) => PricingPreview(
  productId: productId,
  variantId: variantId,
  quantity: quantity,
  unitPrice: Money.create(10).getOrThrow(),
  referenceUnitPrice: Money.create(12).getOrThrow(),
  subtotal: Money.create(10.0 * quantity).getOrThrow(),
);

BuyerQuoteCartItem _item(
  String productId, {
  int quantity = 1,
  String? priceTableId = 'pt-1',
  String? variantId,
  String? variantSku,
  String? variantLabel,
}) => BuyerQuoteCartItem(
  productId: ProductId(productId),
  variantId: variantId,
  productName: 'Produto $productId',
  variantSku: variantSku,
  variantLabel: variantLabel,
  quantity: quantity,
  priceTableId: priceTableId,
  preview: _preview(productId, quantity: quantity, variantId: variantId),
);

void main() {
  late BuyerQuoteCartCubit cubit;

  setUp(() => cubit = BuyerQuoteCartCubit());
  tearDown(() => cubit.close());

  test('começa vazio', () {
    expect(cubit.state.isEmpty, isTrue);
    expect(cubit.state.itemCount, 0);
    expect(cubit.state.total.amount, 0);
  });

  test('acumula itens, unidades e total', () {
    cubit.addOrReplace(_item('p1', quantity: 2));
    cubit.addOrReplace(_item('p2', quantity: 3));

    expect(cubit.state.items, hasLength(2));
    expect(cubit.state.itemCount, 5);
    expect(cubit.state.total.amount, 50);
  });

  test('mesmo produto é substituído, não duplicado', () {
    cubit.addOrReplace(_item('p1', quantity: 2));
    cubit.addOrReplace(_item('p1', quantity: 5));

    final item = cubit.state.items.single;
    expect(item.quantity, 5);
    expect(cubit.state.itemCount, 5);
    expect(cubit.state.total.amount, 50);
  });

  test('variações diferentes do mesmo produto são linhas separadas', () {
    cubit.addOrReplace(
      _item('p1', quantity: 2, variantId: 'v1', variantLabel: 'Preto'),
    );
    cubit.addOrReplace(
      _item('p1', quantity: 3, variantId: 'v2', variantLabel: 'Prata'),
    );

    expect(cubit.state.items, hasLength(2));
    expect(cubit.state.itemCount, 5);

    // A mesma combinação produto+variação continua sendo substituída.
    cubit.addOrReplace(
      _item('p1', quantity: 4, variantId: 'v1', variantLabel: 'Preto'),
    );
    expect(cubit.state.items, hasLength(2));
    expect(cubit.state.items.first.quantity, 4);
  });

  test('remove um produto pelo id', () {
    cubit.addOrReplace(_item('p1'));
    cubit.addOrReplace(_item('p2'));

    cubit.remove(const ProductId('p1'));

    expect(cubit.state.items.single.productId.value, 'p2');
  });

  test('remove apenas a variação informada', () {
    cubit.addOrReplace(_item('p1', variantId: 'v1'));
    cubit.addOrReplace(_item('p1', variantId: 'v2'));

    cubit.remove(const ProductId('p1'), variantId: 'v1');

    expect(cubit.state.items.single.variantId, 'v2');
  });

  test('clear zera o carrinho', () {
    cubit.addOrReplace(_item('p1'));

    cubit.clear();

    expect(cubit.state.isEmpty, isTrue);
  });

  test('toQuoteItem preserva quantidade, tabela e preço do preview', () {
    final quoteItem = _item(
      'p1',
      quantity: 4,
      priceTableId: 'pt-9',
    ).toQuoteItem();

    expect(quoteItem.productId.value, 'p1');
    expect(quoteItem.quantity.value, 4);
    expect(quoteItem.priceTableId, 'pt-9');
    expect(quoteItem.unitPrice.amount, 10);
  });

  test('toQuoteItem preserva a variação e aceita tabela ausente', () {
    final quoteItem = _item(
      'p1',
      priceTableId: null,
      variantId: 'v2',
      variantSku: 'SKU-2',
      variantLabel: 'Prata',
    ).toQuoteItem();

    expect(quoteItem.variantId, 'v2');
    expect(quoteItem.variantSku, 'SKU-2');
    expect(quoteItem.variantLabel, 'Prata');
    expect(quoteItem.priceTableId, isNull);
  });
}
