import 'package:ecommerce_b2b/app/core/format/display_labels.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('formatId', () {
    test('prefixa o ID com #', () {
      expect(formatId('order-102'), '#order-102');
    });
  });

  group('companyLabel', () {
    test('fantasia (razão) · #id', () {
      expect(
        companyLabel(
          tradeName: 'ABC Distribuidora',
          legalName: 'Distribuidora ABC Ltda',
          id: 'c1',
        ),
        'ABC Distribuidora (Distribuidora ABC Ltda) · #c1',
      );
    });

    test('não repete nome quando fantasia e razão são iguais', () {
      expect(
        companyLabel(tradeName: 'ABC', legalName: 'ABC', id: 'c1'),
        'ABC · #c1',
      );
    });

    test('usa o nome disponível quando o outro falta', () {
      expect(companyLabel(tradeName: 'ABC', id: 'c1'), 'ABC · #c1');
      expect(
        companyLabel(legalName: 'Distribuidora ABC Ltda', id: 'c1'),
        'Distribuidora ABC Ltda · #c1',
      );
    });

    test('sinaliza empresa não encontrada', () {
      expect(companyLabel(id: 'c1'), 'Empresa não encontrada · #c1');
    });
  });

  group('productLabel', () {
    test('nome (sku) · #id', () {
      expect(
        productLabel(name: 'Notebook', sku: 'SKU-1', id: 'p1'),
        'Notebook (SKU-1) · #p1',
      );
    });

    test('tolera SKU ausente', () {
      expect(productLabel(name: 'Notebook', id: 'p1'), 'Notebook · #p1');
    });

    test('sinaliza produto não encontrado', () {
      expect(productLabel(id: 'p1'), 'Produto não encontrado · #p1');
    });

    test('usa o SKU e o rótulo da variante quando informados', () {
      expect(
        productLabel(
          name: 'Notebook',
          sku: 'SKU-1',
          variantSku: 'SKU-1-V2',
          variantLabel: 'Prata · 15pol',
          id: 'p1',
        ),
        'Notebook (SKU-1-V2) · Prata · 15pol · #p1',
      );
    });
  });

  group('personLabel', () {
    test('nome (papel) · #id', () {
      expect(
        personLabel(name: 'Maria Financeiro', role: 'Finance', id: 'fin-1'),
        'Maria Financeiro (Financeiro) · #fin-1',
      );
    });

    test('sem nome cai no papel', () {
      expect(personLabel(role: 'System', id: 'sys'), 'Sistema · #sys');
    });

    test('sem papel cai no nome', () {
      expect(personLabel(name: 'Maria', id: 'u1'), 'Maria · #u1');
    });

    test('sem nome nem papel usa "Usuário"', () {
      expect(personLabel(id: 'u1'), 'Usuário · #u1');
    });
  });
}
