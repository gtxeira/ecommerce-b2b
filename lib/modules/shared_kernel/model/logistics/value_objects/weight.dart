import 'package:ecommerce_b2b/app/core/errors/app_error.dart';
import 'package:ecommerce_b2b/app/core/result/result.dart';
import 'package:flutter/foundation.dart';

@immutable
class Weight {
  final double value;

  const Weight._(this.value);

  static Result<Weight, AppError> create(double value) {
    if (value < 0) {
      return Failure(
        const AppError(
          AppErrorCodes.weightNegative,
          'O peso não pode ser negativo.',
        ),
      );
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
