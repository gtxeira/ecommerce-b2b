import 'package:ecommerce_b2b/modules/catalog/product/model/product.dart';
import 'package:ecommerce_b2b/modules/inventory/warehouse/model/warehouse.dart';
import 'package:flutter/material.dart';

typedef AdjustStockResult = ({Warehouse warehouse, int quantity});

/// Dialog de ajuste de estoque de um produto em um depósito.
class AdjustStockDialog extends StatefulWidget {
  const AdjustStockDialog({
    super.key,
    required this.product,
    required this.warehouses,
    this.initialWarehouse,
  });

  final Product product;
  final List<Warehouse> warehouses;
  final Warehouse? initialWarehouse;

  @override
  State<AdjustStockDialog> createState() => _AdjustStockDialogState();
}

class _AdjustStockDialogState extends State<AdjustStockDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _quantityController;
  late Warehouse _selectedWarehouse;

  @override
  void initState() {
    super.initState();
    _selectedWarehouse = widget.initialWarehouse ?? widget.warehouses.first;
    _quantityController = TextEditingController(
      text: _stockFor(_selectedWarehouse).toString(),
    );
  }

  int _stockFor(Warehouse warehouse) =>
      warehouse.getStockItem(widget.product.id)?.physicalQuantity.value ?? 0;

  @override
  void dispose() {
    _quantityController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      title: Text('Ajustar Estoque: ${widget.product.name}'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<Warehouse>(
              initialValue: _selectedWarehouse,
              decoration: const InputDecoration(labelText: 'Depósito'),
              items: widget.warehouses
                  .map(
                    (warehouse) => DropdownMenuItem(
                      value: warehouse,
                      child: Text(warehouse.name),
                    ),
                  )
                  .toList(),
              onChanged: widget.initialWarehouse != null
                  ? null
                  : (warehouse) {
                      if (warehouse == null) return;
                      setState(() {
                        _selectedWarehouse = warehouse;
                        _quantityController.text = _stockFor(
                          warehouse,
                        ).toString();
                      });
                    },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _quantityController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Quantidade Física'),
              validator: (value) {
                final quantity = int.tryParse((value ?? '').trim());
                if (quantity == null) return 'Informe um número inteiro';
                if (quantity < 0) return 'A quantidade não pode ser negativa';
                return null;
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: () {
            if (!(_formKey.currentState?.validate() ?? false)) return;
            Navigator.pop<AdjustStockResult>(context, (
              warehouse: _selectedWarehouse,
              quantity: int.parse(_quantityController.text.trim()),
            ));
          },
          child: const Text('Salvar'),
        ),
      ],
    );
  }
}
