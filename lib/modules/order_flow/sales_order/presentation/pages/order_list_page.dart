import 'package:ecommerce_b2b/app/core/di/service_locator.dart';
import 'package:ecommerce_b2b/app/core/routes/order_routes.dart';
import 'package:ecommerce_b2b/app/presentation/widgets/b2b_app_bar.dart';
import 'package:ecommerce_b2b/modules/order_flow/model/enums/order_status.dart';
import 'package:ecommerce_b2b/modules/order_flow/sales_order/presentation/cubit/order_list_cubit.dart';
import 'package:ecommerce_b2b/modules/order_flow/sales_order/presentation/widgets/order_search_field.dart';
import 'package:ecommerce_b2b/modules/order_flow/sales_order/presentation/widgets/order_summary_tile.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

/// Listagem de pedidos dividida entre abertos e encerrados, com busca por id,
/// empresa ou nome fantasia. O agrupamento inicial pode vir de
/// `?group=open|closed`.
class OrderListPage extends StatelessWidget {
  const OrderListPage({super.key, this.initialGroup});

  final OrderStatusGroup? initialGroup;

  @override
  Widget build(BuildContext context) {
    final group = initialGroup ?? OrderStatusGroup.open;

    return BlocProvider(
      create: (context) => getIt<OrderListCubit>()
        ..setFilter(group)
        ..load(),
      child: Scaffold(
        appBar: const B2BAppBar(title: 'Pedidos'),
        body: BlocBuilder<OrderListCubit, OrderListState>(
          builder: (context, state) {
            if (state is OrderListLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            if (state is OrderListFailure) {
              return _buildFailure(context, state.message);
            }

            if (state is OrderListLoaded) {
              return _buildLoaded(context, state);
            }

            return const SizedBox.shrink();
          },
        ),
      ),
    );
  }

  Widget _buildFailure(BuildContext context, String message) {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline_rounded,
              size: 56,
              color: theme.colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              'Não foi possível carregar os pedidos',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => context.read<OrderListCubit>().load(),
              child: const Text('Recarregar'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoaded(BuildContext context, OrderListLoaded state) {
    final theme = Theme.of(context);
    final orders = state.visibleOrders;
    final hasQuery = state.query.trim().isNotEmpty;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
          child: OrderSearchField(
            initialValue: state.query,
            onChanged: (value) =>
                context.read<OrderListCubit>().setQuery(value),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: SegmentedButton<OrderStatusGroup>(
              segments: OrderStatusGroup.values
                  .map(
                    (group) => ButtonSegment<OrderStatusGroup>(
                      value: group,
                      label: Text('${group.label} (${state.countFor(group)})'),
                    ),
                  )
                  .toList(),
              selected: {state.filter},
              showSelectedIcon: false,
              onSelectionChanged: (selection) =>
                  context.read<OrderListCubit>().setFilter(selection.first),
            ),
          ),
        ),
        Expanded(
          child: RefreshIndicator(
            onRefresh: () => context.read<OrderListCubit>().load(),
            child: orders.isEmpty
                ? ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(32),
                    children: [
                      const SizedBox(height: 48),
                      Icon(
                        Icons.history_rounded,
                        size: 64,
                        color: theme.colorScheme.outline,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        hasQuery
                            ? 'Nenhum pedido corresponde a "${state.query.trim()}".'
                            : 'Nenhum pedido ${state.filter == OrderStatusGroup.open ? 'em aberto' : 'encerrado'}.',
                        style: theme.textTheme.titleMedium,
                        textAlign: TextAlign.center,
                      ),
                    ],
                  )
                : ListView.builder(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                    itemCount: orders.length,
                    itemBuilder: (context, index) {
                      final order = orders[index];
                      return OrderSummaryTile(
                        order: order,
                        companyName: state.companyNameFor(order),
                        onTap: () => context.push(
                          OrderRoutes.detail(order.id.value),
                          extra: order,
                        ),
                      );
                    },
                  ),
          ),
        ),
      ],
    );
  }
}
