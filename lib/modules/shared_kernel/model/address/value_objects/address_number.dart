import 'package:ecommerce_b2b/app/core/errors/app_error.dart';
import 'package:ecommerce_b2b/app/core/result/result.dart';
import 'package:flutter/foundation.dart';

@immutable
class AddressNumber {
  final String value;

  const AddressNumber._(this.value);

  static Result<AddressNumber, AppError> create(String input) {
    final trimmed = input.trim();

    if (trimmed.isEmpty) {
      return Failure(
        const AppError(
          AppErrorCodes.addressNumberEmpty,
          'O número não pode ser vazio.',
          field: 'number',
        ),
      );
    }

    if (trimmed.length > 10) {
      return Failure(
        const AppError(
          AppErrorCodes.addressNumberTooLong,
          'O número não pode ter mais de 10 caracteres.',
          field: 'number',
        ),
      );
    }

    return Success(AddressNumber._(trimmed));
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AddressNumber &&
          runtimeType == other.runtimeType &&
          value == other.value;

  @override
  int get hashCode => value.hashCode;

  @override
  String toString() => value;
}
