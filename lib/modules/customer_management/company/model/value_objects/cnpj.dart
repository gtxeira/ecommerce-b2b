import 'package:ecommerce_b2b/app/core/errors/app_error.dart';
import 'package:ecommerce_b2b/app/core/result/result.dart';
import 'package:flutter/foundation.dart';

/// Value Object para CNPJ (Cadastro Nacional da Pessoa Jurídica)
@immutable
class Cnpj {
  final String value;

  const Cnpj._(this.value);

  /// Creates a valid [Cnpj] instance or returns an [AppError].
  static Result<Cnpj, AppError> create(String input) {
    if (input.trim().isEmpty) {
      return Failure(
        const AppError(
          AppErrorCodes.cnpjEmpty,
          'O CNPJ não pode ser vazio.',
          field: 'cnpj',
        ),
      );
    }

    final digits = _onlyDigits(input);

    if (digits.length != 14) {
      return Failure(
        AppError(
          AppErrorCodes.cnpjInvalidLength,
          'O CNPJ deve conter exatamente 14 dígitos (encontrados ${digits.length}).',
          field: 'cnpj',
        ),
      );
    }

    // Reject sequences (ex: 00000000000000, 11111111111111)
    if (RegExp(r'^(\d)\1*$').hasMatch(digits)) {
      return Failure(
        const AppError(
          AppErrorCodes.cnpjInvalid,
          'O número do CNPJ é inválido.',
          field: 'cnpj',
        ),
      );
    }

    if (!_validateCheckDigits(digits)) {
      return Failure(
        const AppError(
          AppErrorCodes.cnpjInvalidVerificationDigits,
          'O número do CNPJ é inválido (dígitos verificadores não coincidem).',
          field: 'cnpj',
        ),
      );
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
