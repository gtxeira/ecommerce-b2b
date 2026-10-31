import 'package:ecommerce_b2b/app/core/errors/app_error.dart';
import 'package:ecommerce_b2b/app/core/result/result.dart';
import 'package:flutter/foundation.dart';

/// Objeto de Valor que representa um endereço de e-mail válido.
@immutable
class EmailAddress {
  final String value;

  const EmailAddress._(this.value);

  /// Cria uma instância de [EmailAddress] após validar o formato do input.
  /// Normaliza o e-mail para letras minúsculas.
  static Result<EmailAddress, AppError> create(String input) {
    if (input.trim().isEmpty) {
      return Failure(
        const AppError(
          AppErrorCodes.emailEmpty,
          'O e-mail não pode ser vazio.',
          field: 'email',
        ),
      );
    }

    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );

    if (!emailRegex.hasMatch(input)) {
      return Failure(
        const AppError(
          AppErrorCodes.emailInvalid,
          'O endereço de e-mail é inválido.',
          field: 'email',
        ),
      );
    }

    return Success(EmailAddress._(input.trim().toLowerCase()));
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EmailAddress &&
          runtimeType == other.runtimeType &&
          value == other.value;

  @override
  int get hashCode => value.hashCode;

  @override
  String toString() => value;
}
