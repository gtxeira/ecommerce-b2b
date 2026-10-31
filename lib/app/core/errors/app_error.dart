/// Erro único do cliente.
///
/// O [code] é o contrato estável e usa o mesmo vocabulário da API C#; a
/// [message] serve para exibição e pode mudar. Quando o erro vem de um
/// formulário, [field] aponta o campo que falhou.
class AppError {
  final String code;
  final String message;
  final String? field;

  const AppError(this.code, this.message, {this.field});

  @override
  String toString() => message;

  @override
  bool operator ==(Object other) =>
      other is AppError &&
      other.code == code &&
      other.message == message &&
      other.field == field;

  @override
  int get hashCode => Object.hash(code, message, field);
}

/// Códigos estáveis de erro. Os que existem na API usam exatamente o mesmo
/// valor do catálogo de `ApiErrorCatalog`; os exclusivos do cliente estão
/// marcados como tal.
abstract final class AppErrorCodes {
  // CNPJ
  static const cnpjEmpty = 'CNPJ_EMPTY';
  static const cnpjInvalid = 'CNPJ_INVALID';
  static const cnpjInvalidLength = 'CNPJ_INVALID_LENGTH';
  static const cnpjInvalidVerificationDigits =
      'CNPJ_INVALID_VERIFICATION_DIGITS';

  // Inscrição estadual
  static const inscricaoEstadualEmpty = 'INSCRICAO_ESTATAL_EMPTY';
  static const inscricaoEstadualInvalid = 'INSCRICAO_ESTATAL_INVALID';

  // Contato
  static const emailEmpty = 'EMAIL_EMPTY';
  static const emailInvalid = 'EMAIL_INVALID';
  static const phoneNumberEmpty = 'PHONE_NUMBER_EMPTY';
  static const phoneNumberInvalid = 'PHONE_NUMBER_INVALID';

  // Endereço
  static const streetEmpty = 'STREET_EMPTY';
  static const streetTooLong = 'STREET_TOO_LONG';
  static const addressNumberEmpty = 'ADDRESS_NUMBER_EMPTY';
  static const addressNumberTooLong = 'ADDRESS_NUMBER_TOO_LONG';
  static const addressComplementEmpty = 'ADDRESS_COMPLEMENT_EMPTY'; // cliente
  static const addressComplementTooLong = 'ADDRESS_COMPLEMENT_TOO_LONG';
  static const neighborhoodEmpty = 'NEIGHBORHOOD_EMPTY';
  static const neighborhoodTooLong = 'NEIGHBORHOOD_TOO_LONG';
  static const cityEmpty = 'CITY_EMPTY';
  static const cityTooLong = 'CITY_TOO_LONG';
  static const zipCodeEmpty = 'ZIP_CODE_EMPTY';
  static const zipCodeLength = 'ZIP_CODE_LENGTH';
  static const stateInvalid = 'STATE_INVALID';

  // Financeiro / logística
  static const moneyNegative = 'MONEY_NEGATIVE';
  static const moneyCurrencyMismatch = 'MONEY_CURRENCY_MISMATCH'; // cliente
  static const quantityNegative = 'QUANTITY_NEGATIVE';
  static const percentageOutOfRange = 'PERCENTAGE_OUT_OF_RANGE'; // cliente
  static const weightNegative = 'WEIGHT_NEGATIVE';
  static const trackingCodeInvalid = 'TRACKING_CODE_INVALID';

  // Sessão / casos de uso
  static const invalidCredentials = 'INVALID_CREDENTIALS';
  static const sessionExpired = 'SESSION_EXPIRED';
  static const unauthorized = 'UNAUTHORIZED';
  static const forbidden = 'FORBIDDEN';
  static const companyNotFound = 'COMPANY_NOT_FOUND';
  static const apiError = 'API_ERROR';
  static const networkError = 'NETWORK_ERROR';
}
