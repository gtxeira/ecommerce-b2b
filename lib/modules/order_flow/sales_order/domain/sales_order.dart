import 'package:ecommerce_b2b/modules/shared_kernel/base/base_aggregate_root.dart';
import 'package:ecommerce_b2b/modules/shared_kernel/domain/common/ids/order_id.dart';
import 'package:ecommerce_b2b/modules/shared_kernel/domain/finance/value_objects/money.dart';
import 'package:ecommerce_b2b/modules/order_flow/domain/enums/order_status.dart';
import 'package:ecommerce_b2b/modules/order_flow/domain/enums/credit_status.dart';
import 'package:ecommerce_b2b/modules/order_flow/sales_order/domain/order_item.dart';
import 'package:ecommerce_b2b/modules/order_flow/sales_order/domain/finance_review.dart';

// ignore_for_file: prefer_initializing_formals

/// Raiz do Agregado que representa um Pedido de Venda.
class SalesOrder extends AggregateRoot<OrderId> {
  final String? companyId;
  OrderStatus _status;
  CreditStatus _creditStatus;
  final List<OrderItem> _items;
  FinanceReview? _financeReview;
  final Money _shippingCost;

  /// Construtor do Pedido de Venda.
  SalesOrder({
    required OrderId id,
    this.companyId,
    required OrderStatus status,
    required CreditStatus creditStatus,
    required List<OrderItem> items,
    FinanceReview? financeReview,
    Money? shippingCost,
  }) : _status = status,
       _creditStatus = creditStatus,
       _items = items,
       _financeReview = financeReview,
       _shippingCost = shippingCost ?? Money.create(0).getOrThrow(),
       super(id);

  /// Status atual do pedido (ex: pendente aprovação, em trânsito).
  OrderStatus get status => _status;

  /// Status de crédito do pedido.
  CreditStatus get creditStatus => _creditStatus;

  /// Itens que compõem o pedido.
  List<OrderItem> get items => List.unmodifiable(_items);

  /// Revisão financeira associada ao pedido, se houver.
  FinanceReview? get financeReview => _financeReview;

  /// Frete herdado do orçamento, em reais.
  Money get shippingCost => _shippingCost;

  /// Calcula o valor total do pedido somando os subtotais de cada item e o frete.
  Money get total {
    if (_items.isEmpty) return _shippingCost;

    Money sum = Money.create(
      0,
      currency: _items.first.unitPriceSnapshot.currency,
    ).getOrThrow();
    for (var item in _items) {
      sum = sum + item.subtotal;
    }
    return sum + _shippingCost;
  }

  /// Atualiza o status do pedido.
  void updateStatus(OrderStatus newStatus) {
    _status = newStatus;
  }

  /// Atualiza o status de crédito do pedido.
  void updateCreditStatus(CreditStatus newStatus) {
    _creditStatus = newStatus;
  }

  /// Aplica uma decisão de revisão financeira ao pedido.
  void applyFinanceReview(FinanceReview review) {
    _financeReview = review;
  }
}
