import 'package:ecommerce_b2b/modules/shared_kernel/domain/logistics/errors/weight_errors.dart';
import 'package:ecommerce_b2b/modules/shared_kernel/functional/result.dart';
import 'package:flutter/foundation.dart';

@immutable
class Weight {
  final double value;

  const Weight._(this.value);

  static Result<Weight, WeightError> create(double value) {
    if (value < 0) {
      return Failure(WeightNegativeError());
    }
    return Success(Weight._(value));
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Weight &&
          runtimeType == other.runtimeType &&
          value == other.value;

  @override
  int get hashCode => value.hashCode;

  @override
  String toString() => '${value.toStringAsFixed(2)} kg';
}
