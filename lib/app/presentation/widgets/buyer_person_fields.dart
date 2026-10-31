import 'package:ecommerce_b2b/app/presentation/formz/email_input.dart';
import 'package:ecommerce_b2b/app/presentation/formz/not_empty_input.dart';
import 'package:ecommerce_b2b/app/presentation/formz/phone_input.dart';
import 'package:flutter/material.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';

/// Campos de identificação do comprador compartilhados entre o cadastro pela
/// empresa e o cadastro de usuários.
///
/// O e-mail pode ficar desabilitado na edição (ele é a identidade do login) e os
/// campos de telefone/cargo só aparecem quando o papel selecionado é Buyer.
class BuyerPersonFields extends StatelessWidget {
  final TextEditingController fullNameController;
  final TextEditingController emailController;
  final TextEditingController phoneController;
  final TextEditingController positionController;
  final bool showBuyerFields;
  final bool emailEnabled;
  final double spacing;

  const BuyerPersonFields({
    super.key,
    required this.fullNameController,
    required this.emailController,
    required this.phoneController,
    required this.positionController,
    this.showBuyerFields = true,
    this.emailEnabled = true,
    this.spacing = 16,
  });

  @override
  Widget build(BuildContext context) {
    final phoneFormatter = MaskTextInputFormatter(
      mask: '(##) #####-####',
      filter: {"#": RegExp(r'[0-9]')},
    );

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        TextFormField(
          controller: fullNameController,
          decoration: const InputDecoration(
            labelText: 'Nome Completo *',
            prefixIcon: Icon(Icons.person_rounded),
          ),
          validator: (v) {
            final input = NotEmptyInput.dirty(v ?? '');
            return input.isValid ? null : 'Campo obrigatório';
          },
        ),
        SizedBox(height: spacing),
        TextFormField(
          controller: emailController,
          enabled: emailEnabled,
          decoration: const InputDecoration(
            labelText: 'E-mail *',
            prefixIcon: Icon(Icons.email_rounded),
          ),
          validator: (v) {
            final input = EmailInput.dirty(v ?? '');
            return input.isValid ? null : 'E-mail inválido';
          },
        ),
        if (showBuyerFields) ...[
          SizedBox(height: spacing),
          TextFormField(
            controller: phoneController,
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
          SizedBox(height: spacing),
          TextFormField(
            controller: positionController,
            decoration: const InputDecoration(
              labelText: 'Cargo *',
              hintText: 'Ex: Gerente de Compras',
              prefixIcon: Icon(Icons.badge_rounded),
            ),
            validator: (v) {
              final input = NotEmptyInput.dirty(v ?? '');
              return input.isValid ? null : 'Campo obrigatório';
            },
          ),
        ],
      ],
    );
  }
}
