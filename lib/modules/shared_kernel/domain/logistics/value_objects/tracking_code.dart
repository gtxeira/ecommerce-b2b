import 'package:ecommerce_b2b/modules/shared_kernel/functional/result.dart';
import 'package:flutter/foundation.dart';

@immutable
class TrackingCode {
  final String value;

  const TrackingCode._(this.value);

  static Result<TrackingCode, String> create(String value) {
    if (value.isEmpty) {
      return Failure('Código de rastreamento não pode ser vazio');
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
