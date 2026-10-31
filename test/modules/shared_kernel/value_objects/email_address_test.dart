import 'package:ecommerce_b2b/app/core/errors/app_error.dart';
import 'package:ecommerce_b2b/modules/shared_kernel/domain/contact/value_objects/email_address.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('EmailAddress', () {
    /// deve criar um endereço de e-mail válido
    test('should create a valid email address', () {
      final result = EmailAddress.create('test@example.com');
      expect(result.isSuccess, isTrue);
      expect(result.getOrThrow().value, 'test@example.com');
    });

    /// deve normalizar o e-mail para letras minúsculas
    test('should normalize email to lowercase', () {
      final result = EmailAddress.create('TEST@EXAMPLE.COM');
      expect(result.getOrThrow().value, 'test@example.com');
    });

    /// deve retornar erro de e-mail vazio quando a entrada estiver vazia
    test('should return EmailEmptyError when input is empty', () {
      final result = EmailAddress.create('');
      expect(result.isFailure, isTrue);
      expect(result.getFailureOrThrow().code, AppErrorCodes.emailEmpty);
    });

    /// deve retornar erro de e-mail inválido quando a entrada for inválida
    test('should return EmailInvalidError when input is invalid', () {
      final result = EmailAddress.create('invalid-email');
      expect(result.isFailure, isTrue);
      expect(result.getFailureOrThrow().code, AppErrorCodes.emailInvalid);
    });
  });
}
