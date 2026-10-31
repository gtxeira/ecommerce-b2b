import 'package:ecommerce_b2b/app/core/errors/app_error.dart';
import 'package:ecommerce_b2b/app/core/result/result.dart';
import 'package:flutter/foundation.dart';

// TODO Tornar o ZIP Code compatível com todos os códigos postais do mundo, para endereços internacionais.

@immutable
class ZipCode {
  final String value;

  const ZipCode._(this.value);

  static Result<ZipCode, AppError> create(String input) {
    final digits = input.replaceAll(RegExp(r'\D'), '');

    if (digits.isEmpty) {
      return Failure(
        const AppError(
          AppErrorCodes.zipCodeEmpty,
          'O CEP não pode ser vazio',
          field: 'zipCode',
        ),
      );
    }

    if (digits.length != 8) {
      return Failure(
        const AppError(
          AppErrorCodes.zipCodeLength,
          'O CEP deve ter 8 dígitos.',
          field: 'zipCode',
        ),
      );
    }

    return Success(ZipCode._(digits));
  }

  String get formatted => '${value.substring(0, 5)}-${value.substring(5)}';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ZipCode &&
          runtimeType == other.runtimeType &&
          value == other.value;

  @override
  int get hashCode => value.hashCode;

  @override
  String toString() => value;
}
