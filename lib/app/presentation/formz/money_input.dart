import 'package:formz/formz.dart';
import 'package:ecommerce_b2b/modules/shared_kernel/model/finance/value_objects/money.dart';

enum MoneyValidationError { invalid }

class MoneyInput extends FormzInput<String, MoneyValidationError> {
  const MoneyInput.pure() : super.pure('');
  const MoneyInput.dirty([super.value = '']) : super.dirty();

  @override
  MoneyValidationError? validator(String value) {
    if (value.isEmpty) return MoneyValidationError.invalid;
    final cleanValue = value.replaceAll(RegExp(r'[^\d.]'), '');
    final amount = double.tryParse(cleanValue);
    if (amount == null) return MoneyValidationError.invalid;
    final result = Money.create(amount);
    return result.isSuccess ? null : MoneyValidationError.invalid;
  }
}
