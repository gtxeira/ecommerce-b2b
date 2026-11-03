import 'package:ecommerce_b2b/app/core/errors/app_error.dart';
import 'package:ecommerce_b2b/modules/shared_kernel/model/finance/value_objects/percentage.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Percentage', () {
    /// deve criar uma porcentagem válida
    test('should create valid percentage', () {
      final result = Percentage.create(15.5);
      expect(result.isSuccess, isTrue);
      expect(result.getOrThrow().value, 15.5);
      expect(result.getOrThrow().decimal, 0.155);
    });

    /// deve retornar erro de porcentagem fora do intervalo para valores menores que zero
    test('should return PercentageOutOfRangeError for values < 0', () {
      final result = Percentage.create(-1.0);
      expect(result.isFailure, isTrue);
      expect(
        result.getFailureOrThrow().code,
        AppErrorCodes.percentageOutOfRange,
      );
    });

    /// deve retornar erro de porcentagem fora do intervalo para valores maiores que cem
    test('should return PercentageOutOfRangeError for values > 100', () {
      final result = Percentage.create(100.1);
      expect(result.isFailure, isTrue);
      expect(
        result.getFailureOrThrow().code,
        AppErrorCodes.percentageOutOfRange,
      );
    });

    /// toString deve formatar corretamente
    test('toString should format correctly', () {
      final p = Percentage.create(10).getOrThrow();
      expect(p.toString(), '10.00%');
    });
  });
}
