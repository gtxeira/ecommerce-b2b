import 'package:ecommerce_b2b/app/core/errors/app_error.dart';
import 'package:ecommerce_b2b/modules/customer_management/company/domain/value_objects/cnpj.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Cnpj', () {
    /// deve criar um CNPJ válido
    test('should create valid CNPJ', () {
      // Valid CNPJ generated for testing
      final result = Cnpj.create('11.222.333/0001-81');
      expect(result.isSuccess, isTrue);
      expect(result.getOrThrow().value, '11222333000181');
    });

    /// deve retornar erro de CNPJ vazio para entrada vazia
    test('should return CnpjEmptyError for empty input', () {
      final result = Cnpj.create('');
      expect(result.isFailure, isTrue);
      expect(result.getFailureOrThrow().code, AppErrorCodes.cnpjEmpty);
    });

    /// deve retornar erro de tamanho inválido para comprimento incorreto
    test('should return CnpjInvalidLengthError for incorrect length', () {
      final result = Cnpj.create('123');
      expect(result.isFailure, isTrue);
      expect(result.getFailureOrThrow().code, AppErrorCodes.cnpjInvalidLength);
    });

    /// deve retornar erro de CNPJ inválido para números sequenciais
    test('should return CnpjInvalidError for with sequential numbers', () {
      final result = Cnpj.create('11.111.111/1111-11');
      expect(result.isFailure, isTrue);
      expect(result.getFailureOrThrow().code, AppErrorCodes.cnpjInvalid);
    });

    /// deve retornar erro de dígitos verificadores inválidos para dígitos incorretos
    test(
      'should return CnpjInvalidVerificationDigitsError for wrong digits',
      () {
        final result = Cnpj.create('11.222.333/0001-00');
        expect(result.isFailure, isTrue);
        expect(
          result.getFailureOrThrow().code,
          AppErrorCodes.cnpjInvalidVerificationDigits,
        );
      },
    );
  });
}
