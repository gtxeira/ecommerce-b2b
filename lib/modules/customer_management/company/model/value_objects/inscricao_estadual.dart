import 'package:ecommerce_b2b/app/core/errors/app_error.dart';
import 'package:ecommerce_b2b/app/core/result/result.dart';
import 'package:flutter/foundation.dart';

/// Value Object para Inscrição Estadual (IE).
///
/// Representa o número de registro fiscal estadual.
/// A lógica de isenção deve ser tratada na Entidade que utiliza este objeto.
@immutable
class InscricaoEstadual {
  final String value;

  const InscricaoEstadual._(this.value);

  /// Cria uma instância de [InscricaoEstadual] validando se contém apenas dígitos
  /// e se possui o comprimento padrão (8 a 14 dígitos).
  static Result<InscricaoEstadual, AppError> create(String input) {
    final digits = _onlyDigits(input.trim());

    if (digits.isEmpty) {
      return Failure(
        const AppError(
          AppErrorCodes.inscricaoEstadualEmpty,
          'A inscrição estadual não pode ser vazia.',
          field: 'inscricaoEstadual',
        ),
      );
    }

    // Validação básica de comprimento para IE no Brasil.
    // Nota: Futuramente pode ser expandido para validar por UF.
    if (digits.length < 8 || digits.length > 14) {
      return Failure(
        const AppError(
          AppErrorCodes.inscricaoEstadualInvalid,
          'A inscrição estadual é inválida.',
          field: 'inscricaoEstadual',
        ),
      );
    }

    return Success(InscricaoEstadual._(digits));
  }

  static String _onlyDigits(String s) => s.replaceAll(RegExp(r'\D'), '');

  @override
  String toString() => value;

  @override
  bool operator ==(Object other) =>
      other is InscricaoEstadual && other.value == value;

  @override
  int get hashCode => value.hashCode;
}
