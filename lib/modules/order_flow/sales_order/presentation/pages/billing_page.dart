import 'package:ecommerce_b2b/app/core/di/service_locator.dart';
import 'package:ecommerce_b2b/app/presentation/widgets/b2b_app_bar.dart';
import 'package:ecommerce_b2b/modules/order_flow/sales_order/model/repositories/sales_order_repository.dart';
import 'package:ecommerce_b2b/modules/order_flow/sales_order/model/sales_order.dart';
import 'package:ecommerce_b2b/modules/order_flow/sales_order/infrastructure/api/finance_api.dart';
import 'package:flutter/material.dart';

/// Faturamento dos pedidos entregues. É o gatilho da comissão do representante
/// na API; a análise de crédito (finance-review) é uma etapa anterior e separada.
class BillingPage extends StatefulWidget {
  const BillingPage({super.key});

  @override
  State<BillingPage> createState() => _BillingPageState();
}

class _BillingPageState extends State<BillingPage> {
  List<SalesOrder> _orders = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final orders = await getIt<SalesOrderRepository>().findByStatus(
        'Delivered',
      );
      if (!mounted) return;
      setState(() {
        _orders = orders;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao carregar pedidos: $error')),
      );
    }
  }

  Future<void> _invoice(SalesOrder order) async {
    try {
      final result = await getIt<FinanceApi>().invoice(order.id.value);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            result.commissionGenerated
                ? 'Pedido faturado e comissão gerada.'
                : 'Pedido faturado (empresa sem representante: sem comissão).',
          ),
        ),
      );
      await _load();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Erro ao faturar: $error')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const B2BAppBar(title: 'Faturamento'),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: _orders.isEmpty
                  ? const Center(
                      child: Text(
                        'Nenhum pedido entregue aguardando faturamento.',
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _orders.length,
                      itemBuilder: (context, index) {
                        final order = _orders[index];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          child: ListTile(
                            title: Text('Pedido #${order.id.displayCode}'),
                            subtitle: Text(
                              'Total: ${order.total.formatted} • Empresa: ${order.companyId ?? '-'}',
                            ),
                            trailing: ElevatedButton(
                              onPressed: () => _invoice(order),
                              child: const Text('Faturar'),
                            ),
                          ),
                        );
                      },
                    ),
            ),
    );
  }
}
