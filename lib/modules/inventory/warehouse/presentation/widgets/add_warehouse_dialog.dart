import 'package:flutter/material.dart';

typedef AddWarehouseResult = ({String code, String name});

/// Dialog de cadastro de depósito. Devolve os dados validados ou `null`.
class AddWarehouseDialog extends StatefulWidget {
  const AddWarehouseDialog({super.key});

  @override
  State<AddWarehouseDialog> createState() => _AddWarehouseDialogState();
}

class _AddWarehouseDialogState extends State<AddWarehouseDialog> {
  final _formKey = GlobalKey<FormState>();
  final _codeController = TextEditingController();
  final _nameController = TextEditingController();

  @override
  void dispose() {
    _codeController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      title: const Text('Novo Depósito'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Nome do Depósito *',
                prefixIcon: Icon(Icons.warehouse_outlined),
              ),
              validator: (value) =>
                  (value ?? '').trim().isEmpty ? 'Informe o nome' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _codeController,
              textCapitalization: TextCapitalization.characters,
              decoration: const InputDecoration(
                labelText: 'Código Identificador *',
                prefixIcon: Icon(Icons.qr_code_rounded),
                helperText: 'Até 20 caracteres, único',
              ),
              validator: (value) {
                final code = (value ?? '').trim();
                if (code.isEmpty) return 'Informe o código';
                if (code.length > 20) return 'Máximo de 20 caracteres';
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
            Navigator.pop<AddWarehouseResult>(context, (
              code: _codeController.text.trim(),
              name: _nameController.text.trim(),
            ));
          },
          child: const Text('Salvar'),
        ),
      ],
    );
  }
}
