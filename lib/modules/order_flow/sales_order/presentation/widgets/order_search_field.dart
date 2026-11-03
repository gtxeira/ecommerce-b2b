import 'package:flutter/material.dart';

/// Campo de busca das listas de pedido.
///
/// Não tem debounce: o filtro é local (em memória), então cada tecla pode
/// atualizar a lista sem custo de rede. Ficou como widget próprio para poder
/// ser testado sem a página inteira (que depende do `AuthCubit` pelo app bar).
class OrderSearchField extends StatefulWidget {
  const OrderSearchField({
    super.key,
    required this.onChanged,
    this.initialValue = '',
    this.hintText = 'Buscar por pedido, empresa ou nome fantasia',
  });

  final ValueChanged<String> onChanged;
  final String initialValue;
  final String hintText;

  @override
  State<OrderSearchField> createState() => _OrderSearchFieldState();
}

class _OrderSearchFieldState extends State<OrderSearchField> {
  late final TextEditingController _controller = TextEditingController(
    text: widget.initialValue,
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _clear() {
    _controller.clear();
    widget.onChanged('');
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _controller,
      textInputAction: TextInputAction.search,
      onChanged: (value) {
        widget.onChanged(value);
        // Só para mostrar/esconder o botão de limpar.
        setState(() {});
      },
      decoration: InputDecoration(
        hintText: widget.hintText,
        prefixIcon: const Icon(Icons.search),
        suffixIcon: _controller.text.isEmpty
            ? null
            : IconButton(
                icon: const Icon(Icons.clear),
                tooltip: 'Limpar busca',
                onPressed: _clear,
              ),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}
