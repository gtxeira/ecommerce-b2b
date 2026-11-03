import 'dart:async';

import 'package:ecommerce_b2b/modules/identity_access/model/enums/user_role.dart';
import 'package:ecommerce_b2b/modules/identity_access/presentation/cubit/auth_cubit.dart';
import 'package:ecommerce_b2b/modules/order_flow/sales_order/presentation/cubit/open_orders_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Mantém o contador de pedidos em aberto em sincronia com a sessão.
///
/// O `OpenOrdersCubit` é criado no `MyApp` (vive mais que as telas), então é
/// aqui — no composition root — que o ciclo de vida dele é amarrado ao login:
/// autenticou, carrega; saiu (ou é comprador, que não usa a navegação), zera.
class OpenOrdersAuthSync extends StatefulWidget {
  const OpenOrdersAuthSync({super.key, required this.child});

  final Widget child;

  @override
  State<OpenOrdersAuthSync> createState() => _OpenOrdersAuthSyncState();
}

class _OpenOrdersAuthSyncState extends State<OpenOrdersAuthSync> {
  StreamSubscription<AuthState>? _subscription;

  @override
  void initState() {
    super.initState();
    final auth = context.read<AuthCubit>();
    _subscription = auth.stream.listen(_syncWithSession);
    _syncWithSession(auth.state);
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  void _syncWithSession(AuthState state) {
    if (!mounted) return;
    final openOrders = context.read<OpenOrdersCubit>();

    if (state is AuthAuthenticated) {
      if (state.session.role == UserRole.buyer) {
        // Comprador não vê a sidebar; o portal tem o próprio histórico.
        openOrders.clear();
      } else {
        openOrders.load();
      }
      return;
    }

    if (state is AuthUnauthenticated) {
      openOrders.clear();
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
