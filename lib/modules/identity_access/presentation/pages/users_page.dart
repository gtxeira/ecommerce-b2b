import 'package:ecommerce_b2b/app/core/di/service_locator.dart';
import 'package:ecommerce_b2b/app/presentation/widgets/b2b_app_bar.dart';
import 'package:ecommerce_b2b/modules/customer_management/company/model/repositories/company_repository.dart';
import 'package:ecommerce_b2b/modules/identity_access/model/enums/user_role.dart';
import 'package:ecommerce_b2b/modules/identity_access/model/user_account.dart';
import 'package:ecommerce_b2b/modules/identity_access/presentation/cubit/user_management_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class UsersPage extends StatelessWidget {
  const UsersPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<UserManagementCubit>()..load(),
      child: const _UsersView(),
    );
  }
}

class _UsersView extends StatefulWidget {
  const _UsersView();

  @override
  State<_UsersView> createState() => _UsersViewState();
}

class _UsersViewState extends State<_UsersView> {
  final _searchController = TextEditingController();
  final Map<String, String> _companyNames = {};
  UserRole? _roleFilter;

  @override
  void initState() {
    super.initState();
    _loadCompanyNames();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  /// Carrega o nome fantasia das empresas para não exibir o id na listagem.
  Future<void> _loadCompanyNames() async {
    try {
      final companies = await getIt<CompanyRepository>().findAll();
      if (!mounted) return;
      setState(() {
        _companyNames
          ..clear()
          ..addEntries(
            companies.map(
              (company) => MapEntry(company.id.value, company.tradeName),
            ),
          );
      });
    } catch (_) {
      // Mantém o fallback para o id caso não seja possível carregar as empresas.
    }
  }

  void _reload() {
    context.read<UserManagementCubit>().load(
      role: _roleFilter,
      search: _searchController.text,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: const B2BAppBar(title: 'Gestão de Usuários'),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showUserDialog(context, null),
        icon: const Icon(Icons.person_add_alt_1_rounded),
        label: const Text('Novo Usuário'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: const InputDecoration(
                      hintText: 'Pesquisar por nome ou e-mail',
                      prefixIcon: Icon(Icons.search),
                      border: OutlineInputBorder(),
                    ),
                    onSubmitted: (_) => _reload(),
                  ),
                ),
                const SizedBox(width: 12),
                DropdownButton<UserRole?>(
                  value: _roleFilter,
                  hint: const Text('Papel'),
                  items: [
                    const DropdownMenuItem<UserRole?>(
                      value: null,
                      child: Text('Todos'),
                    ),
                    ...UserRole.values.map(
                      (role) => DropdownMenuItem(
                        value: role,
                        child: Text(role.label),
                      ),
                    ),
                  ],
                  onChanged: (value) {
                    setState(() => _roleFilter = value);
                    _reload();
                  },
                ),
              ],
            ),
          ),
          Expanded(
            child: BlocConsumer<UserManagementCubit, UserManagementState>(
              listener: (context, state) {
                if (state is UserManagementSuccess) {
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(SnackBar(content: Text(state.message)));
                } else if (state is UserManagementFailure) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(state.message),
                      backgroundColor: theme.colorScheme.error,
                    ),
                  );
                }
              },
              builder: (context, state) {
                if (state is UserManagementLoading ||
                    state is UserManagementInitial) {
                  return const Center(child: CircularProgressIndicator());
                }

                final users = state is UserManagementLoaded
                    ? state.users
                    : const <UserAccount>[];

                if (users.isEmpty) {
                  return const Center(
                    child: Text('Nenhum usuário encontrado.'),
                  );
                }

                return RefreshIndicator(
                  onRefresh: () async => _reload(),
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: users.length,
                    itemBuilder: (context, index) {
                      final user = users[index];
                      final companyName = user.companyId == null
                          ? null
                          : _companyNames[user.companyId!] ?? user.companyId;
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: ListTile(
                          leading: CircleAvatar(
                            child: Icon(
                              user.active
                                  ? Icons.person_outline
                                  : Icons.person_off_outlined,
                            ),
                          ),
                          title: Text(user.fullName),
                          subtitle: Text(
                            '${user.email} • ${user.role.label}'
                            '${companyName == null ? '' : ' • $companyName'}',
                          ),
                          trailing: PopupMenuButton<String>(
                            onSelected: (action) {
                              if (action == 'edit') {
                                _showUserDialog(context, user);
                              } else if (action == 'password') {
                                _showPasswordDialog(context, user);
                              }
                            },
                            itemBuilder: (_) => const [
                              PopupMenuItem(
                                value: 'edit',
                                child: Text('Editar'),
                              ),
                              PopupMenuItem(
                                value: 'password',
                                child: Text('Redefinir senha'),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showUserDialog(BuildContext context, UserAccount? user) async {
    final companies = await getIt<CompanyRepository>().findAll();
    if (!context.mounted) return;

    final cubit = context.read<UserManagementCubit>();
    final fullNameCtrl = TextEditingController(text: user?.fullName ?? '');
    final emailCtrl = TextEditingController(text: user?.email ?? '');
    final passwordCtrl = TextEditingController();
    var role = user?.role ?? UserRole.buyer;
    var active = user?.active ?? true;
    String? companyId =
        user?.companyId ??
        (companies.isNotEmpty ? companies.first.id.value : null);

    await showDialog<void>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(user == null ? 'Novo usuário' : 'Editar usuário'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: fullNameCtrl,
                  decoration: const InputDecoration(labelText: 'Nome completo'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: emailCtrl,
                  enabled: user == null,
                  decoration: const InputDecoration(labelText: 'E-mail'),
                ),
                if (user == null) ...[
                  const SizedBox(height: 12),
                  TextField(
                    controller: passwordCtrl,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: 'Senha inicial',
                      helperText: 'Mínimo 8 caracteres, com letra e dígito',
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                DropdownButtonFormField<UserRole>(
                  initialValue: role,
                  decoration: const InputDecoration(labelText: 'Papel'),
                  items: UserRole.values
                      .map(
                        (item) => DropdownMenuItem(
                          value: item,
                          child: Text(item.label),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    if (value == null) return;
                    setDialogState(() {
                      role = value;
                      if (role != UserRole.buyer) companyId = null;
                    });
                  },
                ),
                if (role == UserRole.buyer) ...[
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: companyId,
                    decoration: const InputDecoration(labelText: 'Empresa'),
                    items: companies
                        .map(
                          (company) => DropdownMenuItem(
                            value: company.id.value,
                            child: Text(company.tradeName),
                          ),
                        )
                        .toList(),
                    onChanged: (value) =>
                        setDialogState(() => companyId = value),
                  ),
                ],
                if (user != null) ...[
                  const SizedBox(height: 8),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Ativo'),
                    value: active,
                    onChanged: (value) => setDialogState(() => active = value),
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () {
                if (user == null) {
                  cubit.createUser(
                    fullName: fullNameCtrl.text.trim(),
                    email: emailCtrl.text.trim(),
                    password: passwordCtrl.text,
                    role: role,
                    companyId: role == UserRole.buyer ? companyId : null,
                  );
                } else {
                  cubit.updateUser(
                    id: user.id,
                    fullName: fullNameCtrl.text.trim(),
                    role: role,
                    companyId: role == UserRole.buyer ? companyId : null,
                    active: active,
                  );
                }
                Navigator.pop(dialogContext);
              },
              child: const Text('Salvar'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showPasswordDialog(
    BuildContext context,
    UserAccount user,
  ) async {
    final cubit = context.read<UserManagementCubit>();
    final controller = TextEditingController();

    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('Redefinir senha — ${user.fullName}'),
        content: TextField(
          controller: controller,
          obscureText: true,
          decoration: const InputDecoration(labelText: 'Nova senha'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              cubit.resetPassword(id: user.id, newPassword: controller.text);
              Navigator.pop(dialogContext);
            },
            child: const Text('Redefinir'),
          ),
        ],
      ),
    );
  }
}
