import 'package:ecommerce_b2b/app/core/errors/app_error.dart';
import 'package:ecommerce_b2b/app/core/result/result.dart';
import 'package:flutter/foundation.dart';

@immutable
class AddressComplement {
  final String value;

  const AddressComplement._(this.value);

  /// Cria [AddressComplement] a partir de uma string.
  static Result<AddressComplement, AppError> create(String input) {
    final trimmed = input.trim();

    if (trimmed.isEmpty) {
      return Failure(
        const AppError(
          AppErrorCodes.addressComplementEmpty,
          'O complemento não pode ser vazio.',
          field: 'complement',
        ),
      );
    }

    // Limite usado pelo SEFAZ (de 60 a 100 caracteres).
    if (trimmed.length > 60) {
      return Failure(
        const AppError(
          AppErrorCodes.addressComplementTooLong,
          'O complemento não pode ter mais de 60 caracteres.',
          field: 'complement',
        ),
      );
    }

    return Success(AddressComplement._(trimmed));
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AddressComplement &&
          runtimeType == other.runtimeType &&
          value == other.value;

  @override
  int get hashCode => value.hashCode;

  @override
  String toString() => value;
}
