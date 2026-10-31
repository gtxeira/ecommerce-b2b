import 'package:ecommerce_b2b/modules/customer_management/company/domain/errors/cnpj_errors.dart';
import 'package:ecommerce_b2b/modules/shared_kernel/functional/result.dart';
import 'package:flutter/foundation.dart';

/// Value Object para CNPJ (Cadastro Nacional da Pessoa Jurídica)
@immutable
class Cnpj {
  final String value;

  const Cnpj._(this.value);

  /// Creates a valid [Cnpj] instance or returns a [CnpjError].
  static Result<Cnpj, CnpjError> create(String input) {
    if (input.trim().isEmpty) {
      return Failure(CnpjEmptyError());
    }

    final digits = _onlyDigits(input);

    if (digits.length != 14) {
      return Failure(CnpjInvalidLengthError(digits.length));
    }

    // Reject sequences (ex: 00000000000000, 11111111111111)
    if (RegExp(r'^(\d)\1*$').hasMatch(digits)) {
      return Failure(CnpjInvalidError());
    }

    if (!_validateCheckDigits(digits)) {
      return Failure(CnpjInvalidVerificationDigitsError());
    }

    return Success(Cnpj._(digits));
  }

  static String _onlyDigits(String s) => s.replaceAll(RegExp(r'\D'), '');

  static bool _validateCheckDigits(String digits) {
    final numbers = digits.split('').map(int.parse).toList();

    int calcDigit(List<int> nums, List<int> weights) {
      var sum = 0;
      for (var i = 0; i < weights.length; i++) {
        sum += nums[i] * weights[i];
      }
      final mod = sum % 11;
      return mod < 2 ? 0 : 11 - mod;
    }

    final firstWeights = [5, 4, 3, 2, 9, 8, 7, 6, 5, 4, 3, 2];
    final secondWeights = [6] + firstWeights;

    final dv1 = calcDigit(numbers, firstWeights);
    if (dv1 != numbers[12]) return false;

    final dv2 = calcDigit([...numbers.sublist(0, 12), dv1], secondWeights);
    if (dv2 != numbers[13]) return false;

    return true;
  }

  String get formatted {
    return value.replaceFirstMapped(
      RegExp(r'^(\d{2})(\d{3})(\d{3})(\d{4})(\d{2})$'),
      (m) => '${m[1]}.${m[2]}.${m[3]}/${m[4]}-${m[5]}',
    );
  }

  /// Retorna o valor do CNPJ (que é armazenado sem formatação)
  @override
  String toString() => value;

  @override
  bool operator ==(Object other) => other is Cnpj && other.value == value;

  @override
  int get hashCode => value.hashCode;
}