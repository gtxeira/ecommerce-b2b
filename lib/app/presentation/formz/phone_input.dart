import 'package:formz/formz.dart';
import 'package:ecommerce_b2b/modules/shared_kernel/model/contact/value_objects/phone_number.dart';

enum PhoneValidationError { invalid }

class PhoneInput extends FormzInput<String, PhoneValidationError> {
  const PhoneInput.pure() : super.pure('');
  const PhoneInput.dirty([super.value = '']) : super.dirty();

  @override
  PhoneValidationError? validator(String value) {
    if (value.isEmpty) return PhoneValidationError.invalid;
    final result = PhoneNumber.create(value);
    return result.isSuccess ? null : PhoneValidationError.invalid;
  }
}
