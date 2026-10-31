import 'package:ecommerce_b2b/app/core/errors/app_error.dart';
import 'package:ecommerce_b2b/app/core/result/result.dart';
import 'package:flutter/foundation.dart';

@immutable
class Neighborhood {
  final String value;

  const Neighborhood._(this.value);

  static Result<Neighborhood, AppError> create(String input) {
    final trimmed = input.trim();

    if (trimmed.isEmpty) {
      return Failure(
        const AppError(
          AppErrorCodes.neighborhoodEmpty,
          'O bairro não pode ser vazio',
          field: 'neighborhood',
        ),
      );
    }

    // O menor tamanho do nome de um bairro ser de 1 caractere.
    // O maior nome encontrado para um bairro foi de 58 caracteres
    // ("Llanfairpwllgwyngyllgogerychwyrndrobwllllantysiliogogogoch" no Páis de Gales)
    if (trimmed.length > 70) {
      return Failure(
        const AppError(
          AppErrorCodes.neighborhoodTooLong,
          'O bairro não pode ter mais de 70 caracteres.',
          field: 'neighborhood',
        ),
      );
    }

    return Success(Neighborhood._(trimmed));
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Neighborhood &&
          runtimeType == other.runtimeType &&
          value == other.value;

  @override
  int get hashCode => value.hashCode;

  @override
  String toString() => value;
}
