import 'package:ecommerce_b2b/app/core/di/service_locator.dart';
import 'package:ecommerce_b2b/modules/catalog/price_table/model/price_table.dart';
import 'package:ecommerce_b2b/modules/catalog/price_table/model/price_rule.dart';
import 'package:ecommerce_b2b/modules/catalog/price_table/model/enums/price_scope_type.dart';
import 'package:ecommerce_b2b/modules/catalog/price_table/presentation/cubit/price_table_cubit.dart';
import 'package:ecommerce_b2b/modules/catalog/price_table/presentation/cubit/price_table_state.dart';
import 'package:ecommerce_b2b/modules/catalog/product/presentation/cubit/catalog_cubit.dart';
import 'package:ecommerce_b2b/modules/catalog/product/presentation/cubit/catalog_state.dart';
import 'package:ecommerce_b2b/modules/shared_kernel/model/address/enums/state.dart'
    as address_state;
import 'package:ecommerce_b2b/modules/shared_kernel/model/common/ids/price_table_id.dart';
import 'package:ecommerce_b2b/modules/shared_kernel/model/common/ids/product_id.dart';
import 'package:ecommerce_b2b/modules/shared_kernel/model/finance/value_objects/money.dart';
import 'package:ecommerce_b2b/modules/shared_kernel/model/finance/value_objects/quantity.dart';
import 'package:ecommerce_b2b/app/presentation/formz/money_input.dart';
import 'package:ecommerce_b2b/app/presentation/formz/not_empty_input.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';

class PriceTableListView extends StatelessWidget {
  const PriceTableListView({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => getIt<PriceTableCubit>()..loadTables(),
      child: BlocBuilder<PriceTableCubit, PriceTableState>(
        builder: (context, state) {
          final theme = Theme.of(context);
          final colorScheme = theme.colorScheme;

          if (state is PriceTableLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is PriceTableError) {
            return Center(
              child: Text(
                state.message,
                style: TextStyle(color: colorScheme.error),
              ),
            );
          }

          if (state is PriceTableLoaded) {
            final tables = state.tables;
            return Scaffold(
              floatingActionButton: FloatingActionButton.extended(
                onPressed: () => _showAddTableDialog(context),
                icon: const Icon(Icons.add_chart_rounded),
                label: const Text('Nova Tabela'),
              ),
              body: tables.isEmpty
                  ? const Center(
                      child: Text('Nenhuma tabela de preços cadastrada.'),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: tables.length,
                      itemBuilder: (context, index) {
                        final table = tables[index];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: ExpansionTile(
                            title: Text(
                              table.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            subtitle: Text(
                              'Escopo: ${table.scopeType.label}',
                            ),
                            children: [
                              Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          'Regras de Preços (${table.rules.length})',
                                          style: theme.textTheme.titleSmall
                                              ?.copyWith(
                                                fontWeight: FontWeight.bold,
                                              ),
                                        ),
                                        TextButton.icon(
                                          onPressed: () => _showAddRuleDialog(
                                            context,
                                            table,
                                          ),
                                          icon: const Icon(
                                            Icons.add_circle_outline,
                                          ),
                                          label: const Text('Adicionar Regra'),
                                        ),
                                      ],
                                    ),
                                    if (table.rules.isEmpty)
                                      const Padding(
                                        padding: EdgeInsets.symmetric(
                                          vertical: 8.0,
                                        ),
                                        child: Text(
                                          'Nenhuma regra definida nesta tabela.',
                                        ),
                                      )
                                    else
                                      ...table.rules.map(
                                        (rule) => Card(
                                          color: colorScheme
                                              .surfaceContainerHighest
                                              .withValues(alpha: 0.3),
                                          elevation: 0,
                                          margin: const EdgeInsets.only(top: 8),
                                          child: ListTile(
                                            dense: true,
                                            title: Text(
                                              'Produto ID: ${rule.productId.value}',
                                            ),
                                            subtitle: Text(
                                              'Qtd: ${rule.minQuantity.value} - ${rule.maxQuantity.value} | '
                                              'Estado: ${rule.state?.code ?? "NACIONAL"}',
                                            ),
                                            trailing: Text(
                                              rule.unitPrice.formatted,
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                color: colorScheme.primary,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            );
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }

  void _showAddTableDialog(BuildContext context) {
    final formKey = GlobalKey<FormState>();
    final nameCtrl = TextEditingController();
    PriceScopeType scope = PriceScopeType.national;
    bool hasSubmitted = false;

    showDialog(
      context: context,
      builder: (diagCtx) => BlocProvider.value(
        value: context.read<PriceTableCubit>(),
        child: StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Nova Tabela de Preços'),
              content: Form(
                key: formKey,
                autovalidateMode: hasSubmitted
                    ? AutovalidateMode.onUserInteraction
                    : AutovalidateMode.disabled,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      controller: nameCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Nome da Tabela *',
                      ),
                      validator: (v) => NotEmptyInput.dirty(v ?? '').isValid
                          ? null
                          : 'Obrigatório',
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<PriceScopeType>(
                      initialValue: scope,
                      decoration: const InputDecoration(labelText: 'Escopo'),
                      items: PriceScopeType.values
                          .map(
                            (e) => DropdownMenuItem(
                              value: e,
                              child: Text(e.label),
                            ),
                          )
                          .toList(),
                      onChanged: (v) => setState(() => scope = v!),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(diagCtx),
                  child: const Text('Cancelar'),
                ),
                ElevatedButton(
                  onPressed: () {
                    setState(() => hasSubmitted = true);
                    if (formKey.currentState?.validate() ?? false) {
                      final table = PriceTable(
                        id: PriceTableId(const Uuid().v7()),
                        name: nameCtrl.text,
                        scopeType: scope,
                      );
                      context.read<PriceTableCubit>().saveTable(table);
                      Navigator.pop(diagCtx);
                    }
                  },
                  child: const Text('Criar'),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  void _showAddRuleDialog(BuildContext context, PriceTable table) {
    final formKey = GlobalKey<FormState>();
    final minQtyCtrl = TextEditingController(text: '1');
    final maxQtyCtrl = TextEditingController(text: '9999');
    final priceCtrl = TextEditingController();
    ProductId? selectedProduct;
    address_state.State? selectedState;
    bool hasSubmitted = false;

    showDialog(
      context: context,
      builder: (diagCtx) => MultiBlocProvider(
        providers: [
          BlocProvider.value(value: context.read<PriceTableCubit>()),
          BlocProvider(
            create: (context) => getIt<CatalogCubit>()..loadProducts(),
          ),
        ],
        child: StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Adicionar Regra de Preço'),
              content: SizedBox(
                width: 500,
                child: SingleChildScrollView(
                  child: Form(
                    key: formKey,
                    autovalidateMode: hasSubmitted
                        ? AutovalidateMode.onUserInteraction
                        : AutovalidateMode.disabled,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        BlocBuilder<CatalogCubit, CatalogState>(
                          builder: (context, state) {
                            if (state is CatalogLoaded) {
                              return DropdownButtonFormField<ProductId>(
                                decoration: const InputDecoration(
                                  labelText: 'Produto *',
                                ),
                                items: state.products
                                    .map(
                                      (p) => DropdownMenuItem(
                                        value: p.id,
                                        child: Text(p.name),
                                      ),
                                    )
                                    .toList(),
                                onChanged: (v) =>
                                    setState(() => selectedProduct = v),
                                validator: (v) =>
                                    v == null ? 'Obrigatório' : null,
                              );
                            }
                            return const CircularProgressIndicator();
                          },
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: minQtyCtrl,
                                keyboardType: TextInputType.number,
                                decoration: const InputDecoration(
                                  labelText: 'Qtd Mínima',
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: TextFormField(
                                controller: maxQtyCtrl,
                                keyboardType: TextInputType.number,
                                decoration: const InputDecoration(
                                  labelText: 'Qtd Máxima',
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        DropdownButtonFormField<address_state.State?>(
                          decoration: const InputDecoration(
                            labelText: 'Estado (Opcional)',
                          ),
                          items: [
                            const DropdownMenuItem(
                              value: null,
                              child: Text('NACIONAL'),
                            ),
                            ...address_state.State.values.map(
                              (e) => DropdownMenuItem(
                                value: e,
                                child: Text(e.code),
                              ),
                            ),
                          ],
                          onChanged: (v) => setState(() => selectedState = v),
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: priceCtrl,
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(
                              RegExp(r'^\d*\.?\d*'),
                            ),
                          ],
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          decoration: const InputDecoration(
                            labelText: 'Preço Unitário *',
                            prefixIcon: Icon(Icons.attach_money),
                          ),
                          validator: (v) => MoneyInput.dirty(v ?? '').isValid
                              ? null
                              : 'Preço inválido',
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(diagCtx),
                  child: const Text('Cancelar'),
                ),
                ElevatedButton(
                  onPressed: () {
                    setState(() => hasSubmitted = true);
                    if (formKey.currentState?.validate() ?? false) {
                      final rule = PriceRule(
                        productId: selectedProduct!,
                        minQuantity: Quantity.create(
                          int.parse(minQtyCtrl.text),
                        ).getOrThrow(),
                        maxQuantity: Quantity.create(
                          int.parse(maxQtyCtrl.text),
                        ).getOrThrow(),
                        state: selectedState,
                        unitPrice: Money.create(
                          double.parse(priceCtrl.text),
                        ).getOrThrow(),
                      );

                      final updatedTable = PriceTable(
                        id: table.id,
                        name: table.name,
                        scopeType: table.scopeType,
                        rules: [...table.rules, rule],
                      );

                      context.read<PriceTableCubit>().saveTable(updatedTable);
                      Navigator.pop(diagCtx);
                    }
                  },
                  child: const Text('Adicionar'),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
