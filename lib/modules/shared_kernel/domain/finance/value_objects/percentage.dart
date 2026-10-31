import 'package:ecommerce_b2b/app/core/errors/app_error.dart';
import 'package:ecommerce_b2b/app/core/result/result.dart';
import 'package:flutter/foundation.dart';

/// Objeto de Valor que representa uma porcentagem válida.
@immutable
class Percentage {
  final double value;

  const Percentage._(this.value);

  /// Cria uma instância de [Percentage] a partir de um valor decimal.
  /// Retorna [Failure] se o valor estiver fora do intervalo [0, 100].
  static Result<Percentage, AppError> create(double value) {
    if (value < 0 || value > 100) {
      return Failure(
        const AppError(
          AppErrorCodes.percentageOutOfRange,
          'A porcentagem deve estar entre 0 e 100.',
        ),
      );
    }
    return Success(Percentage._(value));
  }

  double get decimal => value / 100;

  String get formatted => '${value.toStringAsFixed(2)}%';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Percentage &&
          runtimeType == other.runtimeType &&
          value == other.value;

  @override
  int get hashCode => value.hashCode;

  @override
  String toString() => formatted;
}
