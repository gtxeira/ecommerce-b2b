import 'package:ecommerce_b2b/app/core/format/date_format.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('formatDate', () {
    test('formata dd/MM/yyyy com zero à esquerda', () {
      expect(formatDate(DateTime(2026, 9, 5)), '05/09/2026');
      expect(formatDate(DateTime(2026, 12, 21)), '21/12/2026');
    });
  });

  group('formatDateTime', () {
    test('inclui hora e minuto com zero à esquerda', () {
      expect(formatDateTime(DateTime(2026, 9, 5, 9, 7)), '05/09/2026 09:07');
      expect(formatDateTime(DateTime(2026, 9, 5, 23, 59)), '05/09/2026 23:59');
    });
  });

  group('variações tolerantes a nulo', () {
    test('formatDateOrDash', () {
      expect(formatDateOrDash(null), '-');
      expect(formatDateOrDash(DateTime(2026, 1, 2)), '02/01/2026');
    });

    test('formatDateTimeOrDash', () {
      expect(formatDateTimeOrDash(null), '-');
      expect(
        formatDateTimeOrDash(DateTime(2026, 1, 2, 3, 4)),
        '02/01/2026 03:04',
      );
    });
  });
}
