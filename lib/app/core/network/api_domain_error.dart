import 'package:ecommerce_b2b/app/core/network/api_exception.dart';
import 'package:ecommerce_b2b/modules/shared_kernel/base/base_domain_errors.dart';

/// Adapta um erro HTTP da API ao contrato de `DomainError` usado pelos casos de uso.
class ApiDomainError extends DomainError {
  final String code;

  ApiDomainError(super.message, {this.code = 'API_ERROR'});

  factory ApiDomainError.fromException(ApiException error) =>
      ApiDomainError(error.message, code: error.code);

  @override
  String toString() => message;
}
