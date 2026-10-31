import 'package:flutter/foundation.dart';

@immutable
class BoletoCopy {
  final String barcode;
  final String url;

  const BoletoCopy({
    required this.barcode,
    required this.url,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BoletoCopy &&
          runtimeType == other.runtimeType &&
          barcode == other.barcode &&
          url == other.url;

  @override
  int get hashCode => barcode.hashCode ^ url.hashCode;
}
