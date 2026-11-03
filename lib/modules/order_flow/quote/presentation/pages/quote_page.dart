import 'package:ecommerce_b2b/app/core/di/service_locator.dart';
import 'package:ecommerce_b2b/app/presentation/widgets/b2b_app_bar.dart';
import 'package:ecommerce_b2b/modules/identity_access/presentation/cubit/auth_cubit.dart';
import 'package:ecommerce_b2b/modules/order_flow/quote/presentation/cubit/quote_cubit.dart';
import 'package:ecommerce_b2b/modules/order_flow/quote/presentation/pages/create_quote_view.dart';
import 'package:ecommerce_b2b/modules/order_flow/quote/presentation/pages/quote_list_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class QuotePage extends StatelessWidget {
  const QuotePage({super.key, this.initialTab = 0});

  /// Índice da aba inicial: 0 = novo orçamento, 1 = lista.
  final int initialTab;

  @override
  Widget build(BuildContext context) {
    final authState = context.watch<AuthCubit>().state;
    // O Admin vê a lista de todos os representantes, não a própria carteira.
    final isAdmin = authState is AuthAuthenticated && authState.session.isAdmin;

    return BlocProvider(
      create: (context) => getIt<QuoteCubit>(),
      child: DefaultTabController(
        length: 2,
        initialIndex: initialTab,
        child: Scaffold(
          appBar: B2BAppBar(
            title: 'Gestão de Orçamentos',
            bottom: TabBar(
              tabs: [
                const Tab(
                  icon: Icon(Icons.add_task_rounded),
                  text: 'Novo Orçamento',
                ),
                Tab(
                  icon: const Icon(Icons.list_alt_rounded),
                  text: isAdmin ? 'Todos os Orçamentos' : 'Meus Orçamentos',
                ),
              ],
            ),
          ),
          body: const TabBarView(
            children: [CreateQuoteView(), QuoteListView()],
          ),
        ),
      ),
    );
  }
}
