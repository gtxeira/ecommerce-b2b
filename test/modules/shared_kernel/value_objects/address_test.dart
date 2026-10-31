import 'package:ecommerce_b2b/app/core/errors/app_error.dart';
import 'package:ecommerce_b2b/modules/shared_kernel/domain/address/enums/state.dart';
import 'package:ecommerce_b2b/modules/shared_kernel/domain/address/value_objects/address.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Address', () {
    /// deve criar um endereço válido sem complemento
    test('should create valid address without complement', () {
      final result = Address.create(
        street: 'Rua A',
        number: '123',
        neighborhood: 'Centro',
        city: 'São Paulo',
        state: 'SP',
        zipCode: '01001-000',
      );
      expect(result.isSuccess, isTrue);
      final address = result.getOrThrow();
      expect(address.street.value, 'Rua A');
      expect(address.number.value, '123');
      expect(address.complement, isNull);
      expect(address.neighborhood.value, 'Centro');
      expect(address.city.value, 'São Paulo');
      expect(address.state, State.saoPaulo);
      expect(address.zipCode.value, '01001000');
    });

    /// deve criar um endereço válido com complemento
    test('should create valid address with complement', () {
      final result = Address.create(
        street: 'Rua A',
        number: '123',
        complement: 'Apto 101',
        neighborhood: 'Centro',
        city: 'São Paulo',
        state: 'SP',
        zipCode: '01001-000',
      );
      expect(result.isSuccess, isTrue);
      final address = result.getOrThrow();
      expect(address.complement?.value, 'Apto 101');
    });

    /// deve criar um endereço válido com complemento vazio
    test('should create valid address with empty complement', () {
      final result = Address.create(
        street: 'Rua A',
        number: '123',
        complement: '',
        neighborhood: 'Centro',
        city: 'São Paulo',
        state: 'SP',
        zipCode: '01001-000',
      );

      expect(result.isSuccess, isTrue);
      final address = result.getOrThrow();
      expect(address.complement, isNull);
    });

    /// deve retornar erro para estado inválido
    test('should return error for invalid state', () {
      final result = Address.create(
        street: 'Rua A',
        number: '123',
        neighborhood: 'Centro',
        city: 'São Paulo',
        state: 'XX',
        zipCode: '01001-000',
      );
      expect(result.isFailure, isTrue);
      expect(result.getFailureOrThrow().code, AppErrorCodes.stateInvalid);
    });

    /// deve retornar erro para rua ausente
    test('should return error for missing street', () {
      final result = Address.create(
        street: '',
        number: '123',
        neighborhood: 'Centro',
        city: 'São Paulo',
        state: 'SP',
        zipCode: '01001-000',
      );
      expect(result.isFailure, isTrue);
      expect(result.getFailureOrThrow().code, AppErrorCodes.streetEmpty);
    });

    /// deve retornar erro para código postal inválido
    test('should return error for invalid zip code', () {
      final result = Address.create(
        street: 'Rua A',
        number: '123',
        neighborhood: 'Centro',
        city: 'São Paulo',
        state: 'SP',
        zipCode: '123',
      );
      expect(result.isFailure, isTrue);
      expect(result.getFailureOrThrow().code, AppErrorCodes.zipCodeLength);
    });

    /// deve retornar erro para bairro vazio
    test('should return error for empty neighborhood', () {
      final result = Address.create(
        street: 'Rua A',
        number: '123',
        neighborhood: '',
        city: 'São Paulo',
        state: 'SP',
        zipCode: '01001-000',
      );
      expect(result.isFailure, isTrue);
      expect(result.getFailureOrThrow().code, AppErrorCodes.neighborhoodEmpty);
    });

    /// deve retornar erro para cidade vazia
    test('should return error for empty city', () {
      final result = Address.create(
        street: 'Rua A',
        number: '123',
        neighborhood: 'Centro',
        city: '',
        state: 'SP',
        zipCode: '01001-000',
      );
      expect(result.isFailure, isTrue);
      expect(result.getFailureOrThrow().code, AppErrorCodes.cityEmpty);
    });

    /// deve retornar erro para número vazio
    test('should return error for empty number', () {
      final result = Address.create(
        street: 'Rua A',
        number: '',
        neighborhood: 'Centro',
        city: 'São Paulo',
        state: 'SP',
        zipCode: '01001-000',
      );
      expect(result.isFailure, isTrue);
      expect(result.getFailureOrThrow().code, AppErrorCodes.addressNumberEmpty);
    });

    /// deve retornar erro para rua muito longa
    test('should return error for too long street', () {
      final result = Address.create(
        street: 'a' * 101,
        number: '123',
        neighborhood: 'Centro',
        city: 'São Paulo',
        state: 'SP',
        zipCode: '01001-000',
      );
      expect(result.isFailure, isTrue);
      expect(result.getFailureOrThrow().code, AppErrorCodes.streetTooLong);
    });

    /// deve retornar erro para complemento muito longo
    test('should return error for too long complement', () {
      final result = Address.create(
        street: 'Rua A',
        number: '123',
        complement: 'a' * 61,
        neighborhood: 'Centro',
        city: 'São Paulo',
        state: 'SP',
        zipCode: '01001-000',
      );
      expect(result.isFailure, isTrue);
      expect(
        result.getFailureOrThrow().code,
        AppErrorCodes.addressComplementTooLong,
      );
    });
  });
}
