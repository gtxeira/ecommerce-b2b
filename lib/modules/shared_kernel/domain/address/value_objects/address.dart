import 'package:ecommerce_b2b/modules/shared_kernel/base/base_domain_errors.dart';
import 'package:ecommerce_b2b/modules/shared_kernel/domain/address/enums/state.dart';
import 'package:ecommerce_b2b/modules/shared_kernel/functional/result.dart';
import 'package:ecommerce_b2b/modules/shared_kernel/domain/address/value_objects/address_complement.dart';
import 'package:ecommerce_b2b/modules/shared_kernel/domain/address/value_objects/address_number.dart';
import 'package:ecommerce_b2b/modules/shared_kernel/domain/address/value_objects/city.dart';
import 'package:ecommerce_b2b/modules/shared_kernel/domain/address/value_objects/neighborhood.dart';
import 'package:ecommerce_b2b/modules/shared_kernel/domain/address/value_objects/street.dart';
import 'package:ecommerce_b2b/modules/shared_kernel/domain/address/value_objects/zip_code.dart';
import 'package:flutter/foundation.dart';

/// Objeto de Valor que representa um endereço válido.
@immutable
class Address {
  final Street street;
  final AddressNumber number;
  final AddressComplement? complement;
  final Neighborhood neighborhood;
  final City city;
  final State state;
  final ZipCode zipCode;

  const Address._({
    required this.street,
    required this.number,
    required this.complement,
    required this.neighborhood,
    required this.city,
    required this.state,
    required this.zipCode,
  });

  static Result<Address, DomainError> create({
    required String street,
    required String number,
    String? complement,
    required String neighborhood,
    required String city,
    required String state,
    required String zipCode,
  }) {
    final streetResult = Street.create(street);
    final numberResult = AddressNumber.create(number);
    final cityResult = City.create(city);
    final stateResult = State.fromString(state);
    final zipResult = ZipCode.create(zipCode);
    final neighborhoodResult = Neighborhood.create(neighborhood);

    if (streetResult.isFailure) {
      return Failure(streetResult.getFailureOrThrow());
    }

    if (numberResult.isFailure) {
      return Failure(numberResult.getFailureOrThrow());
    }

    if (cityResult.isFailure) {
      return Failure(cityResult.getFailureOrThrow());
    }

    if (stateResult.isFailure) {
      return Failure(stateResult.getFailureOrThrow());
    }

    if (zipResult.isFailure) {
      return Failure(zipResult.getFailureOrThrow());
    }

    if (neighborhoodResult.isFailure) {
      return Failure(neighborhoodResult.getFailureOrThrow());
    }

    final Result<AddressComplement?, DomainError> complementResult =
        complement == null || complement.trim().isEmpty
        ? Success<AddressComplement?, DomainError>(null)
        : AddressComplement.create(complement);

    if (complementResult.isFailure) {
      return Failure(complementResult.getFailureOrThrow());
    }

    return Success(
      Address._(
        street: streetResult.getOrThrow(),
        number: numberResult.getOrThrow(),
        complement: complementResult.getOrThrow(),
        neighborhood: neighborhoodResult.getOrThrow(),
        city: cityResult.getOrThrow(),
        state: stateResult.getOrThrow(),
        zipCode: zipResult.getOrThrow(),
      ),
    );
  }

  bool get hasComplement => complement != null;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Address &&
          runtimeType == other.runtimeType &&
          street == other.street &&
          number == other.number &&
          complement == other.complement &&
          neighborhood == other.neighborhood &&
          city == other.city &&
          state == other.state &&
          zipCode == other.zipCode;

  @override
  int get hashCode =>
      street.hashCode ^
      number.hashCode ^
      complement.hashCode ^
      neighborhood.hashCode ^
      city.hashCode ^
      state.hashCode ^
      zipCode.hashCode;
}
