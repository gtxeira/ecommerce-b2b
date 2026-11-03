/// Rótulos padrão de identificação na UI.
///
/// A regra é sempre a mesma: nome legível + ID precedido de `#`, para o ID nunca
/// aparecer solto. Quando o nome não foi resolvido (registro removido do
/// catálogo/cadastro), o fallback deixa claro o que falta em vez de mostrar só o
/// número.
String formatId(String value) => '#$value';

/// `Nome Fantasia (Razão Social) · #id`.
String companyLabel({
  String? tradeName,
  String? legalName,
  required String id,
}) {
  final trade = (tradeName ?? '').trim();
  final legal = (legalName ?? '').trim();
  final name = switch ((trade.isEmpty, legal.isEmpty)) {
    (true, true) => 'Empresa não encontrada',
    (true, false) => legal,
    (false, true) => trade,
    (false, false) => trade == legal ? trade : '$trade ($legal)',
  };
  return '$name · ${formatId(id)}';
}

/// `Nome (SKU) · #id`.
String productLabel({String? name, String? sku, required String id}) {
  final productName = (name ?? '').trim();
  final productSku = (sku ?? '').trim();
  final label = productName.isEmpty
      ? 'Produto não encontrado'
      : productSku.isEmpty
      ? productName
      : '$productName ($productSku)';
  return '$label · ${formatId(id)}';
}

/// `Nome (Papel) · #id`.
String personLabel({String? name, String? role, required String id}) {
  final personName = (name ?? '').trim();
  final roleLabel = displayRole(role);
  final label = personName.isEmpty
      ? (roleLabel ?? 'Usuário')
      : roleLabel == null
      ? personName
      : '$personName ($roleLabel)';
  return '$label · ${formatId(id)}';
}

/// Nome do papel em português, para os rótulos de pessoa.
String? displayRole(String? role) => switch (role?.toLowerCase()) {
  'system' => 'Sistema',
  'finance' => 'Financeiro',
  'admin' => 'Administrador',
  'buyer' => 'Comprador',
  'representative' => 'Representante',
  'supervisor' => 'Supervisor',
  _ => role,
};
