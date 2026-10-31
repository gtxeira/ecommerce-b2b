import 'package:ecommerce_b2b/modules/shared_kernel/domain/finance/errors/quantity_errors.dart';
import 'package:ecommerce_b2b/modules/shared_kernel/functional/result.dart';
import 'package:flutter/foundation.dart';

/// Objeto de Valor que representa uma quantidade válida.
@immutable
class Quantity {
  final int value;

  const Quantity._(this.value);

  /// Cria uma instância de [Quantity] a partir de um valor inteiro.
  /// Retorna [Failure] se o valor for negativo.
  static Result<Quantity, QuantityError> create(int value) {
    if (value < 0) {
      return Failure(QuantityNegativeError());
    }
    return Success(Quantity._(value));
  }

  Quantity operator +(Quantity other) => Quantity._(value + other.value);

  /// Subtrai duas quantidades.
  /// Lança [StateError] se o resultado for negativo.
  Quantity operator -(Quantity other) {
    final result = value - other.value;
    if (result < 0) {
      throw StateError('A quantidade não pode ser negativa após a subtração');
    }
    return Quantity._(result);
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Quantity &&
          runtimeType == other.runtimeType &&
          value == other.value;

  @override
  int get hashCode => value.hashCode;

  @override
  String toString() => value.toString();
}
