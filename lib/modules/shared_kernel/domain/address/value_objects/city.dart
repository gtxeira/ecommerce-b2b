import 'package:ecommerce_b2b/modules/shared_kernel/domain/address/errors/city_errors.dart';
import 'package:ecommerce_b2b/modules/shared_kernel/functional/result.dart';
import 'package:flutter/foundation.dart';

/// Objeto de Valor que representa uma cidade válida.
@immutable
class City {
  final String value;

  const City._(this.value);

  static Result<City, CityError> create(String input) {
    final trimmed = input.trim();

    if (trimmed.isEmpty) {
      return Failure(CityEmptyError());
    }

    // O menor tamanho do nome de uma cidade pode ser de 1 caractere (como 'Y' na França).
    // O maior nome de um local habitável foi de 85 caracteres
    // ("Taumatawhakatangihangakoauauotamateaturipukakapikimaungahoronukupokaiwhenuakitanatahu" na Nova Zelândia),
    // mas foi deixado com 100 caracteres para uma margem de segurança.
    if (trimmed.length > 100) {
      return Failure(CityTooLongError());
    }

    return Success(City._(trimmed));
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is City &&
          runtimeType == other.runtimeType &&
          value == other.value;

  @override
  int get hashCode => value.hashCode;

  @override
  String toString() => value;
}
