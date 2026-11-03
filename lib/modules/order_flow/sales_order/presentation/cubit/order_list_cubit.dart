import 'dart:async';

import 'package:ecommerce_b2b/modules/customer_management/company/model/repositories/company_repository.dart';
import 'package:ecommerce_b2b/modules/order_flow/model/enums/order_status.dart';
import 'package:ecommerce_b2b/modules/order_flow/sales_order/model/repositories/sales_order_repository.dart';
import 'package:ecommerce_b2b/modules/order_flow/sales_order/model/sales_order.dart';
import 'package:ecommerce_b2b/modules/order_flow/sales_order/model/sales_order_sort.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

part 'order_list_state.dart';

/// Lista de pedidos separada por situação (abertos x encerrados), com busca
/// local por id, empresa ou nome fantasia.
///
/// A API só aceita um `status` por consulta e não tem parâmetro de busca, então
/// a carga é feita uma única vez com `getAll()` (já escopada por papel no
/// backend) e o recorte é local. Os nomes das empresas vêm de `GET
/// /api/companies`, que também é escopado por papel.
class OrderListCubit extends Cubit<OrderListState> {
  final SalesOrderRepository _orderRepository;
  final CompanyRepository _companyRepository;

  OrderStatusGroup _filter;

  OrderListCubit(
    this._orderRepository,
    this._companyRepository, {
    OrderStatusGroup initialFilter = OrderStatusGroup.open,
  }) : _filter = initialFilter,
       super(OrderListInitial());

  Future<void> load() async {
    emit(OrderListLoading());
    try {
      final (orders, companyNames) = await (
        _orderRepository.getAll(),
        _loadCompanyNames(),
      ).wait;

      emit(
        OrderListLoaded(
          allOrders: orders,
          companyNames: companyNames,
          filter: _filter,
          query: _query,
        ),
      );
    } catch (e) {
      emit(OrderListFailure(e.toString()));
    }
  }

  void setFilter(OrderStatusGroup group) {
    _filter = group;
    _emitCurrentFilters();
  }

  void setQuery(String query) {
    _query = query;
    _emitCurrentFilters();
  }

  String _query = '';

  void _emitCurrentFilters() {
    final current = state;
    if (current is OrderListLoaded) {
      emit(
        OrderListLoaded(
          allOrders: current.allOrders,
          companyNames: current.companyNames,
          filter: _filter,
          query: _query,
        ),
      );
    }
  }

  /// Nomes fantasia por `companyId`. Falha aqui não derruba a lista: a busca
  /// continua funcionando por id/companyId.
  Future<Map<String, String>> _loadCompanyNames() async {
    try {
      final companies = await _companyRepository.findAll();
      return {
        for (final company in companies)
          company.id.value: company.tradeName.isNotEmpty
              ? company.tradeName
              : company.legalName,
      };
    } catch (_) {
      return const {};
    }
  }
}
