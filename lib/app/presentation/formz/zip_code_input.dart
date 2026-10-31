import 'package:formz/formz.dart';
import 'package:ecommerce_b2b/modules/shared_kernel/model/address/value_objects/zip_code.dart';

enum ZipCodeValidationError { invalid }

class ZipCodeInput extends FormzInput<String, ZipCodeValidationError> {
  const ZipCodeInput.pure() : super.pure('');
  const ZipCodeInput.dirty([super.value = '']) : super.dirty();

  @override
  ZipCodeValidationError? validator(String value) {
    if (value.isEmpty) return ZipCodeValidationError.invalid;
    final result = ZipCode.create(value);
    return result.isSuccess ? null : ZipCodeValidationError.invalid;
  }
}
