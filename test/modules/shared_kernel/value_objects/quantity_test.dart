import 'package:ecommerce_b2b/app/core/errors/app_error.dart';
import 'package:ecommerce_b2b/modules/shared_kernel/model/finance/value_objects/quantity.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Quantity', () {
    /// deve criar uma quantidade válida
    test('should create valid quantity', () {
      final result = Quantity.create(10);
      expect(result.isSuccess, isTrue);
      expect(result.getOrThrow().value, 10);
    });

    /// deve retornar erro de quantidade negativa para valores negativos
    test('should return QuantityNegativeError for negative values', () {
      final result = Quantity.create(-1);
      expect(result.isFailure, isTrue);
      expect(result.getFailureOrThrow().code, AppErrorCodes.quantityNegative);
    });

    /// deve somar quantidades
    test('should add quantities', () {
      final q1 = Quantity.create(10).getOrThrow();
      final q2 = Quantity.create(5).getOrThrow();
      expect((q1 + q2).value, 15);
    });

    /// deve subtrair quantidades
    test('should subtract quantities', () {
      final q1 = Quantity.create(10).getOrThrow();
      final q2 = Quantity.create(3).getOrThrow();
      expect((q1 - q2).value, 7);
    });

    /// deve lançar erro se a subtração resultar em valor negativo
    test('should throw StateError if subtraction results in negative', () {
      final q1 = Quantity.create(5).getOrThrow();
      final q2 = Quantity.create(10).getOrThrow();
      expect(() => q1 - q2, throwsStateError);
    });
  });
}
