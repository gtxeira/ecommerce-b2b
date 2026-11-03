import 'package:ecommerce_b2b/modules/shared_kernel/model/entity.dart';
import 'package:ecommerce_b2b/modules/shared_kernel/model/common/ids/buyer_id.dart';
import 'package:ecommerce_b2b/modules/shared_kernel/model/contact/value_objects/email_address.dart';
import 'package:ecommerce_b2b/modules/shared_kernel/model/contact/value_objects/phone_number.dart';

class AuthorizedBuyer extends Entity<BuyerId> {
  final String fullName;
  final EmailAddress email;
  final PhoneNumber? phone;
  final String positionTitle;
  final bool active;

  const AuthorizedBuyer({
    required BuyerId id,
    required this.fullName,
    required this.email,
    required this.phone,
    required this.positionTitle,
    required this.active,
  }) : super(id);
}
