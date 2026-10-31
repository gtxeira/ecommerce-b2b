import 'package:formz/formz.dart';

enum NotEmptyValidationError { empty }

class NotEmptyInput extends FormzInput<String, NotEmptyValidationError> {
  const NotEmptyInput.pure() : super.pure('');
  const NotEmptyInput.dirty([super.value = '']) : super.dirty();

  @override
  NotEmptyValidationError? validator(String value) {
    return value.trim().isNotEmpty ? null : NotEmptyValidationError.empty;
  }
}
