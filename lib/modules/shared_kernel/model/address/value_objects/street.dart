import 'package:ecommerce_b2b/app/core/errors/app_error.dart';
import 'package:ecommerce_b2b/app/core/result/result.dart';
import 'package:flutter/foundation.dart';

/// Objeto de Valor que representa uma rua válida.
@immutable
class Street {
  final String value;

  const Street._(this.value);

  static Result<Street, AppError> create(String input) {
    final trimmed = input.trim();

    if (trimmed.isEmpty) {
      return Failure(
        const AppError(
          AppErrorCodes.streetEmpty,
          'O logradouro não pode ser vazio',
          field: 'street',
        ),
      );
    }

    // O menor tamanho do nome de uma rua pode ser de 1 caractere (como 'Rua A').
    // O maior tamanho do nome de uma rua foi de 72 caracteres
    // ("rua Dwudziestego Pierwszego Praskiego Pułku Piechoty imienia Dzieci Warszawy" na Polônia)
    if (trimmed.length > 100) {
      return Failure(
        const AppError(
          AppErrorCodes.streetTooLong,
          'O logradouro não pode ter mais de 100 caracteres.',
          field: 'street',
        ),
      );
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
