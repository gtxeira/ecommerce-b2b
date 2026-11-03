import 'package:flutter/foundation.dart';

@immutable
class ShippingLabel {
  final String labelNumber;

  const ShippingLabel(this.labelNumber);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ShippingLabel &&
          runtimeType == other.runtimeType &&
          labelNumber == other.labelNumber;

  @override
  int get hashCode => labelNumber.hashCode;
}
