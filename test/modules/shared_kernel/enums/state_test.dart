import 'package:ecommerce_b2b/app/core/errors/app_error.dart';
import 'package:ecommerce_b2b/modules/shared_kernel/model/address/enums/state.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('State Enum', () {
    /// deve retornar Success para um código de estado válido
    test('should return Success for valid state code', () {
      final result = State.fromString('SP');
      expect(result.isSuccess, isTrue);
      expect(result.getOrThrow(), State.saoPaulo);
    });

    /// deve retornar Success para um nome de estado válido
    test('should return Success for valid state name', () {
      final result = State.fromString('São Paulo');
      expect(result.isSuccess, isTrue);
      expect(result.getOrThrow(), State.saoPaulo);
    });

    /// deve ser insensível a maiúsculas e minúsculas
    test('should be case insensitive', () {
      final result = State.fromString('sp');
      expect(result.isSuccess, isTrue);
      expect(result.getOrThrow(), State.saoPaulo);
    });

    /// deve retornar Failure para um estado inválido
    test('should return Failure for invalid state', () {
      final result = State.fromString('XX');
      expect(result.isFailure, isTrue);
      expect(result.getFailureOrThrow().code, AppErrorCodes.stateInvalid);
    });

    /// deve retornar Failure para entrada vazia
    test('should return Failure for empty input', () {
      final result = State.fromString('');
      expect(result.isFailure, isTrue);
      expect(result.getFailureOrThrow().code, AppErrorCodes.stateInvalid);
    });
  });
}
