import 'package:flutter/material.dart';

/// Selo com a quantidade de pedidos em aberto.
///
/// Envolve o ícone (e o `selectedIcon`, senão o selo some quando o item está
/// selecionado). Com zero, o selo é escondido em vez de mostrar "0".
class OpenOrdersBadge extends StatelessWidget {
  const OpenOrdersBadge({super.key, required this.count, required this.child});

  final int count;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Badge(
      isLabelVisible: count > 0,
      label: Text(count > 99 ? '99+' : '$count'),
      child: child,
    );
  }
}
