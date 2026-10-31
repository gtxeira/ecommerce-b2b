import 'package:ecommerce_b2b/app/core/errors/app_error.dart';
import 'package:ecommerce_b2b/modules/customer_management/company/domain/value_objects/inscricao_estadual.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('InscricaoEstadual', () {
    /// deve criar uma Inscrição Estadual válida
    test('should create valid IE', () {
      final result = InscricaoEstadual.create('123.456.789-01');
      expect(result.isSuccess, isTrue);
      expect(result.getOrThrow().value, '12345678901');
    });

    /// deve retornar InscricaoEstadualEmptyError para entrada vazia
    test('should return InscricaoEstadualEmptyError for empty input', () {
      final result = InscricaoEstadual.create('');
      expect(result.isFailure, isTrue);
      expect(
        result.getFailureOrThrow().code,
        AppErrorCodes.inscricaoEstadualEmpty,
      );
    });

    /// deve retornar InscricaoEstadualEmptyError para entrada apenas com espaços em branco
    test(
      'should return InscricaoEstadualEmptyError for whitespace-only input',
      () {
        final result = InscricaoEstadual.create('  ');
        expect(result.isFailure, isTrue);
        expect(
          result.getFailureOrThrow().code,
          AppErrorCodes.inscricaoEstadualEmpty,
        );
      },
    );

    /// deve retornar InscricaoEstadualInvalidError para entrada muito curta
    test('should return InscricaoEstadualInvalidError for too short input', () {
      final result = InscricaoEstadual.create('123');
      expect(result.isFailure, isTrue);
      expect(
        result.getFailureOrThrow().code,
        AppErrorCodes.inscricaoEstadualInvalid,
      );
    });

    /// deve ser igual a outro objeto com o mesmo valor
    test('should equal other with same value', () {
      final ie1 = InscricaoEstadual.create('123.456.789-01').getOrThrow();
      final ie2 = InscricaoEstadual.create('123.456.789-01').getOrThrow();
      expect(ie1, equals(ie2));
    });
  });
}
