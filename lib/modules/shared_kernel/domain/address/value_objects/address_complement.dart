import 'package:ecommerce_b2b/modules/shared_kernel/domain/address/errors/address_complement_errors.dart';
import 'package:ecommerce_b2b/modules/shared_kernel/functional/result.dart';
import 'package:flutter/foundation.dart';

@immutable
class AddressComplement {
  final String value;

  const AddressComplement._(this.value);

  /// Cria [AddressComplement] a partir de uma string.
  static Result<AddressComplement, AddressComplementError> create(String input) {
    final trimmed = input.trim();

    if (trimmed.isEmpty) {
      return Failure(AddressComplementEmptyError());
    }

    // Limite usado pelo SEFAZ (de 60 a 100 caracteres).
    if (trimmed.length > 60) {
      return Failure(AddressComplementTooLongError());
    }

    return Success(AddressComplement._(trimmed));
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
          other is AddressComplement && runtimeType == other.runtimeType && value == other.value;

  @override
  int get hashCode => value.hashCode;

  @override
  String toString() => value;
}