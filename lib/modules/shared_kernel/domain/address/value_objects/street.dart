import 'package:ecommerce_b2b/modules/shared_kernel/domain/address/errors/street_errors.dart';
import 'package:ecommerce_b2b/modules/shared_kernel/functional/result.dart';
import 'package:flutter/foundation.dart';

/// Objeto de Valor que representa uma rua válida.
@immutable
class Street {
  final String value;

  const Street._(this.value);

  static Result<Street, StreetError> create(String input) {
    final trimmed = input.trim();

    if (trimmed.isEmpty) {
      return Failure(StreetEmptyError());
    }

    // O menor tamanho do nome de uma rua pode ser de 1 caractere (como 'Rua A').
    // O maior tamanho do nome de uma rua foi de 72 caracteres
    // ("rua Dwudziestego Pierwszego Praskiego Pułku Piechoty imienia Dzieci Warszawy" na Polônia)
    if (trimmed.length > 100) {
      return Failure(StreetTooLongError());
    }

    return Success(Street._(trimmed));
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Street &&
          runtimeType == other.runtimeType &&
          value == other.value;

  @override
  int get hashCode => value.hashCode;

  @override
  String toString() => value;
}
