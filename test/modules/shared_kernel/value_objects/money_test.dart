import 'package:ecommerce_b2b/app/core/errors/app_error.dart';
import 'package:ecommerce_b2b/modules/shared_kernel/domain/finance/enums/currency.dart';
import 'package:ecommerce_b2b/modules/shared_kernel/domain/finance/value_objects/money.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Money', () {
    /// deve criar uma quantia monetária válida
    test('should create valid money', () {
      final result = Money.create(100.50);
      expect(result.isSuccess, isTrue);
      expect(result.getOrThrow().amount, 100.50);
      expect(result.getOrThrow().amountInCents, 10050);
    });

    /// deve retornar erro de valor negativo na criação
    test(
      'should return MoneyNegativeError for negative amount during creation',
      () {
        final result = Money.create(-1.0);
        expect(result.isFailure, isTrue);
        expect(result.getFailureOrThrow().code, AppErrorCodes.moneyNegative);
      },
    );

    /// deve somar quantias da mesma moeda
    test('should add money with same currency', () {
      final m1 = Money.create(50.0).getOrThrow();
      final m2 = Money.create(30.0).getOrThrow();
      final sum = m1 + m2;
      expect(sum.amount, 80.0);
    });

    /// deve lançar erro ao somar moedas diferentes
    test('should throw ArgumentError when adding different currencies', () {
      final m1 = Money.create(50.0, currency: Currency.brazil).getOrThrow();
      final m2 = Money.create(
        30.0,
        currency: Currency.unitedStates,
      ).getOrThrow();
      expect(() => m1 + m2, throwsArgumentError);
    });

    /// deve subtrair quantias monetárias
    test('should subtract money', () {
      final m1 = Money.create(100.0).getOrThrow();
      final m2 = Money.create(30.0).getOrThrow();
      final diff = m1 - m2;
      expect(diff.amount, 70.0);
    });

    /// deve lançar erro se o resultado da subtração for negativo
    test('should throw StateError if subtraction result is negative', () {
      final m1 = Money.create(30.0).getOrThrow();
      final m2 = Money.create(100.0).getOrThrow();
      expect(() => m1 - m2, throwsStateError);
    });

    /// deve lidar corretamente com precisão de ponto flutuante usando centavos
    test('should handle floating point precision correctly using cents', () {
      final m1 = Money.create(0.1).getOrThrow();
      final m2 = Money.create(0.2).getOrThrow();
      final sum = m1 + m2;
      expect(sum.amount, 0.3);
      expect(sum.amountInCents, 30);
    });
  });
}
