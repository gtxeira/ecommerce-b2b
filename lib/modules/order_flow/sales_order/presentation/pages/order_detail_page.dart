import 'package:ecommerce_b2b/app/core/di/service_locator.dart';
import 'package:ecommerce_b2b/app/core/routes/app_pages.dart';
import 'package:ecommerce_b2b/app/presentation/widgets/b2b_app_bar.dart';
import 'package:ecommerce_b2b/modules/order_flow/model/enums/order_status.dart';
import 'package:ecommerce_b2b/modules/order_flow/sales_order/model/repositories/sales_order_repository.dart';
import 'package:ecommerce_b2b/modules/order_flow/sales_order/model/sales_order.dart';
import 'package:ecommerce_b2b/modules/order_flow/sales_order/presentation/widgets/order_details_content.dart';
import 'package:ecommerce_b2b/modules/shared_kernel/model/common/ids/order_id.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Detalhe de um pedido. Recebe o pedido já carregado por `extra` quando
/// disponível (render imediato) e busca a versão atual na API em seguida.
class OrderDetailPage extends StatefulWidget {
  const OrderDetailPage({super.key, required this.orderId, this.initialOrder});

  final String orderId;
  final SalesOrder? initialOrder;

  @override
  State<OrderDetailPage> createState() => _OrderDetailPageState();
}

class _OrderDetailPageState extends State<OrderDetailPage> {
  SalesOrder? _order;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _order = widget.initialOrder;
    _loading = _order == null;
    _load();
  }

  Future<void> _load() async {
    try {
      final order = await getIt<SalesOrderRepository>().getById(
        OrderId(widget.orderId),
      );
      if (!mounted) return;
      setState(() {
        if (order != null) _order = order;
        _loading = false;
        _error = _order == null ? 'Pedido não encontrado.' : null;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        // Se já temos os dados vindos da lista, mantém a tela utilizável.
        if (_order == null) _error = error.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final order = _order;

    return Scaffold(
      appBar: B2BAppBar(
        title: 'Pedido #${order?.id.displayCode ?? widget.orderId}',
      ),
      body: _buildBody(context, order),
    );
  }

  Widget _buildBody(BuildContext context, SalesOrder? order) {
    if (order == null) {
      if (_loading) {
        return const Center(child: CircularProgressIndicator());
      }
      return _buildError(context);
    }

    final action = _buildNextStepAction(context, order);

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(20),
        children: [
          OrderDetailsContent(order: order),
          if (action != null) ...[const SizedBox(height: 24), action],
        ],
      ),
    );
  }

  Widget _buildError(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off_rounded,
              size: 56,
              color: theme.colorScheme.outline,
            ),
            const SizedBox(height: 16),
            Text(
              _error ?? 'Não foi possível carregar o pedido.',
              style: theme.textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            Wrap(
              spacing: 12,
              alignment: WrapAlignment.center,
              children: [
                OutlinedButton(
                  onPressed: () => context.canPop()
                      ? context.pop()
                      : context.go(AppPage.home.path),
                  child: const Text('Voltar'),
                ),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _loading = true;
                      _error = null;
                    });
                    _load();
                  },
                  child: const Text('Tentar novamente'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Próximo passo operacional do pedido, quando existe uma tela para ele.
  Widget? _buildNextStepAction(BuildContext context, SalesOrder order) {
    final (label, icon, path) = switch (order.status) {
      OrderStatus.pendingFinanceApproval || OrderStatus.blockedByFinance => (
        'Ir para análise de crédito',
        Icons.gpp_maybe_rounded,
        AppPage.finance.path,
      ),
      OrderStatus.delivered => (
        'Ir para faturamento',
        Icons.receipt_long_rounded,
        AppPage.billing.path,
      ),
      OrderStatus.pickingPacking || OrderStatus.inTransit => (
        'Ir para logística',
        Icons.local_shipping_rounded,
        AppPage.logistics.path,
      ),
      OrderStatus.invoiced ||
      OrderStatus.cancelled ||
      OrderStatus.rma => (null, null, null),
    };

    if (label == null || icon == null || path == null) return null;

    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: () => context.go(path),
        icon: Icon(icon),
        label: Text(label),
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
    );
  }
}
