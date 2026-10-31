import 'package:ecommerce_b2b/app/core/di/service_locator.dart';
import 'package:ecommerce_b2b/main.dart';
import 'package:ecommerce_b2b/modules/customer_management/company/model/repositories/company_repository.dart';
import 'package:ecommerce_b2b/modules/identity_access/model/user_session.dart';
import 'package:ecommerce_b2b/modules/identity_access/presentation/cubit/auth_cubit.dart';
import 'package:ecommerce_b2b/modules/shared_kernel/model/common/ids/company_id.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class UserProfileDropdown extends StatefulWidget {
  final Color? borderColor;

  const UserProfileDropdown({super.key, this.borderColor});

  @override
  State<UserProfileDropdown> createState() => _UserProfileDropdownState();
}

class _UserProfileDropdownState extends State<UserProfileDropdown> {
  String? _companyName;
  String? _positionTitle;
  String? _loadedProfileKey;

  /// Carrega a empresa uma única vez por sessão para exibir nome e cargo.
  void _ensureCompanyData(UserSession session) {
    final companyId = session.companyId;
    if (companyId == null) return;

    final profileKey = '${companyId.value}:${session.fullName}';
    if (profileKey == _loadedProfileKey) return;
    _loadedProfileKey = profileKey;
    _companyName = null;
    _positionTitle = null;
    _loadCompanyData(companyId, session.fullName, profileKey);
  }

  Future<void> _loadCompanyData(
    CompanyId companyId,
    String fullName,
    String profileKey,
  ) async {
    try {
      final company = await getIt<CompanyRepository>().findById(companyId);
      if (!mounted || profileKey != _loadedProfileKey) return;

      String? position;
      final normalizedName = fullName.trim().toLowerCase();
      if (company != null && normalizedName.isNotEmpty) {
        for (final buyer in company.authorizedBuyers) {
          if (buyer.fullName.trim().toLowerCase() == normalizedName) {
            if (buyer.positionTitle.trim().isNotEmpty) {
              position = buyer.positionTitle;
            }
            break;
          }
        }
      }

      setState(() {
        _companyName = company?.tradeName;
        _positionTitle = position;
      });
    } catch (_) {
      // Sem os dados da empresa, o menu mostra apenas nome e cargo.
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final authState = context.watch<AuthCubit>().state;

    String userName = 'Visitante';
    String userRole = 'Convidado';
    String? companyName;

    if (authState is AuthAuthenticated) {
      final session = authState.session;
      _ensureCompanyData(session);
      userName = session.fullName.isNotEmpty
          ? session.fullName
          : session.role.label;
      userRole = _positionTitle ?? session.role.label;
      companyName = _companyName;
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
              color: widget.borderColor ?? colorScheme.outlineVariant,
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
              if (companyName != null) ...[
                const SizedBox(height: 2),
                Text(
                  companyName,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
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
