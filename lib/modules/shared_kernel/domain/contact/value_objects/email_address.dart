import 'package:ecommerce_b2b/modules/shared_kernel/domain/contact/errors/email_errors.dart';
import 'package:ecommerce_b2b/modules/shared_kernel/functional/result.dart';
import 'package:flutter/foundation.dart';

/// Objeto de Valor que representa um endereço de e-mail válido.
@immutable
class EmailAddress {
  final String value;

  const EmailAddress._(this.value);

  /// Cria uma instância de [EmailAddress] após validar o formato do input.
  /// Normaliza o e-mail para letras minúsculas.
  static Result<EmailAddress, EmailError> create(String input) {
    if (input.trim().isEmpty) {
      return Failure(EmailEmptyError());
    }

    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );

    if (!emailRegex.hasMatch(input)) {
      return Failure(EmailInvalidError());
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
