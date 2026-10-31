import 'package:ecommerce_b2b/main.dart';
import 'package:ecommerce_b2b/modules/identity_access/model/enums/user_role.dart';
import 'package:ecommerce_b2b/modules/identity_access/presentation/cubit/auth_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class UserProfileDropdown extends StatelessWidget {
  final Color? borderColor;

  const UserProfileDropdown({super.key, this.borderColor});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final authState = context.watch<AuthCubit>().state;

    String userName = 'Visitante';
    String userRole = 'Convidado';

    if (authState is AuthAuthenticated) {
      userRole = authState.session.role.name;
      userName = switch (authState.session.role) {
        UserRole.buyer => 'Comprador',
        UserRole.representative => 'Representante',
        UserRole.finance => 'Gestor Financeiro',
        UserRole.supervisor => 'Supervisor',
        UserRole.admin => 'Administrador',
      };
    }

    return PopupMenuButton<void>(
      offset: const Offset(0, 56),
      surfaceTintColor: colorScheme.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12.0),
        child: Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: borderColor ?? colorScheme.outlineVariant,
              width: 1,
            ),
          ),
          child: CircleAvatar(
            radius: 16,
            backgroundColor: colorScheme.secondaryContainer,
            child: Icon(
              Icons.person_outline_rounded,
              size: 20,
              color: colorScheme.onSecondaryContainer,
            ),
          ),
        ),
      ),
      itemBuilder: (context) => [
        PopupMenuItem<void>(
          enabled: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                userName,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w900,
                  color: colorScheme.onSurface,
                ),
              ),
              Text(
                userRole.toUpperCase(),
                style: theme.textTheme.labelSmall?.copyWith(
                  color: colorScheme.primary,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 8),
              const Divider(),
            ],
          ),
        ),
        PopupMenuItem<void>(
          onTap: () {
            final brightness = MediaQuery.of(context).platformBrightness;
            // Pequeno delay para permitir que o menu feche antes de mudar o tema,
            // evitando glitch visual em alguns dispositivos.
            Future.delayed(Duration.zero, () {
              final currentMode = themeNotifier.value;
              final isDark =
                  currentMode == ThemeMode.dark ||
                  (currentMode == ThemeMode.system &&
                      brightness == Brightness.dark);
              themeNotifier.value = isDark ? ThemeMode.light : ThemeMode.dark;
            });
          },
          child: const ListTile(
            leading: Icon(Icons.brightness_6_outlined),
            title: Text(
              'Mudar Tema',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            contentPadding: EdgeInsets.zero,
            visualDensity: VisualDensity.compact,
          ),
        ),
        PopupMenuItem<void>(
          onTap: () {
            // O logout deve ser chamado fora do ciclo de construção do PopupMenu
            // para garantir que o GoRouter consiga processar o redirecionamento.
            context.read<AuthCubit>().logout();
          },
          child: ListTile(
            leading: Icon(Icons.logout_rounded, color: colorScheme.error),
            title: Text(
              'Sair',
              style: TextStyle(
                color: colorScheme.error,
                fontWeight: FontWeight.bold,
              ),
            ),
            contentPadding: EdgeInsets.zero,
            visualDensity: VisualDensity.compact,
          ),
        ),
      ],
    );
  }
}
