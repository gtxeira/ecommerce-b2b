import 'package:ecommerce_b2b/app/core/errors/app_error.dart';
import 'package:ecommerce_b2b/app/core/result/result.dart';
import 'package:flutter/foundation.dart';

@immutable
class TrackingCode {
  final String value;

  const TrackingCode._(this.value);

  static Result<TrackingCode, AppError> create(String value) {
    if (value.isEmpty) {
      return Failure(
        const AppError(
          AppErrorCodes.trackingCodeInvalid,
          'Código de rastreamento não pode ser vazio',
          field: 'trackingCode',
        ),
      );
    }
    return Success(TrackingCode._(value));
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TrackingCode &&
          runtimeType == other.runtimeType &&
          value == other.value;

  @override
  int get hashCode => value.hashCode;

  @override
  String toString() => value;
}
