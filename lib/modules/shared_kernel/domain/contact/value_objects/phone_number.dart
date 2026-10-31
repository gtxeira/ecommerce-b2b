import 'package:ecommerce_b2b/app/core/errors/app_error.dart';
import 'package:ecommerce_b2b/app/core/result/result.dart';
import 'package:flutter/foundation.dart';

/// Objeto de Valor que representa um número de telefone no padrão internacional E.164.
/// O formato E.164 garante que o número inclua o código do país, DDD e número,
/// começando com o caractere '+' seguido apenas por dígitos (máximo 15 dígitos).
@immutable
class PhoneNumber {
  /// O número de telefone no formato E.164 (ex: +5511999998888).
  final String value;

  const PhoneNumber._(this.value);

  /// Cria uma instância de [PhoneNumber] validando o padrão E.164.
  /// Aceita inputs com formatação variada, mas normaliza para +DDI...
  static Result<PhoneNumber, AppError> create(String input) {
    final trimmed = input.trim();
    if (trimmed.isEmpty) {
      return Failure(
        const AppError(
          AppErrorCodes.phoneNumberEmpty,
          'O telefone não pode ser vazio.',
          field: 'phone',
        ),
      );
    }

    // Remove tudo que não for dígito (incluindo '+')
    final digits = trimmed.replaceAll(RegExp(r'\D'), '');

    // O padrão E.164 recomenda: [+][código do país][assinante]
    // Mínimo costuma ser 7 (ex: países pequenos) e máximo 15.
    if (digits.length < 7 || digits.length > 15) {
      return Failure(
        const AppError(
          AppErrorCodes.phoneNumberInvalid,
          'O número de telefone é inválido.',
          field: 'phone',
        ),
      );
    }

    // Se não tinha '+', assume que deve ser adicionado (DDI deve estar incluso nos dígitos)
    final formatted = '+$digits';

    return Success(PhoneNumber._(formatted));
  }

  String get formatted {
    if (!value.startsWith('+55')) {
      return value;
    }

    final digits = value.replaceAll(RegExp(r'\D'), '');
    final ddd = digits.substring(2, 4);
    final subscriber = digits.substring(4);

    if (subscriber.length == 9) {
      return '($ddd) ${subscriber.substring(0, 5)}-${subscriber.substring(5)}';
    }

    if (subscriber.length == 8) {
      return '($ddd) ${subscriber.substring(0, 4)}-${subscriber.substring(4)}';
    }

    return value;
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PhoneNumber &&
          runtimeType == other.runtimeType &&
          value == other.value;

  @override
  int get hashCode => value.hashCode;

  @override
  String toString() => value;
}
