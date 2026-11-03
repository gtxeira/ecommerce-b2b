import 'package:ecommerce_b2b/app/core/di/service_locator.dart';
import 'package:ecommerce_b2b/app/presentation/widgets/b2b_app_bar.dart';
import 'package:ecommerce_b2b/app/presentation/widgets/buyer_person_fields.dart';
import 'package:ecommerce_b2b/modules/customer_management/company/model/company.dart';
import 'package:ecommerce_b2b/modules/customer_management/company/model/value_objects/cnpj.dart';
import 'package:ecommerce_b2b/modules/customer_management/company/model/value_objects/inscricao_estadual.dart';
import 'package:ecommerce_b2b/modules/customer_management/company/presentation/cubit/company_management_cubit.dart';
import 'package:ecommerce_b2b/modules/identity_access/model/user_session.dart';
import 'package:ecommerce_b2b/modules/sales_team/sales_representative/model/sales_representative.dart';
import 'package:ecommerce_b2b/modules/identity_access/presentation/cubit/auth_cubit.dart';
import 'package:ecommerce_b2b/modules/shared_kernel/model/address/enums/state.dart'
    as address_state;
import 'package:ecommerce_b2b/app/presentation/formz/email_input.dart';
import 'package:ecommerce_b2b/app/presentation/formz/money_input.dart';
import 'package:ecommerce_b2b/app/presentation/formz/not_empty_input.dart';
import 'package:ecommerce_b2b/app/presentation/formz/phone_input.dart';
import 'package:ecommerce_b2b/app/presentation/formz/zip_code_input.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';

const _teamScopeValue = '__team__';

class CompanyListPage extends StatelessWidget {
  const CompanyListPage({
    super.key,
    this.initialRepresentativeId,
    this.initialTeamView = false,
  });

  final String? initialRepresentativeId;
  final bool initialTeamView;

  @override
  Widget build(BuildContext context) {
    final authState = context.watch<AuthCubit>().state;

    if (authState is! AuthAuthenticated) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final session = authState.session;

    return BlocProvider(
      create: (context) => getIt<CompanyManagementCubit>()
        ..loadCompanies(
          session,
          targetRepresentativeId: initialRepresentativeId,
          teamView: initialTeamView,
        ),
      child: BlocConsumer<CompanyManagementCubit, CompanyManagementState>(
        listener: (context, state) {
          if (state is CompanyManagementSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.green,
              ),
            );
          } else if (state is CompanyManagementFailure) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Theme.of(context).colorScheme.error,
              ),
            );
          }
        },
        builder: (context, state) {
          final theme = Theme.of(context);
          final colorScheme = theme.colorScheme;

          return Scaffold(
            appBar: const B2BAppBar(title: 'Gestão de Clientes Corporativos'),
            floatingActionButton: session.isBuyer
                ? null
                : FloatingActionButton.extended(
                    onPressed: () =>
                        _showRegisterCompanyDialog(context, session),
                    icon: const Icon(Icons.add_business_rounded),
                    label: const Text('Nova Empresa'),
                  ),
            body: RefreshIndicator(
              onRefresh: () {
                final targetRepId = state is CompanyManagementLoaded
                    ? state.selectedRepresentativeId
                    : null;
                final teamView = state is CompanyManagementLoaded
                    ? state.isTeamView
                    : false;
                return context.read<CompanyManagementCubit>().loadCompanies(
                  session,
                  targetRepresentativeId: targetRepId,
                  teamView: teamView,
                );
              },
              child: state is CompanyManagementLoading
                  ? const Center(child: CircularProgressIndicator())
                  : state is CompanyManagementFailure &&
                        state is! CompanyManagementLoaded
                  ? Center(
                      child: Text(
                        state.message,
                        style: TextStyle(color: colorScheme.error),
                      ),
                    )
                  : _buildContent(context, state, session, theme, colorScheme),
            ),
          );
        },
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    CompanyManagementState state,
    UserSession session,
    ThemeData theme,
    ColorScheme colorScheme,
  ) {
    List<Company> companies = [];
    List<SalesRepresentative> subordinates = [];
    String? selectedRepId;
    var isTeamView = false;
    if (state is CompanyManagementLoaded) {
      companies = state.companies;
      subordinates = state.subordinates;
      selectedRepId = state.selectedRepresentativeId;
      isTeamView = state.isTeamView;
    }

    final hasSubordinates = session.isSupervisor && subordinates.isNotEmpty;
    final currentFilterValue = isTeamView
        ? _teamScopeValue
        : selectedRepId ?? session.userId.value;

    Widget mainContent;
    if (companies.isEmpty) {
      mainContent = const Expanded(
        child: Center(
          child: Padding(
            padding: EdgeInsets.all(32.0),
            child: Text(
              'Nenhuma empresa cadastrada.',
              style: TextStyle(fontSize: 16),
            ),
          ),
        ),
      );
    } else {
      mainContent = Expanded(
        child: ListView.builder(
          padding: const EdgeInsets.all(16.0),
          itemCount: companies.length,
          itemBuilder: (context, index) {
            final company = companies[index];
            return Card(
              margin: const EdgeInsets.only(bottom: 16.0),
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: ExpansionTile(
                leading: CircleAvatar(
                  backgroundColor: colorScheme.primaryContainer,
                  child: Icon(
                    Icons.business_rounded,
                    color: colorScheme.onPrimaryContainer,
                  ),
                ),
                title: Text(
                  company.tradeName,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                subtitle: Text('CNPJ: ${company.cnpj.formatted}'),
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Divider(),
                        _buildSectionTitle(theme, 'Informações Gerais'),
                        _buildInfoRow('Razão Social', company.legalName),
                        _buildInfoRow(
                          'Inscrição Estadual',
                          company.inscricaoEstadual.value,
                        ),
                        _buildInfoRow('E-mail de Contato', company.email.value),
                        _buildInfoRow('Telefone', company.phone.formatted),
                        const SizedBox(height: 12),
                        _buildSectionTitle(theme, 'Endereço de Faturamento'),
                        Text(
                          '${company.billingAddress.street.value}, ${company.billingAddress.number.value}'
                          '${company.billingAddress.complement != null ? " - ${company.billingAddress.complement!.value}" : ""}\n'
                          '${company.billingAddress.neighborhood.value} - ${company.billingAddress.city.value}/${company.billingAddress.state.code} - CEP: ${company.billingAddress.zipCode.formatted}',
                          style: theme.textTheme.bodyMedium,
                        ),
                        const SizedBox(height: 12),
                        _buildSectionTitle(theme, 'Crédito e Limites'),
                        _buildInfoRow(
                          'Limite Total',
                          company.creditLimit.toString(),
                        ),
                        _buildInfoRow(
                          'Saldo Devedor',
                          company.creditAccount.openBalance.toString(),
                        ),
                        _buildInfoRow(
                          'Pedidos Pendentes',
                          company.creditAccount.pendingOrdersBalance.toString(),
                        ),
                        _buildInfoRow(
                          'Limite Disponível',
                          company.creditAccount.availableLimit.toString(),
                          valueColor: colorScheme.primary,
                          isBold: true,
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _buildSectionTitle(
                              theme,
                              'Compradores Autorizados',
                            ),
                            if (session.isAdmin)
                              TextButton.icon(
                                onPressed: () => _showAddBuyerDialog(
                                  context,
                                  company,
                                  session,
                                ),
                                icon: const Icon(
                                  Icons.person_add_rounded,
                                  size: 18,
                                ),
                                label: const Text('Adicionar'),
                              ),
                          ],
                        ),
                        if (company.authorizedBuyers.isEmpty)
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 8.0),
                            child: Text(
                              'Nenhum comprador autorizado cadastrado.',
                            ),
                          )
                        else
                          ...company.authorizedBuyers.map(
                            (buyer) => Card(
                              color: colorScheme.surfaceContainerLow,
                              margin: const EdgeInsets.only(top: 8.0),
                              child: ListTile(
                                dense: true,
                                leading: const Icon(
                                  Icons.person_outline_rounded,
                                ),
                                title: Text(
                                  buyer.fullName,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                subtitle: Text(
                                  [
                                    if (buyer.positionTitle.trim().isNotEmpty)
                                      buyer.positionTitle,
                                    buyer.email.value,
                                    if (buyer.phone != null)
                                      buyer.phone!.formatted,
                                  ].join(' • '),
                                ),
                                trailing: buyer.active
                                    ? Icon(
                                        Icons.check_circle_rounded,
                                        color: Colors.green.shade600,
                                        size: 18,
                                      )
                                    : const Icon(
                                        Icons.cancel_rounded,
                                        color: Colors.grey,
                                        size: 18,
                                      ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      );
    }

    return Column(
      children: [
        if (hasSubordinates)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16.0,
                  vertical: 8.0,
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.supervised_user_circle_rounded,
                      color: colorScheme.primary,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Filtrar Carteira por Representante',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey,
                            ),
                          ),
                          const SizedBox(height: 4),
                          DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              isExpanded: true,
                              value: currentFilterValue,
                              items: [
                                DropdownMenuItem(
                                  value: _teamScopeValue,
                                  child: const Text(
                                    'Toda a Equipe (Consolidado)',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                DropdownMenuItem(
                                  value: session.userId.value,
                                  child: const Text('Minha Carteira (Pessoal)'),
                                ),
                                ...subordinates.map(
                                  (sub) => DropdownMenuItem(
                                    value: sub.id.value,
                                    child: Text(sub.fullName),
                                  ),
                                ),
                              ],
                              onChanged: (newRepId) {
                                if (newRepId == null) return;
                                if (newRepId == _teamScopeValue) {
                                  context
                                      .read<CompanyManagementCubit>()
                                      .loadCompanies(session, teamView: true);
                                } else {
                                  context
                                      .read<CompanyManagementCubit>()
                                      .loadCompanies(
                                        session,
                                        targetRepresentativeId: newRepId,
                                      );
                                }
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        mainContent,
      ],
    );
  }

  Widget _buildSectionTitle(ThemeData theme, String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6.0),
      child: Text(
        title,
        style: theme.textTheme.titleSmall?.copyWith(
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }

  Widget _buildInfoRow(
    String label,
    String value, {
    Color? valueColor,
    bool isBold = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey, fontSize: 13)),
          Text(
            value,
            style: TextStyle(
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              color: valueColor,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  void _showRegisterCompanyDialog(BuildContext context, UserSession session) {
    final formKey = GlobalKey<FormState>();
    final legalNameCtrl = TextEditingController();
    final tradeNameCtrl = TextEditingController();
    final cnpjCtrl = TextEditingController();
    final ieCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    final streetCtrl = TextEditingController(text: 'Rua das Indústrias');
    final numberCtrl = TextEditingController(text: '123');
    final complementCtrl = TextEditingController();
    final neighborhoodCtrl = TextEditingController(text: 'Distrito Industrial');
    final cityCtrl = TextEditingController(text: 'São Paulo');
    final stateCtrl = TextEditingController(text: 'SP');
    final zipCodeCtrl = TextEditingController(text: '01000-000');
    final creditLimitCtrl = TextEditingController(text: '50000');

    final cnpjFormatter = MaskTextInputFormatter(
      mask: '##.###.###/####-##',
      filter: {"#": RegExp(r'[0-9]')},
    );
    final phoneFormatter = MaskTextInputFormatter(
      mask: '(##) #####-####',
      filter: {"#": RegExp(r'[0-9]')},
    );
    final zipCodeFormatter = MaskTextInputFormatter(
      mask: '#####-###',
      filter: {"#": RegExp(r'[0-9]')},
    );

    bool hasSubmitted = false;

    showDialog(
      context: context,
      builder: (diagCtx) => BlocProvider.value(
        value: context.read<CompanyManagementCubit>(),
        child: StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Cadastrar Nova Empresa'),
              content: SizedBox(
                width: 500,
                child: SingleChildScrollView(
                  child: Form(
                    key: formKey,
                    autovalidateMode: hasSubmitted
                        ? AutovalidateMode.onUserInteraction
                        : AutovalidateMode.disabled,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TextFormField(
                          controller: tradeNameCtrl,
                          decoration: const InputDecoration(
                            labelText: 'Nome Fantasia *',
                            prefixIcon: Icon(Icons.storefront_rounded),
                          ),
                          validator: (v) {
                            final input = NotEmptyInput.dirty(v ?? '');
                            return input.isValid ? null : 'Campo obrigatório';
                          },
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: legalNameCtrl,
                          decoration: const InputDecoration(
                            labelText: 'Razão Social *',
                            prefixIcon: Icon(Icons.business_rounded),
                          ),
                          validator: (v) {
                            final input = NotEmptyInput.dirty(v ?? '');
                            return input.isValid ? null : 'Campo obrigatório';
                          },
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: cnpjCtrl,
                          inputFormatters: [cnpjFormatter],
                          decoration: const InputDecoration(
                            labelText: 'CNPJ *',
                            hintText: '00.000.000/0000-00',
                            prefixIcon: Icon(Icons.badge_rounded),
                          ),
                          validator: (v) {
                            if (v == null || v.isEmpty) {
                              return 'Campo obrigatório';
                            }
                            final res = Cnpj.create(v);
                            if (res.isFailure) {
                              return res.getFailureOrThrow().message;
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: ieCtrl,
                          decoration: const InputDecoration(
                            labelText: 'Inscrição Estadual *',
                            prefixIcon: Icon(Icons.corporate_fare_rounded),
                          ),
                          validator: (v) {
                            if (v == null || v.isEmpty) {
                              return 'Campo obrigatório';
                            }
                            final res = InscricaoEstadual.create(v);
                            if (res.isFailure) {
                              return res.getFailureOrThrow().message;
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: emailCtrl,
                          decoration: const InputDecoration(
                            labelText: 'E-mail *',
                            prefixIcon: Icon(Icons.email_rounded),
                          ),
                          validator: (v) {
                            final input = EmailInput.dirty(v ?? '');
                            return input.isValid ? null : 'E-mail inválido';
                          },
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: phoneCtrl,
                          inputFormatters: [phoneFormatter],
                          decoration: const InputDecoration(
                            labelText: 'Telefone *',
                            hintText: '(00) 00000-0000',
                            prefixIcon: Icon(Icons.phone_rounded),
                          ),
                          validator: (v) {
                            final input = PhoneInput.dirty(v ?? '');
                            return input.isValid ? null : 'Telefone inválido';
                          },
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: creditLimitCtrl,
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(
                              RegExp(r'^\d*\.?\d*'),
                            ),
                          ],
                          decoration: const InputDecoration(
                            labelText: 'Limite de Crédito pré-aprovado *',
                            prefixIcon: Icon(Icons.attach_money_rounded),
                          ),
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          validator: (v) {
                            final input = MoneyInput.dirty(v ?? '');
                            return input.isValid
                                ? null
                                : 'Limite de crédito inválido';
                          },
                        ),
                        const Divider(height: 48),
                        const Align(
                          alignment: Alignment.centerLeft,
                          child: Padding(
                            padding: EdgeInsets.only(bottom: 16.0),
                            child: Text(
                              'Endereço de Faturamento',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                        TextFormField(
                          controller: streetCtrl,
                          decoration: const InputDecoration(
                            labelText: 'Rua *',
                            prefixIcon: Icon(Icons.add_road_rounded),
                          ),
                          validator: (v) {
                            final input = NotEmptyInput.dirty(v ?? '');
                            return input.isValid ? null : 'Campo obrigatório';
                          },
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: numberCtrl,
                          decoration: const InputDecoration(
                            labelText: 'Número *',
                            prefixIcon: Icon(Icons.pin_rounded),
                          ),
                          validator: (v) {
                            final input = NotEmptyInput.dirty(v ?? '');
                            return input.isValid ? null : 'Campo obrigatório';
                          },
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: complementCtrl,
                          decoration: const InputDecoration(
                            labelText: 'Complemento',
                            prefixIcon: Icon(Icons.info_outline_rounded),
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: neighborhoodCtrl,
                          decoration: const InputDecoration(
                            labelText: 'Bairro *',
                            prefixIcon: Icon(Icons.maps_home_work_rounded),
                          ),
                          validator: (v) {
                            final input = NotEmptyInput.dirty(v ?? '');
                            return input.isValid ? null : 'Campo obrigatório';
                          },
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: cityCtrl,
                          decoration: const InputDecoration(
                            labelText: 'Cidade *',
                            prefixIcon: Icon(Icons.location_city_rounded),
                          ),
                          validator: (v) {
                            final input = NotEmptyInput.dirty(v ?? '');
                            return input.isValid ? null : 'Campo obrigatório';
                          },
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: stateCtrl,
                          decoration: const InputDecoration(
                            labelText: 'Estado (UF) *',
                            prefixIcon: Icon(Icons.map_rounded),
                          ),
                          validator: (v) {
                            if (v == null || v.isEmpty) {
                              return 'Campo obrigatório';
                            }
                            final res = address_state.State.fromString(v);
                            if (res.isFailure) return 'UF inválida (ex: SP)';
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: zipCodeCtrl,
                          inputFormatters: [zipCodeFormatter],
                          decoration: const InputDecoration(
                            labelText: 'CEP *',
                            hintText: '00000-000',
                            prefixIcon: Icon(Icons.local_post_office_rounded),
                          ),
                          validator: (v) {
                            final input = ZipCodeInput.dirty(v ?? '');
                            return input.isValid ? null : 'CEP inválido';
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(diagCtx),
                  child: const Text('Cancelar'),
                ),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      hasSubmitted = true;
                    });
                    if (formKey.currentState?.validate() ?? false) {
                      context.read<CompanyManagementCubit>().registerCompany(
                        currentSession: session,
                        legalName: legalNameCtrl.text,
                        tradeName: tradeNameCtrl.text,
                        cnpj: cnpjCtrl.text,
                        inscricaoEstadual: ieCtrl.text,
                        email: emailCtrl.text,
                        phone: phoneCtrl.text,
                        billingStreet: streetCtrl.text,
                        billingNumber: numberCtrl.text,
                        billingComplement: complementCtrl.text.isEmpty
                            ? null
                            : complementCtrl.text,
                        billingNeighborhood: neighborhoodCtrl.text,
                        billingCity: cityCtrl.text,
                        billingState: stateCtrl.text,
                        billingZipCode: zipCodeCtrl.text,
                        shippingStreet: streetCtrl.text,
                        shippingNumber: numberCtrl.text,
                        shippingComplement: complementCtrl.text.isEmpty
                            ? null
                            : complementCtrl.text,
                        shippingNeighborhood: neighborhoodCtrl.text,
                        shippingCity: cityCtrl.text,
                        shippingState: stateCtrl.text,
                        shippingZipCode: zipCodeCtrl.text,
                        creditLimit:
                            double.tryParse(creditLimitCtrl.text) ?? 0.0,
                      );
                      Navigator.pop(diagCtx);
                    }
                  },
                  child: const Text('Cadastrar'),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  void _showAddBuyerDialog(
    BuildContext context,
    Company company,
    UserSession session,
  ) {
    final formKey = GlobalKey<FormState>();
    final fullNameCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    final positionCtrl = TextEditingController();
    final passwordCtrl = TextEditingController();

    bool hasSubmitted = false;

    showDialog(
      context: context,
      builder: (diagCtx) => BlocProvider.value(
        value: context.read<CompanyManagementCubit>(),
        child: StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text('Adicionar Comprador - ${company.tradeName}'),
              content: SizedBox(
                width: 500, // Aumenta a largura do modal
                child: SingleChildScrollView(
                  child: Form(
                    key: formKey,
                    autovalidateMode: hasSubmitted
                        ? AutovalidateMode.onUserInteraction
                        : AutovalidateMode.disabled,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        BuyerPersonFields(
                          fullNameController: fullNameCtrl,
                          emailController: emailCtrl,
                          phoneController: phoneCtrl,
                          positionController: positionCtrl,
                        ),
                        const Divider(height: 32),
                        const Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            'Acesso ao portal',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: passwordCtrl,
                          obscureText: true,
                          decoration: const InputDecoration(
                            labelText: 'Senha inicial *',
                            helperText:
                                'Mínimo 8 caracteres, com pelo menos uma letra e um número',
                            prefixIcon: Icon(Icons.lock_rounded),
                          ),
                          validator: (v) {
                            final value = v ?? '';
                            if (value.length < 8) {
                              return 'A senha deve ter ao menos 8 caracteres';
                            }
                            if (!RegExp(r'[A-Za-z]').hasMatch(value) ||
                                !RegExp(r'\d').hasMatch(value)) {
                              return 'A senha deve conter letra e número';
                            }
                            return null;
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(diagCtx),
                  child: const Text('Cancelar'),
                ),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      hasSubmitted = true;
                    });
                    if (formKey.currentState?.validate() ?? false) {
                      context.read<CompanyManagementCubit>().addAuthorizedBuyer(
                        currentSession: session,
                        companyId: company.id,
                        fullName: fullNameCtrl.text,
                        email: emailCtrl.text,
                        phone: phoneCtrl.text,
                        positionTitle: positionCtrl.text,
                        password: passwordCtrl.text,
                      );
                      Navigator.pop(diagCtx);
                    }
                  },
                  child: const Text('Adicionar'),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
