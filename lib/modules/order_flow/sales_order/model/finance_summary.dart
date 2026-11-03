import 'package:ecommerce_b2b/app/core/network/json_read.dart';
import 'package:ecommerce_b2b/modules/shared_kernel/model/finance/value_objects/money.dart';
import 'package:equatable/equatable.dart';

/// Indicadores agregados da carteira exibidos no painel financeiro.
///
/// A API é a dona da regra: o app só apresenta os valores. O detalhamento por
/// empresa continua em `GET /api/companies`.
class FinanceSummary extends Equatable {
  /// Quantidade de empresas no escopo da sessão.
  final int companyCount;

  /// Soma dos limites pré-aprovados.
  final Money totalCreditLimit;

  /// Soma do saldo devedor registrado.
  final Money totalOpenBalance;

  /// Soma dos pedidos em aberto ainda não faturados.
  final Money totalPendingOrdersBalance;

  /// Saldo devedor mais pedidos em aberto.
  final Money totalExposure;

  /// Limite ainda disponível somado entre as empresas.
  final Money availableLimit;

  /// Percentual da carteira comprometido (0 a 100, ou mais em caso de estouro).
  final double utilizationPercentage;

  /// Empresas com 80% ou mais do limite comprometido.
  final int companiesAtRisk;

  /// Empresas com 100% ou mais do limite comprometido.
  final int companiesOverLimit;

  const FinanceSummary({
    required this.companyCount,
    required this.totalCreditLimit,
    required this.totalOpenBalance,
    required this.totalPendingOrdersBalance,
    required this.totalExposure,
    required this.availableLimit,
    required this.utilizationPercentage,
    required this.companiesAtRisk,
    required this.companiesOverLimit,
  });

  factory FinanceSummary.fromJson(Map<String, dynamic> json) {
    Money money(String key) => Money.create(readDouble(json, key)).getOrThrow();

    return FinanceSummary(
      companyCount: readInt(json, 'companyCount'),
      totalCreditLimit: money('totalCreditLimit'),
      totalOpenBalance: money('totalOpenBalance'),
      totalPendingOrdersBalance: money('totalPendingOrdersBalance'),
      totalExposure: money('totalExposure'),
      availableLimit: money('availableLimit'),
      utilizationPercentage: readDouble(json, 'utilizationPercentage'),
      companiesAtRisk: readInt(json, 'companiesAtRisk'),
      companiesOverLimit: readInt(json, 'companiesOverLimit'),
    );
  }

  /// Percentual no formato brasileiro, com uma casa decimal.
  String get utilizationLabel =>
      '${utilizationPercentage.toStringAsFixed(1).replaceAll('.', ',')}%';

  bool get hasCompanies => companyCount > 0;

  @override
  List<Object?> get props => [
    companyCount,
    totalCreditLimit,
    totalOpenBalance,
    totalPendingOrdersBalance,
    totalExposure,
    availableLimit,
    utilizationPercentage,
    companiesAtRisk,
    companiesOverLimit,
  ];
}
