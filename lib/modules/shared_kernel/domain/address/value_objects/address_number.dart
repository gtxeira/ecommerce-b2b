import 'package:ecommerce_b2b/modules/shared_kernel/domain/address/errors/address_number_errors.dart';
import 'package:ecommerce_b2b/modules/shared_kernel/functional/result.dart';
import 'package:flutter/foundation.dart';

@immutable
class AddressNumber {
  final String value;

  const AddressNumber._(this.value);

  static Result<AddressNumber, AddressNumberError> create(String input) {
    final trimmed = input.trim();

    if (trimmed.isEmpty) {
      return Failure(AddressNumberEmptyError());
    }

    if (trimmed.length > 10) {
      return Failure(AddressNumberTooLongError());
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
