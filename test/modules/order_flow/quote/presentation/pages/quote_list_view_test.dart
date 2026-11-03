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

Quote _quote({
  required String id,
  String? representativeId,
  String? representativeName,
  String? companyId,
  String? companyName,
  String? companyLegalName,
}) => Quote(
  id: QuoteId(id),
  representativeId: representativeId,
  representativeName: representativeName,
  companyId: companyId,
  companyName: companyName,
  companyLegalName: companyLegalName,
  status: QuoteStatus.sent,
);

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

  group('filterQuotes', () {
    final quotes = [
      _quote(id: 'q1', representativeId: 'rep-1', companyId: 'c1'),
      _quote(id: 'q2', representativeId: 'rep-1', companyId: 'c2'),
      _quote(id: 'q3', representativeId: 'rep-2', companyId: 'c2'),
    ];

    test('sem filtro devolve tudo', () {
      expect(filterQuotes(quotes), hasLength(3));
    });

    test('filtra por representante', () {
      final result = filterQuotes(quotes, representativeId: 'rep-1');

      expect(result.map((quote) => quote.id.value), ['q1', 'q2']);
    });

    test('filtra por empresa', () {
      final result = filterQuotes(quotes, companyId: 'c2');

      expect(result.map((quote) => quote.id.value), ['q2', 'q3']);
    });

    test('combina representante e empresa', () {
      final result = filterQuotes(
        quotes,
        representativeId: 'rep-1',
        companyId: 'c2',
      );

      expect(result.map((quote) => quote.id.value), ['q2']);
    });
  });

  group('quoteFilterOptions', () {
    test('lista representantes e empresas distintos, ordenados pelo nome', () {
      final options = quoteFilterOptions([
        _quote(
          id: 'q1',
          representativeId: 'rep-2',
          representativeName: 'Zé',
          companyId: 'c1',
          companyName: 'Beta',
        ),
        _quote(
          id: 'q2',
          representativeId: 'rep-1',
          representativeName: 'Ana',
          companyId: 'c2',
          companyLegalName: 'Alfa Ltda',
        ),
        _quote(
          id: 'q3',
          representativeId: 'rep-1',
          representativeName: 'Ana',
          companyId: 'c1',
          companyName: 'Beta',
        ),
      ]);

      expect(options.representatives.map((option) => option.id), [
        'rep-1',
        'rep-2',
      ]);
      expect(options.representatives.map((option) => option.label), [
        'Ana',
        'Zé',
      ]);
      expect(options.companies.map((option) => option.id), ['c2', 'c1']);
      expect(options.companies.map((option) => option.label), [
        'Alfa Ltda',
        'Beta',
      ]);
    });

    test('usa #id quando o nome não veio e ignora orçamento sem vínculo', () {
      final options = quoteFilterOptions([
        _quote(id: 'q1', representativeId: 'rep-1'),
        _quote(id: 'q2'),
      ]);

      expect(options.representatives.single.label, '#rep-1');
      expect(options.companies, isEmpty);
    });
  });

  group('effectiveQuoteFilter', () {
    const options = [QuoteFilterOption(id: 'rep-1', label: 'Ana')];

    test('mantém um id presente nas opções', () {
      expect(effectiveQuoteFilter(options, 'rep-1'), 'rep-1');
    });

    test('zera filtro nulo ou que sumiu da lista', () {
      expect(effectiveQuoteFilter(options, null), isNull);
      expect(effectiveQuoteFilter(options, 'rep-9'), isNull);
    });
  });
}
