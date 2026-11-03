import 'package:ecommerce_b2b/app/core/di/service_locator.dart';
import 'package:ecommerce_b2b/modules/order_flow/quote/presentation/cubit/quote_cubit.dart';
import 'package:ecommerce_b2b/modules/order_flow/quote/presentation/pages/quote_list_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

/// Histórico de orçamentos da empresa do comprador.
///
/// Reusa a [QuoteListView]: o comprador só lê (não converte), e o filtro por
/// representante/empresa é exclusivo do Admin. A API restringe a consulta à
/// empresa da sessão.
class BuyerQuotesPage extends StatelessWidget {
  const BuyerQuotesPage({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return BlocProvider(
      create: (context) => getIt<QuoteCubit>(),
      child: Scaffold(
        backgroundColor: colorScheme.surface,
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded),
            onPressed: () => context.canPop() ? context.pop() : context.go('/'),
            tooltip: 'Voltar para Home',
          ),
          title: const Text(
            'Meus Orçamentos',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          backgroundColor: colorScheme.primary,
          foregroundColor: colorScheme.onPrimary,
          elevation: 0,
        ),
        body: const QuoteListView(),
      ),
    );
  }
}
