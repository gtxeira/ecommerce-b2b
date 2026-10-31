/// Leitura defensiva de JSON da API (camelCase).
///
/// A API garante os campos, mas tolerar nulos evita que um campo novo/ausente
/// derrube a tela inteira com um cast.
String readString(
  Map<String, dynamic> json,
  String key, [
  String fallback = '',
]) {
  final value = json[key];
  return value is String ? value : fallback;
}

String? readNullableString(Map<String, dynamic> json, String key) {
  final value = json[key];
  return value is String && value.isNotEmpty ? value : null;
}

double readDouble(
  Map<String, dynamic> json,
  String key, [
  double fallback = 0,
]) {
  final value = json[key];
  if (value is num) return value.toDouble();
  return fallback;
}

double? readNullableDouble(Map<String, dynamic> json, String key) {
  final value = json[key];
  return value is num ? value.toDouble() : null;
}

int readInt(Map<String, dynamic> json, String key, [int fallback = 0]) {
  final value = json[key];
  if (value is int) return value;
  if (value is num) return value.toInt();
  return fallback;
}

bool readBool(Map<String, dynamic> json, String key, [bool fallback = false]) {
  final value = json[key];
  return value is bool ? value : fallback;
}

List<Map<String, dynamic>> readMapList(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value is! List) return const [];
  return value
      .whereType<Map>()
      .map((item) => Map<String, dynamic>.from(item))
      .toList();
}

Map<String, dynamic> readMap(Map<String, dynamic> json, String key) {
  final value = json[key];
  return value is Map ? Map<String, dynamic>.from(value) : <String, dynamic>{};
}

DateTime? readDate(Map<String, dynamic> json, String key) {
  final value = json[key];
  return value is String ? DateTime.tryParse(value) : null;
}
