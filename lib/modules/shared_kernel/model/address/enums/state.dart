import 'package:ecommerce_b2b/app/core/errors/app_error.dart';
import 'package:ecommerce_b2b/app/core/result/result.dart';

/// Enum que representa as Unidades Federativas (UF) do Brasil.
enum State {
  acre(name: 'Acre', code: 'AC'),
  alagoas(name: 'Alagoas', code: 'AL'),
  amazonas(name: 'Amazonas', code: 'AM'),
  amapa(name: 'Amapá', code: 'AP'),
  bahia(name: 'Bahia', code: 'BA'),
  ceara(name: 'Ceará', code: 'CE'),
  distritoFederal(name: 'Distrito Federal', code: 'DF'),
  espiritoSanto(name: 'Espírito Santo', code: 'ES'),
  goias(name: 'Goiás', code: 'GO'),
  maranhao(name: 'Maranhão', code: 'MA'),
  minasGerais(name: 'Minas Gerais', code: 'MG'),
  matoGrossoSul(name: 'Mato Grosso do Sul', code: 'MS'),
  matoGrosso(name: 'Mato Grosso', code: 'MT'),
  para(name: 'Pará', code: 'PA'),
  paraiba(name: 'Paraíba', code: 'PB'),
  pernambuco(name: 'Pernambuco', code: 'PE'),
  piaui(name: 'Piauí', code: 'PI'),
  parana(name: 'Paraná', code: 'PR'),
  rioDeJaneiro(name: 'Rio de Janeiro', code: 'RJ'),
  rioGrandeDoNorte(name: 'Rio Grande do Norte', code: 'RN'),
  rondonia(name: 'Rondônia', code: 'RO'),
  roraima(name: 'Roraima', code: 'RR'),
  rioGrandeDoSul(name: 'Rio Grande do Sul', code: 'RS'),
  santaCatarina(name: 'Santa Catarina', code: 'SC'),
  sergipe(name: 'Sergipe', code: 'SE'),
  saoPaulo(name: 'São Paulo', code: 'SP'),
  tocantins(name: 'Tocantins', code: 'TO');

  /// Nome do estado (ex: São Paulo)
  final String name;

  /// Código do estado (ex: SP)
  final String code;

  const State({required this.name, required this.code});

  /// Função utilitária (Factory) para criar o Enum a partir de uma String não tratada
  static Result<State, AppError> fromString(String input) {
    final cleanInput = input.trim().toLowerCase();

    if (cleanInput.isEmpty) {
      return Failure(
        const AppError(
          AppErrorCodes.stateInvalid,
          'O estado é inválido.',
          field: 'state',
        ),
      );
    }

    for (final state in State.values) {
      if (state.code.toLowerCase() == cleanInput ||
          state.name.toLowerCase() == cleanInput) {
        return Success(state);
      }
    }

    return Failure(
      const AppError(
        AppErrorCodes.stateInvalid,
        'O estado é inválido.',
        field: 'state',
      ),
    );
  }

  /// Converte o nome do enum devolvido pela API C# (ex.: `SaoPaulo`).
  ///
  /// O nome de exibição deste enum é acentuado ("São Paulo"), então não serve
  /// para o contrato HTTP; o identificador do enum é a ponte.
  static Result<State, AppError> fromApiName(String input) {
    final cleanInput = input.trim().toLowerCase();
    if (cleanInput.isEmpty) {
      return Failure(
        const AppError(
          AppErrorCodes.stateInvalid,
          'O estado é inválido.',
          field: 'state',
        ),
      );
    }

    for (final state in State.values) {
      if (state.apiName.toLowerCase() == cleanInput ||
          state.code.toLowerCase() == cleanInput) {
        return Success(state);
      }
    }

    return Failure(
      const AppError(
        AppErrorCodes.stateInvalid,
        'O estado é inválido.',
        field: 'state',
      ),
    );
  }

  /// Nome esperado pela API (identificador do enum em C#).
  String get apiName => toString().split('.').last;
}
