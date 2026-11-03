/// Formatação de datas para a UI.
///
/// A API expõe as datas em **UTC**; a conversão para o fuso local acontece aqui,
/// no último momento, para que o horário exibido seja o do usuário. O formato é
/// feito à mão (como o `Money.formatted`) para não adicionar o pacote `intl` por
/// um único formato.
String formatDate(DateTime value) {
  final local = value.toLocal();
  return '${_twoDigits(local.day)}/${_twoDigits(local.month)}/${local.year}';
}

/// Data e hora no formato `dd/MM/yyyy HH:mm`.
String formatDateTime(DateTime value) {
  final local = value.toLocal();
  return '${formatDate(value)} ${_twoDigits(local.hour)}:${_twoDigits(local.minute)}';
}

/// [formatDate] tolerante a ausência do campo no contrato.
String formatDateOrDash(DateTime? value) =>
    value == null ? '-' : formatDate(value);

/// [formatDateTime] tolerante a ausência do campo no contrato.
String formatDateTimeOrDash(DateTime? value) =>
    value == null ? '-' : formatDateTime(value);

String _twoDigits(int value) => value.toString().padLeft(2, '0');
