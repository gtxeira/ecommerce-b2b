import 'package:ecommerce_b2b/modules/sales_team/sales_representative/model/enums/commission_status.dart';
import 'package:ecommerce_b2b/modules/shared_kernel/model/finance/value_objects/money.dart';
import 'package:ecommerce_b2b/modules/shared_kernel/model/finance/value_objects/percentage.dart';
import 'package:flutter/foundation.dart';

@immutable
class Commission {
  /// Identificador de persistência, usado para alterar o status.
  /// Zero em comissões construídas localmente (fixtures/testes).
  final int id;

  final Money baseAmount;
  final Percentage rate;
  final Money amount;
  final CommissionStatus status;

  /// Pedido que originou a comissão (nulo nas comissões históricas do seed).
  final String? orderId;

  /// Momento em que a comissão foi gerada, em UTC. Nulo em payloads antigos.
  final DateTime? createdAt;

  /// Representante que recebeu a comissão. Preenchido pela API no modo pessoal e
  /// no consolidado da equipe.
  final String? representativeId;
  final String? representativeName;

  const Commission({
    this.id = 0,
    required this.baseAmount,
    required this.rate,
    required this.amount,
    required this.status,
    this.orderId,
    this.createdAt,
    this.representativeId,
    this.representativeName,
  });

  /// Uma comissão com status terminal não aceita nova transição.
  bool get canChangeStatus => id > 0 && status == CommissionStatus.pending;

  Commission copyWithStatus(CommissionStatus newStatus) => Commission(
    id: id,
    baseAmount: baseAmount,
    rate: rate,
    amount: amount,
    status: newStatus,
    orderId: orderId,
    createdAt: createdAt,
    representativeId: representativeId,
    representativeName: representativeName,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Commission &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          baseAmount == other.baseAmount &&
          rate == other.rate &&
          amount == other.amount &&
          status == other.status &&
          orderId == other.orderId &&
          createdAt == other.createdAt &&
          representativeId == other.representativeId &&
          representativeName == other.representativeName;

  @override
  int get hashCode =>
      id.hashCode ^
      baseAmount.hashCode ^
      rate.hashCode ^
      amount.hashCode ^
      status.hashCode ^
      orderId.hashCode ^
      createdAt.hashCode ^
      representativeId.hashCode ^
      representativeName.hashCode;
}
