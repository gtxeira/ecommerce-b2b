import 'package:ecommerce_b2b/modules/shared_kernel/domain/address/errors/neighborhood_errors.dart';
import 'package:ecommerce_b2b/modules/shared_kernel/functional/result.dart';
import 'package:flutter/foundation.dart';

@immutable
class Neighborhood {
  final String value;

  const Neighborhood._(this.value);

  static Result<Neighborhood, NeighborhoodError> create(String input) {
    final trimmed = input.trim();

    if (trimmed.isEmpty) {
      return Failure(NeighborhoodEmptyError());
    }

    // O menor tamanho do nome de um bairro ser de 1 caractere.
    // O maior nome encontrado para um bairro foi de 58 caracteres
    // ("Llanfairpwllgwyngyllgogerychwyrndrobwllllantysiliogogogoch" no Páis de Gales)
    if (trimmed.length > 70) {
      return Failure(NeighborhoodTooLongError());
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
