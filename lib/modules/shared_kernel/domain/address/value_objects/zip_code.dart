import 'package:ecommerce_b2b/modules/shared_kernel/domain/address/errors/zip_code_errors.dart';
import 'package:ecommerce_b2b/modules/shared_kernel/functional/result.dart';
import 'package:flutter/foundation.dart';

// TODO Tornar o ZIP Code compatível com todos os códigos postais do mundo, para endereços internacionais.

@immutable
class ZipCode {
  final String value;

  const ZipCode._(this.value);

  static Result<ZipCode, ZipCodeError> create(String input) {
    final digits = input.replaceAll(RegExp(r'\D'), '');

    if (digits.isEmpty) {
      return Failure(ZipCodeEmptyError());
    }

    if (digits.length != 8) {
      return Failure(ZipCodeLengthError());
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
