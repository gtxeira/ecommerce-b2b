import 'package:ecommerce_b2b/app/core/errors/app_error.dart';
import 'package:ecommerce_b2b/modules/shared_kernel/domain/address/value_objects/address_complement.dart';
import 'package:ecommerce_b2b/modules/shared_kernel/domain/address/value_objects/address_number.dart';
import 'package:ecommerce_b2b/modules/shared_kernel/domain/address/value_objects/city.dart';
import 'package:ecommerce_b2b/modules/shared_kernel/domain/address/value_objects/neighborhood.dart';
import 'package:ecommerce_b2b/modules/shared_kernel/domain/address/value_objects/street.dart';
import 'package:ecommerce_b2b/modules/shared_kernel/domain/address/value_objects/zip_code.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Street', () {
    /// deve criar uma rua válida
    test('should create valid street', () {
      final result = Street.create('Rua das Flores');
      expect(result.isSuccess, isTrue);
      expect(result.getOrThrow().value, 'Rua das Flores');
    });

    /// deve retornar erro para rua vazia
    test('should return error for empty street', () {
      final result = Street.create('  ');
      expect(result.isFailure, isTrue);
      expect(result.getFailureOrThrow().code, AppErrorCodes.streetEmpty);
    });

    /// deve retornar erro para rua muito longa
    test('should return error for too long street', () {
      final result = Street.create('a' * 101);
      expect(result.isFailure, isTrue);
      expect(result.getFailureOrThrow().code, AppErrorCodes.streetTooLong);
    });
  });

  group('AddressNumber', () {
    /// deve criar um número de endereço válido
    test('should create valid number', () {
      final result = AddressNumber.create('123 A');
      expect(result.isSuccess, isTrue);
      expect(result.getOrThrow().value, '123 A');
    });

    /// deve retornar erro para número vazio
    test('should return error for empty number', () {
      final result = AddressNumber.create('');
      expect(result.isFailure, isTrue);
      expect(result.getFailureOrThrow().code, AppErrorCodes.addressNumberEmpty);
    });

    /// deve retornar erro para número muito longo
    test('should return error for too long number', () {
      final result = AddressNumber.create('a' * 11);
      expect(result.isFailure, isTrue);
      expect(
        result.getFailureOrThrow().code,
        AppErrorCodes.addressNumberTooLong,
      );
    });
  });

  group('AddressComplement', () {
    /// deve criar um complemento válido
    test('should create valid complement', () {
      final result = AddressComplement.create('Apto 101');
      expect(result.isSuccess, isTrue);
      expect(result.getOrThrow().value, 'Apto 101');
    });

    /// deve retornar erro para complemento vazio
    test('should return error for empty complement', () {
      final result = AddressComplement.create('');
      expect(result.isFailure, isTrue);
      expect(
        result.getFailureOrThrow().code,
        AppErrorCodes.addressComplementEmpty,
      );
    });

    /// deve retornar erro para complemento muito longo
    test('should return error for too long complement', () {
      final result = AddressComplement.create('a' * 61);
      expect(result.isFailure, isTrue);
      expect(
        result.getFailureOrThrow().code,
        AppErrorCodes.addressComplementTooLong,
      );
    });
  });

  group('City', () {
    /// deve criar uma cidade válida
    test('should create valid city', () {
      final result = City.create('São Paulo');
      expect(result.isSuccess, isTrue);
      expect(result.getOrThrow().value, 'São Paulo');
    });

    /// deve retornar erro para cidade vazia
    test('should return error for empty city', () {
      final result = City.create('');
      expect(result.isFailure, isTrue);
      expect(result.getFailureOrThrow().code, AppErrorCodes.cityEmpty);
    });

    /// deve retornar erro para cidade muito longa
    test('should return error for too long city', () {
      final result = City.create('a' * 101);
      expect(result.isFailure, isTrue);
      expect(result.getFailureOrThrow().code, AppErrorCodes.cityTooLong);
    });
  });

  group('Neighborhood', () {
    /// deve criar um bairro válido
    test('should create valid neighborhood', () {
      final result = Neighborhood.create('Centro');
      expect(result.isSuccess, isTrue);
      expect(result.getOrThrow().value, 'Centro');
    });

    /// deve retornar erro para bairro vazio
    test('should return error for empty neighborhood', () {
      final result = Neighborhood.create('');
      expect(result.isFailure, isTrue);
      expect(result.getFailureOrThrow().code, AppErrorCodes.neighborhoodEmpty);
    });

    /// deve retornar erro para bairro muito longo
    test('should return error for too long neighborhood', () {
      final result = Neighborhood.create('a' * 71);
      expect(result.isFailure, isTrue);
      expect(
        result.getFailureOrThrow().code,
        AppErrorCodes.neighborhoodTooLong,
      );
    });
  });

  group('ZipCode', () {
    /// deve criar um código postal (CEP) válido
    test('should create valid zip code', () {
      final result = ZipCode.create('01234-567');
      expect(result.isSuccess, isTrue);
      expect(result.getOrThrow().value, '01234567');
      expect(result.getOrThrow().formatted, '01234-567');
    });

    /// deve retornar erro para comprimento de CEP inválido
    test('should return error for invalid zip code length', () {
      final result = ZipCode.create('12345');
      expect(result.isFailure, isTrue);
      expect(result.getFailureOrThrow().code, AppErrorCodes.zipCodeLength);
    });

    /// deve retornar erro para CEP vazio
    test('should return error for empty zip code', () {
      final result = ZipCode.create('');
      expect(result.isFailure, isTrue);
      expect(result.getFailureOrThrow().code, AppErrorCodes.zipCodeEmpty);
    });
  });
}
