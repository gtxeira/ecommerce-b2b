import 'package:ecommerce_b2b/modules/identity_access/model/demo_account.dart';
import 'package:ecommerce_b2b/modules/identity_access/model/enums/user_role.dart';
import 'package:ecommerce_b2b/modules/identity_access/model/user_session.dart';
import 'package:ecommerce_b2b/modules/identity_access/presentation/cubit/auth_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Seletor de contas demo.
///
/// Retorna `true` quando a troca terminou com sucesso. A navegação para a home
/// fica a cargo de quem abriu o dialog.
class AccountSwitcherDialog extends StatefulWidget {
  const AccountSwitcherDialog({super.key});

  @override
  State<AccountSwitcherDialog> createState() => _AccountSwitcherDialogState();
}

class _AccountSwitcherDialogState extends State<AccountSwitcherDialog> {
  String? _switchingEmail;
  String? _error;

  bool get _busy => _switchingEmail != null;

  bool _isCurrent(UserSession? session, DemoAccount account) {
    if (session == null || session.role != account.role) return false;
    if (account.role == UserRole.buyer) {
      return session.companyId?.value == account.companyId;
    }
    return session.fullName.trim() == account.fullName.trim();
  }

  Future<void> _switch(DemoAccount account) async {
    setState(() {
      _switchingEmail = account.email;
      _error = null;
    });

    final error = await context.read<AuthCubit>().switchAccount(
      account.email,
      DemoAccounts.password,
    );

    if (!mounted) return;
    if (error == null) {
      Navigator.of(context).pop(true);
      return;
    }

    setState(() {
      _switchingEmail = null;
      _error = error;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final authState = context.watch<AuthCubit>().state;
    final session = authState is AuthAuthenticated ? authState.session : null;

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      title: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.manage_accounts_rounded, color: colorScheme.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Trocar de conta',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Contas de demonstração disponíveis',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      content: SizedBox(
        width: MediaQuery.sizeOf(context).width < 520 ? double.maxFinite : 440,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (_error != null) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: colorScheme.errorContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.error_outline_rounded,
                        color: colorScheme.onErrorContainer,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _error!,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colorScheme.onErrorContainer,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
              ],
              ...DemoAccounts.builtIn.map((account) {
                final isCurrent = _isCurrent(session, account);
                final isSwitching = _switchingEmail == account.email;

                return ListTile(
                  enabled: !_busy,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  selected: isCurrent,
                  selectedTileColor: colorScheme.secondaryContainer.withValues(
                    alpha: 0.45,
                  ),
                  leading: CircleAvatar(
                    backgroundColor: isCurrent
                        ? colorScheme.secondaryContainer
                        : colorScheme.surfaceContainerHighest,
                    child: isSwitching
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(
                            account.initials,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                  ),
                  title: Text(
                    account.fullName,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    [
                      account.email,
                      account.companyLabel ??
                          account.positionTitle ??
                          account.role.label,
                      if (account.companyLabel != null) account.role.label,
                    ].join(' · '),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  isThreeLine: true,
                  trailing: isCurrent
                      ? Icon(
                          Icons.check_circle_rounded,
                          color: colorScheme.primary,
                        )
                      : Icon(account.icon, color: colorScheme.onSurfaceVariant),
                  onTap: isCurrent || _busy ? null : () => _switch(account),
                );
              }),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _busy ? null : () => Navigator.of(context).pop(false),
          child: const Text('Cancelar'),
        ),
      ],
    );
  }
}
