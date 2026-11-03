import 'package:ecommerce_b2b/app/core/errors/app_error.dart';
import 'package:ecommerce_b2b/modules/shared_kernel/model/finance/enums/currency.dart';
import 'package:ecommerce_b2b/app/core/result/result.dart';
import 'package:flutter/foundation.dart';

// TODO: Migrar para utilizar os pacotes decimal/decimal.dart ou money2/money2:

/// Objeto de Valor que representa quantias monetárias.
/// Utiliza inteiros (centavos) internamente para evitar erros de precisão decimal.
@immutable
class Money {
  /// Valor total em centavos.
  final int amountInCents;

  /// Código da moeda (ex: BRL, USD).
  final Currency currency;

  const Money._(this.amountInCents, {this.currency = Currency.brazil});

  /// Cria uma instância de [Money] a partir de um valor decimal.
  /// Retorna [Failure] se o valor for negativo.
  static Result<Money, AppError> create(
    double amount, {
    Currency currency = Currency.brazil,
  }) {
    if (amount < 0) {
      return Failure(
        const AppError(
          AppErrorCodes.moneyNegative,
          'O valor monetário não pode ser negativo.',
        ),
      );
    }

    final cents = (amount * 100).round();
    return Success(Money._(cents, currency: currency));
  }

  /// Retorna o valor convertido para decimal (unidade principal da moeda).
  double get amount => amountInCents / 100;

  /// Soma duas quantias monetárias.
  /// Lança [ArgumentError] se as moedas forem diferentes.
  Money operator +(Money other) {
    if (currency != other.currency) {
      throw ArgumentError(
        'Money currency mismatch: $currency vs ${other.currency}',
      );
    }

    return Money._(amountInCents + other.amountInCents, currency: currency);
  }

  /// Subtrai duas quantias monetárias.
  /// Lança [ArgumentError] se as moedas forem diferentes.
  /// Lança [StateError] se o resultado for negativo.
  Money operator -(Money other) {
    if (currency != other.currency) {
      throw ArgumentError(
        'Money currency mismatch: $currency vs ${other.currency}',
      );
    }

    final result = amountInCents - other.amountInCents;
    if (result < 0) {
      throw StateError(
        'O valor monetário não pode ser negativo após a subtração',
      );
    }

    return Money._(result, currency: currency);
  }

  String get formatted {
    final String decimalSeparator = currency == Currency.brazil ? ',' : '.';
    final String thousandSeparator = currency == Currency.brazil ? '.' : ',';
    final String units = (amountInCents ~/ 100).toString();
    final String cents = (amountInCents % 100).toString().padLeft(2, '0');
    final String formattedUnits = _formatUnits(units, thousandSeparator);

    return '${currency.symbol} $formattedUnits$decimalSeparator$cents';
  }

  String _formatUnits(String value, String separator) {
    final buffer = StringBuffer();
    final reversed = value.split('').reversed.toList();

    for (var i = 0; i < reversed.length; i++) {
      if (i != 0 && i % 3 == 0) {
        buffer.write(separator);
      }
      buffer.write(reversed[i]);
    }

    return buffer.toString().split('').reversed.join();
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Money &&
          runtimeType == other.runtimeType &&
          amountInCents == other.amountInCents &&
          currency == other.currency;

  @override
  int get hashCode => amountInCents.hashCode ^ currency.hashCode;

  @override
  String toString() => formatted;
}
