import 'package:ecommerce_b2b/app/core/di/service_locator.dart';
import 'package:ecommerce_b2b/app/presentation/widgets/b2b_app_bar.dart';
import 'package:ecommerce_b2b/modules/inventory/warehouse/presentation/cubit/inventory_cubit.dart';
import 'package:ecommerce_b2b/modules/inventory/warehouse/presentation/pages/stock_control_view.dart';
import 'package:ecommerce_b2b/modules/inventory/warehouse/presentation/pages/warehouse_management_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class InventoryPage extends StatelessWidget {
  const InventoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => getIt<InventoryCubit>()..load(),
      child: DefaultTabController(
        length: 2,
        child: Scaffold(
          appBar: const B2BAppBar(
            title: 'Gestão de Estoque',
            bottom: TabBar(
              tabs: [
                Tab(
                  icon: Icon(Icons.inventory_2_rounded),
                  text: 'Controle de Estoque',
                ),
                Tab(icon: Icon(Icons.warehouse_rounded), text: 'Depósitos'),
              ],
            ),
          ),
          body: const TabBarView(
            children: [StockControlView(), WarehouseManagementView()],
          ),
        ),
      ),
    );
  }
}
