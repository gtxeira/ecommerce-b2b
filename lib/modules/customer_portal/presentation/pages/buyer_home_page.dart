import 'package:ecommerce_b2b/app/core/di/service_locator.dart';
import 'package:ecommerce_b2b/app/presentation/widgets/user_profile_dropdown.dart';
import 'package:ecommerce_b2b/modules/customer_portal/boleto/domain/value_objects/boleto_copy.dart';
import 'package:ecommerce_b2b/modules/customer_portal/presentation/cubit/customer_portal_cubit.dart';
import 'package:ecommerce_b2b/modules/customer_portal/return_request/domain/enums/rma_status.dart';
import 'package:ecommerce_b2b/modules/identity_access/domain/user_session.dart';
import 'package:ecommerce_b2b/modules/identity_access/presentation/cubit/auth_cubit.dart';
import 'package:ecommerce_b2b/modules/order_flow/domain/enums/credit_status.dart';
import 'package:ecommerce_b2b/modules/order_flow/domain/enums/order_status.dart';
import 'package:ecommerce_b2b/modules/order_flow/sales_order/domain/sales_order.dart';
import 'package:ecommerce_b2b/modules/shared_kernel/domain/common/ids/company_id.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

class BuyerHomePage extends StatelessWidget {
  const BuyerHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final authState = context.watch<AuthCubit>().state;

    if (authState is! AuthAuthenticated) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final session = authState.session;
    final companyIdStr = session.companyId;

    if (companyIdStr == null) {
      return const Scaffold(
        body: Center(child: Text('Erro: Conta sem empresa associada.')),
      );
    }

    final companyId = CompanyId(companyIdStr.value);

    return BlocProvider(
      create: (context) => getIt<CustomerPortalCubit>()
        ..loadPortalData(companyId: companyId, session: session),
      child: BlocConsumer<CustomerPortalCubit, CustomerPortalState>(
        listener: (context, state) {
          if (state is CustomerPortalLoaded) {
            if (state.successMessage != null) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.successMessage!),
                  backgroundColor: colorScheme.secondary,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
              );
              context.read<CustomerPortalCubit>().clearSuccessMessage();
            }
            if (state.activeBoleto != null) {
              _showBoletoBottomSheet(context, state.activeBoleto!);
            }
          }
        },
        builder: (context, state) {
          if (state is CustomerPortalLoading) {
            return const Scaffold(body: Center(child: CircularProgressIndicator()));
          }
          if (state is CustomerPortalFailure) {
            return Scaffold(
              body: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error_outline_rounded, size: 64, color: colorScheme.error),
                    const SizedBox(height: 16),
                    Text(
                      'Erro ao carregar portal',
                      style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 32),
                      child: Text(state.message, textAlign: TextAlign.center),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: () => context.read<CustomerPortalCubit>().loadPortalData(
                            companyId: companyId,
                            session: session,
                          ),
                      icon: const Icon(Icons.refresh_rounded),
                      label: const Text('Tentar Novamente'),
                    ),
                  ],
                ),
              ),
            );
          }
          if (state is CustomerPortalLoaded) {
            final orders = state.orders;
            final rmas = state.returnRequests;
            final activeOrders = orders.where((o) => o.status != OrderStatus.delivered && o.status != OrderStatus.cancelled).toList();
            final pendingBoletos = orders.where((o) => o.status == OrderStatus.blockedByFinance || o.status == OrderStatus.pendingFinanceApproval).toList();

            return Scaffold(
              backgroundColor: colorScheme.surface,
              body: RefreshIndicator(
                onRefresh: () => context.read<CustomerPortalCubit>().loadPortalData(
                      companyId: companyId,
                      session: session,
                    ),
                child: CustomScrollView(
                  slivers: [
                    // Header Expressivo
                    SliverAppBar(
                      expandedHeight: 180,
                      floating: false,
                      pinned: true,
                      backgroundColor: colorScheme.primary,
                      elevation: 0,
                      scrolledUnderElevation: 3,
                      flexibleSpace: FlexibleSpaceBar(
                        titlePadding: const EdgeInsets.only(left: 20, bottom: 16),
                        title: Text(
                          'Olá, ${session.userId.value.substring(0, 8)}',
                          style: theme.textTheme.headlineSmall?.copyWith(
                            color: colorScheme.onPrimary,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.5,
                          ),
                        ),
                        background: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                colorScheme.primary,
                                colorScheme.primary.withValues(alpha: 0.8),
                                colorScheme.tertiary.withValues(alpha: 0.6),
                              ],
                            ),
                          ),
                          child: Stack(
                            children: [
                              Positioned(
                                right: -20,
                                top: -20,
                                child: Icon(
                                  Icons.shopping_bag,
                                  size: 200,
                                  color: colorScheme.onPrimary.withValues(alpha: 0.1),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      bottom: PreferredSize(
                        preferredSize: const Size.fromHeight(1.0),
                        child: Container(
                          color: colorScheme.outlineVariant.withValues(alpha: 0.3),
                          height: 1.0,
                        ),
                      ),
                      actions: [
                        UserProfileDropdown(
                          borderColor: colorScheme.onPrimary.withValues(alpha: 0.5),
                        ),
                      ],
                    ),

                    // Quick Summary Cards
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 24, 20, 8),
                        child: Row(
                          children: [
                            _buildSummaryCard(
                              context,
                              'Pedidos Ativos',
                              '${activeOrders.length} ativos',
                              Icons.shopping_cart_outlined,
                              colorScheme.primaryContainer,
                              colorScheme.onPrimaryContainer,
                            ),
                            const SizedBox(width: 12),
                            _buildSummaryCard(
                              context,
                              'Financeiro',
                              '${pendingBoletos.length} boletos',
                              Icons.account_balance_wallet_outlined,
                              colorScheme.secondaryContainer,
                              colorScheme.onSecondaryContainer,
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Seção de Ações Rápidas
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                        child: Text(
                          'Ações Rápidas',
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.5,
                          ),
                        ),
                      ),
                    ),

                    SliverToBoxAdapter(
                      child: SizedBox(
                        height: 120,
                        child: ListView(
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          children: [
                            _buildActionButton(
                              context,
                              'Novo Pedido',
                              Icons.add_rounded,
                              colorScheme.tertiaryContainer,
                              colorScheme.onTertiaryContainer,
                              () => context.push('/buyer-catalog'),
                            ),
                            _buildActionButton(
                              context,
                              'Ver Boletos',
                              Icons.description_outlined,
                              colorScheme.surfaceContainerHigh,
                              colorScheme.onSurface,
                              () => _showAllBoletosBottomSheet(context, pendingBoletos),
                            ),
                            _buildActionButton(
                              context,
                              'Abrir RMA',
                              Icons.assignment_return_outlined,
                              colorScheme.surfaceContainerHigh,
                              colorScheme.onSurface,
                              () => _showOpenRmaBottomSheet(context, orders, companyId, session),
                            ),
                            _buildActionButton(
                              context,
                              'Catálogo',
                              Icons.grid_view_rounded,
                              colorScheme.surfaceContainerHigh,
                              colorScheme.onSurface,
                              () => context.push('/buyer-catalog'),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Histórico de Pedidos Recentes
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 32, 20, 16),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Pedidos Recentes',
                              style: theme.textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.w900,
                                letterSpacing: -0.5,
                              ),
                            ),
                            TextButton(
                              onPressed: () => _showAllOrdersPage(context, orders),
                              child: const Text('Ver todos'),
                            ),
                          ],
                        ),
                      ),
                    ),

                    SliverPadding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            if (orders.isEmpty) {
                              return Card(
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                                child: const Padding(
                                  padding: EdgeInsets.all(24),
                                  child: Center(child: Text('Nenhum pedido encontrado.')),
                                ),
                              );
                            }
                            final order = orders[index];
                            final orderStatusLabel = _getOrderStatusLabel(order.status);
                            final orderStatusColor = _getOrderStatusColor(order.status, colorScheme);

                            return Card(
                              margin: const EdgeInsets.only(bottom: 12),
                              elevation: 0,
                              color: colorScheme.surfaceContainerLow,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(24),
                              ),
                              child: ListTile(
                                contentPadding: const EdgeInsets.all(16),
                                leading: Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: orderStatusColor.withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: Icon(
                                    _getOrderStatusIcon(order.status),
                                    color: orderStatusColor,
                                  ),
                                ),
                                title: Text(
                                  'Pedido #${order.id.value.substring(0, 8)}',
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                ),
                                subtitle: Text('Status: $orderStatusLabel\nTotal: ${order.total.toString()}'),
                                isThreeLine: true,
                                trailing: const Icon(Icons.chevron_right_rounded),
                                onTap: () => _showOrderDetailsDialog(context, order),
                              ),
                            );
                          },
                          childCount: orders.isEmpty ? 1 : (orders.length > 5 ? 5 : orders.length),
                        ),
                      ),
                    ),

                    // Acompanhamento de RMAs (Devoluções)
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 32, 20, 16),
                        child: Text(
                          'Acompanhamento de RMAs',
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.5,
                          ),
                        ),
                      ),
                    ),

                    SliverPadding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            if (rmas.isEmpty) {
                              return Card(
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                                color: colorScheme.surfaceContainerLow,
                                child: const Padding(
                                  padding: EdgeInsets.all(24),
                                  child: Center(child: Text('Nenhuma solicitação de devolução aberta.')),
                                ),
                              );
                            }
                            final rma = rmas[index];
                            final rmaStatusLabel = _getRmaStatusLabel(rma.status);
                            final rmaStatusColor = _getRmaStatusColor(rma.status, colorScheme);

                            return Card(
                              margin: const EdgeInsets.only(bottom: 12),
                              elevation: 0,
                              color: colorScheme.surfaceContainerLow,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(24),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          'RMA #${rma.id.value.substring(0, 8)}',
                                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                        ),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: rmaStatusColor.withValues(alpha: 0.15),
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          child: Text(
                                            rmaStatusLabel.toUpperCase(),
                                            style: TextStyle(
                                              color: rmaStatusColor,
                                              fontSize: 11,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    Text('Pedido Original: #${rma.orderId.substring(0, 8)}'),
                                    Text('Motivo: ${rma.reason}'),
                                    const Divider(height: 24),
                                    _buildRmaStatusStepper(rma.status, colorScheme),
                                  ],
                                ),
                              ),
                            );
                          },
                          childCount: rmas.isEmpty ? 1 : rmas.length,
                        ),
                      ),
                    ),

                    const SliverToBoxAdapter(child: SizedBox(height: 48)),
                  ],
                ),
              ),
            );
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }

  // --- Widgets Auxiliares ---

  Widget _buildSummaryCard(
    BuildContext context,
    String title,
    String value,
    IconData icon,
    Color backgroundColor,
    Color foregroundColor,
  ) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(28),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: foregroundColor, size: 28),
            const SizedBox(height: 16),
            Text(
              value,
              style: TextStyle(
                color: foregroundColor,
                fontSize: 20,
                fontWeight: FontWeight.w900,
              ),
            ),
            Text(
              title,
              style: TextStyle(
                color: foregroundColor.withValues(alpha: 0.7),
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton(
    BuildContext context,
    String label,
    IconData icon,
    Color backgroundColor,
    Color foregroundColor,
    VoidCallback onTap,
  ) {
    return Container(
      width: 100,
      margin: const EdgeInsets.only(right: 12),
      child: Column(
        children: [
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(24),
              child: Ink(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: backgroundColor,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: backgroundColor.withValues(alpha: 0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    )
                  ]
                ),
                child: Icon(icon, color: foregroundColor, size: 32),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  // --- Bottom Sheets e Diálogos ---

  void _showBoletoBottomSheet(BuildContext context, BoletoCopy boleto) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      builder: (sheetContext) => Padding(
        padding: EdgeInsets.fromLTRB(24, 24, 24, MediaQuery.of(sheetContext).viewInsets.bottom + 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 48,
                height: 6,
                decoration: BoxDecoration(
                  color: colorScheme.outlineVariant,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Segunda Via do Boleto',
              style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            const Text(
              'Use o código de barras abaixo para pagamento ou acesse o arquivo PDF.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: colorScheme.outlineVariant),
              ),
              child: SelectableText(
                boleto.barcode,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.1,
                  fontFamily: 'monospace',
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                Clipboard.setData(ClipboardData(text: boleto.barcode));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Código de barras copiado!')),
                );
              },
              icon: const Icon(Icons.copy_rounded),
              label: const Text('COPIAR CÓDIGO DE BARRAS'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Download do PDF iniciado (simulado)')),
                );
              },
              icon: const Icon(Icons.picture_as_pdf_rounded),
              label: const Text('VISUALIZAR PDF'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
            ),
          ],
        ),
      ),
    ).then((_) {
      if (context.mounted) {
        context.read<CustomerPortalCubit>().clearActiveBoleto();
      }
    });
  }

  void _showAllBoletosBottomSheet(BuildContext context, List<SalesOrder> pendingOrders) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      builder: (sheetContext) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 48,
                height: 6,
                decoration: BoxDecoration(
                  color: colorScheme.outlineVariant,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Boletos de Cobrança',
              style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Expanded(
              child: pendingOrders.isEmpty
                  ? const Center(
                      child: Text(
                        'Nenhum boleto em aberto no momento.',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    )
                  : ListView.builder(
                      itemCount: pendingOrders.length,
                      itemBuilder: (lContext, index) {
                        final order = pendingOrders[index];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          color: colorScheme.surfaceContainerLow,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Pedido #${order.id.value.substring(0, 8)}',
                                      style: const TextStyle(fontWeight: FontWeight.bold),
                                    ),
                                    const SizedBox(height: 4),
                                    Text('Total: ${order.total.toString()}'),
                                    Text(
                                      order.status == OrderStatus.blockedByFinance ? 'Bloqueado no Financeiro' : 'Aguardando Aprovação',
                                      style: TextStyle(
                                        color: order.status == OrderStatus.blockedByFinance ? colorScheme.error : colorScheme.secondary,
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                                ElevatedButton(
                                  onPressed: () {
                                    Navigator.pop(sheetContext);
                                    context.read<CustomerPortalCubit>().downloadBoleto(order.id);
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: colorScheme.primary,
                                    foregroundColor: colorScheme.onPrimary,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  ),
                                  child: const Text('VER BOLETO'),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  void _showOpenRmaBottomSheet(
    BuildContext context,
    List<SalesOrder> orders,
    CompanyId companyId,
    UserSession session,
  ) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // A API aceita RMA para pedidos entregues ou faturados.
    final deliveredOrders = orders
        .where((o) =>
            o.status == OrderStatus.delivered || o.status == OrderStatus.invoiced)
        .toList();

    if (deliveredOrders.isEmpty) {
      showDialog(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('Abrir RMA (Troca/Devolução)'),
          content: const Text(
            'Você não possui nenhum pedido com status "Entregue" associado à sua conta.\n\nSó é possível abrir solicitações de RMA para pedidos já entregues.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('ENTENDIDO'),
            ),
          ],
        ),
      );
      return;
    }

    SalesOrder selectedOrder = deliveredOrders.first;
    final reasonController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (stateContext, setState) {
            return Padding(
              padding: EdgeInsets.fromLTRB(24, 24, 24, MediaQuery.of(sheetContext).viewInsets.bottom + 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Container(
                      width: 48,
                      height: 6,
                      decoration: BoxDecoration(
                        color: colorScheme.outlineVariant,
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Solicitar Devolução (RMA)',
                    style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<SalesOrder>(
                    initialValue: selectedOrder,
                    decoration: const InputDecoration(
                      labelText: 'Selecione o Pedido Entregue',
                      border: OutlineInputBorder(),
                    ),
                    items: deliveredOrders.map((order) {
                      return DropdownMenuItem<SalesOrder>(
                        value: order,
                        child: Text('Pedido #${order.id.value.substring(0, 8)} - ${order.total.toString()}'),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) {
                        setState(() => selectedOrder = val);
                      }
                    },
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: reasonController,
                    maxLines: 4,
                    decoration: const InputDecoration(
                      labelText: 'Justificativa / Motivo do RMA',
                      hintText: 'Descreva os itens a serem trocados e o motivo detalhado...',
                      border: OutlineInputBorder(),
                      alignLabelWithHint: true,
                    ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () {
                      if (reasonController.text.trim().isEmpty) {
                        ScaffoldMessenger.of(stateContext).showSnackBar(
                          const SnackBar(content: Text('Por favor, preencha o motivo da devolução.')),
                        );
                        return;
                      }
                      Navigator.pop(sheetContext);
                      context.read<CustomerPortalCubit>().openRma(
                            order: selectedOrder,
                            reason: reasonController.text,
                            companyId: companyId,
                            session: session,
                          );
                    },
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      backgroundColor: colorScheme.primary,
                      foregroundColor: colorScheme.onPrimary,
                    ),
                    child: const Text('ENVIAR SOLICITAÇÃO DE RMA'),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showOrderDetailsDialog(BuildContext context, SalesOrder order) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        title: Text('Detalhes do Pedido #${order.id.value.substring(0, 8)}'),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Status: ${_getOrderStatusLabel(order.status)}', style: const TextStyle(fontWeight: FontWeight.bold)),
              Text('Limite Financeiro: ${_getCreditStatusLabel(order.creditStatus)}'),
              const Divider(height: 24),
              const Text('Itens do Pedido:', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              if (order.items.isEmpty)
                const Text('Nenhum item adicionado.')
              else
                Flexible(
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: order.items.length,
                    itemBuilder: (itemContext, index) {
                      final item = order.items[index];
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('${item.quantity.value}x Produto #${item.productId.value.substring(0, 5)}'),
                            Text(item.unitPriceSnapshot.toString()),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              const Divider(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Total:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  Text(order.total.toString(), style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: colorScheme.primary)),
                ],
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('FECHAR'),
          ),
        ],
      ),
    );
  }

  void _showAllOrdersPage(BuildContext context, List<SalesOrder> orders) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      builder: (sheetContext) => Container(
        height: MediaQuery.of(context).size.height * 0.85,
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 48,
                height: 6,
                decoration: BoxDecoration(
                  color: colorScheme.outlineVariant,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Histórico Completo de Pedidos',
              style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.builder(
                itemCount: orders.length,
                itemBuilder: (listContext, index) {
                  final order = orders[index];
                  final orderStatusLabel = _getOrderStatusLabel(order.status);
                  final orderStatusColor = _getOrderStatusColor(order.status, colorScheme);

                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    color: colorScheme.surfaceContainerLow,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    child: ListTile(
                      contentPadding: const EdgeInsets.all(16),
                      leading: CircleAvatar(
                        backgroundColor: orderStatusColor.withValues(alpha: 0.15),
                        child: Icon(_getOrderStatusIcon(order.status), color: orderStatusColor),
                      ),
                      title: Text(
                        'Pedido #${order.id.value.substring(0, 8)}',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text('Status: $orderStatusLabel\nTotal: ${order.total.toString()}'),
                      isThreeLine: true,
                      trailing: const Icon(Icons.chevron_right_rounded),
                      onTap: () {
                        _showOrderDetailsDialog(context, order);
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- Conversores de Status e Helpers ---

  String _getOrderStatusLabel(OrderStatus status) {
    switch (status) {
      case OrderStatus.pendingFinanceApproval:
        return 'Pendente Aprovação';
      case OrderStatus.blockedByFinance:
        return 'Bloqueado pelo Financeiro';
      case OrderStatus.pickingPacking:
        return 'Picking & Packing';
      case OrderStatus.inTransit:
        return 'Em Transporte';
      case OrderStatus.delivered:
        return 'Entregue';
      case OrderStatus.invoiced:
        return 'Faturado';
      case OrderStatus.rma:
        return 'Devolução / RMA';
      case OrderStatus.cancelled:
        return 'Cancelado';
    }
  }

  Color _getOrderStatusColor(OrderStatus status, ColorScheme colorScheme) {
    switch (status) {
      case OrderStatus.pendingFinanceApproval:
        return colorScheme.tertiary;
      case OrderStatus.blockedByFinance:
        return colorScheme.error;
      case OrderStatus.pickingPacking:
        return colorScheme.primary;
      case OrderStatus.inTransit:
        return Colors.orange;
      case OrderStatus.delivered:
        return Colors.green;
      case OrderStatus.invoiced:
        return Colors.teal;
      case OrderStatus.rma:
        return colorScheme.secondary;
      case OrderStatus.cancelled:
        return colorScheme.outline;
    }
  }

  IconData _getOrderStatusIcon(OrderStatus status) {
    switch (status) {
      case OrderStatus.pendingFinanceApproval:
        return Icons.hourglass_empty_rounded;
      case OrderStatus.blockedByFinance:
        return Icons.lock_rounded;
      case OrderStatus.pickingPacking:
        return Icons.inventory_2_outlined;
      case OrderStatus.inTransit:
        return Icons.local_shipping_outlined;
      case OrderStatus.delivered:
        return Icons.check_circle_outline_rounded;
      case OrderStatus.invoiced:
        return Icons.receipt_long_outlined;
      case OrderStatus.rma:
        return Icons.assignment_return_outlined;
      case OrderStatus.cancelled:
        return Icons.cancel_outlined;
    }
  }

  String _getCreditStatusLabel(CreditStatus status) {
    switch (status) {
      case CreditStatus.approved:
        return 'Aprovado';
      case CreditStatus.blocked:
        return 'Bloqueado';
      case CreditStatus.pending:
        return 'Pendente';
      default:
        return 'Desconhecido';
    }
  }

  String _getRmaStatusLabel(RmaStatus status) {
    switch (status) {
      case RmaStatus.pending:
        return 'Solicitado';
      case RmaStatus.authorized:
        return 'Autorizado';
      case RmaStatus.received:
        return 'Recebido';
      case RmaStatus.inspected:
        return 'Em Inspeção';
      case RmaStatus.completed:
        return 'Concluído';
      case RmaStatus.rejected:
        return 'Rejeitado';
    }
  }

  Color _getRmaStatusColor(RmaStatus status, ColorScheme colorScheme) {
    switch (status) {
      case RmaStatus.pending:
        return colorScheme.primary;
      case RmaStatus.authorized:
        return colorScheme.secondary;
      case RmaStatus.received:
      case RmaStatus.inspected:
        return Colors.orange;
      case RmaStatus.completed:
        return Colors.green;
      case RmaStatus.rejected:
        return colorScheme.error;
    }
  }

  Widget _buildRmaStatusStepper(RmaStatus status, ColorScheme colorScheme) {
    int activeIndex = 0;
    if (status == RmaStatus.authorized) activeIndex = 1;
    if (status == RmaStatus.received || status == RmaStatus.inspected) activeIndex = 2;
    if (status == RmaStatus.completed || status == RmaStatus.rejected) activeIndex = 3;

    final steps = ['Solicitado', 'Autorizado', 'Em Análise', 'Finalizado'];

    return Row(
      children: List.generate(steps.length * 2 - 1, (index) {
        if (index.isOdd) {
          // Divisor/Linha
          final stepIndex = index ~/ 2;
          final isActive = stepIndex < activeIndex;
          return Expanded(
            child: Container(
              height: 4,
              color: isActive ? colorScheme.primary : colorScheme.outlineVariant,
            ),
          );
        } else {
          // Ponto do Step
          final stepIndex = index ~/ 2;
          final isActive = stepIndex <= activeIndex;
          final isCompleted = stepIndex < activeIndex;

          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: isActive ? colorScheme.primary : colorScheme.surfaceContainerHigh,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isActive ? colorScheme.primary : colorScheme.outlineVariant,
                    width: 2,
                  ),
                ),
                child: isCompleted
                    ? Icon(Icons.check, size: 14, color: colorScheme.onPrimary)
                    : Center(
                        child: Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: isActive ? colorScheme.onPrimary : colorScheme.outline,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
              ),
              const SizedBox(height: 6),
              Text(
                steps[stepIndex],
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                  color: isActive ? colorScheme.primary : colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          );
        }
      }),
    );
  }
}
