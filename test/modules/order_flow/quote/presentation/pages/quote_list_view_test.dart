import 'package:ecommerce_b2b/modules/catalog/price_table/model/pricing_explanation.dart';
import 'package:ecommerce_b2b/modules/order_flow/quote/model/enums/quote_status.dart';
import 'package:ecommerce_b2b/modules/order_flow/quote/model/quote.dart';
import 'package:ecommerce_b2b/modules/order_flow/quote/model/quote_item.dart';
import 'package:ecommerce_b2b/modules/order_flow/quote/presentation/pages/quote_list_view.dart';
import 'package:ecommerce_b2b/modules/shared_kernel/model/common/ids/quote_id.dart';
import 'package:ecommerce_b2b/modules/shared_kernel/model/common/ids/product_id.dart';
import 'package:ecommerce_b2b/modules/shared_kernel/model/finance/value_objects/money.dart';
import 'package:ecommerce_b2b/modules/shared_kernel/model/finance/value_objects/quantity.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final pricing = PricingExplanation.fromJson({
    'referenceUnitPrice': 5500.0,
    'discountPerUnit': 500.0,
    'discountTotal': 5000.0,
    'discountPercentage': 9.09,
    'priceTableId': 'pt-1',
    'priceTableName': 'Tabela Atacado SP',
    'scopeType': 'Regional',
    'minQuantity': 10,
    'maxQuantity': 999,
    'state': 'SaoPaulo',
  });

  test('quoteSavings soma o desconto congelado dos itens', () {
    final quote = Quote(
      id: const QuoteId('quote-003'),
      status: QuoteStatus.sent,
      items: [
        QuoteItem(
          productId: const ProductId('p1'),
          quantity: Quantity.create(10).getOrThrow(),
          unitPrice: Money.create(5000).getOrThrow(),
          pricing: pricing,
        ),
      ],
    );

    expect(quoteSavings(quote)!.amount, 5000);
  });

  test('quoteSavings é nulo quando nenhum item tem desconto', () {
    final quote = Quote(
      id: const QuoteId('quote-004'),
      status: QuoteStatus.sent,
      items: [
        QuoteItem(
          productId: const ProductId('p2'),
          quantity: Quantity.create(2).getOrThrow(),
          unitPrice: Money.create(2800).getOrThrow(),
        ),
      ],
    );

    expect(quoteSavings(quote), isNull);
  });
}
