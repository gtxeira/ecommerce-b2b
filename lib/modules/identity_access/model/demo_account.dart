import 'package:ecommerce_b2b/modules/identity_access/model/enums/user_role.dart';
import 'package:flutter/material.dart';

/// Conta de demonstração disponível no seed da API.
///
/// A senha é a mesma para todas: [DemoAccounts.password]. A lista espelha
/// `UserSeeder.cs` da API para que o seletor multi-contas funcione sem precisar
/// consultar um endpoint administrativo.
class DemoAccount {
  const DemoAccount({
    required this.fullName,
    required this.email,
    required this.role,
    this.companyLabel,
    this.companyId,
    this.positionTitle,
  });

  final String fullName;
  final String email;
  final UserRole role;
  final String? companyLabel;
  final String? companyId;
  final String? positionTitle;

  /// Iniciais exibidas no avatar do seletor.
  String get initials {
    final parts = fullName
        .trim()
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts.first.characters.first.toUpperCase();
    return '${parts.first.characters.first}${parts.last.characters.first}'
        .toUpperCase();
  }

  IconData get icon => switch (role) {
    UserRole.buyer => Icons.shopping_bag_outlined,
    UserRole.representative => Icons.handshake_outlined,
    UserRole.supervisor => Icons.supervisor_account_outlined,
    UserRole.finance => Icons.account_balance_wallet_outlined,
    UserRole.admin => Icons.admin_panel_settings_outlined,
  };
}

abstract final class DemoAccounts {
  DemoAccounts._();

  static const String password = 'password123';

  static const List<DemoAccount> builtIn = [
    DemoAccount(
      fullName: 'Carlos Comprador',
      email: 'buyer@test.com',
      role: UserRole.buyer,
      companyLabel: 'Acme Corp',
      companyId: 'c1',
      positionTitle: 'Diretor de Compras',
    ),
    DemoAccount(
      fullName: 'Pepper Potts',
      email: 'pepper@stark.com',
      role: UserRole.buyer,
      companyLabel: 'Stark Industries',
      companyId: 'c2',
      positionTitle: 'CEO',
    ),
    DemoAccount(
      fullName: 'Representante Mock',
      email: 'rep@test.com',
      role: UserRole.representative,
    ),
    DemoAccount(
      fullName: 'Supervisor Mock',
      email: 'supervisor@test.com',
      role: UserRole.supervisor,
    ),
    DemoAccount(
      fullName: 'Financeiro Mock',
      email: 'finance@test.com',
      role: UserRole.finance,
    ),
    DemoAccount(
      fullName: 'Administrador Mock',
      email: 'admin@test.com',
      role: UserRole.admin,
    ),
  ];
}
