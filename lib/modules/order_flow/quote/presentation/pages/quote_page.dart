import 'package:ecommerce_b2b/app/core/di/service_locator.dart';
import 'package:ecommerce_b2b/app/presentation/widgets/b2b_app_bar.dart';
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
    return BlocProvider(
      create: (context) => getIt<QuoteCubit>(),
      child: DefaultTabController(
        length: 2,
        initialIndex: initialTab,
        child: Scaffold(
          appBar: const B2BAppBar(
            title: 'Gestão de Orçamentos',
            bottom: TabBar(
              tabs: [
                Tab(icon: Icon(Icons.add_task_rounded), text: 'Novo Orçamento'),
                Tab(
                  icon: Icon(Icons.list_alt_rounded),
                  text: 'Meus Orçamentos',
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
