/// Papel/responsabilidade de um usuário
enum UserRole {
  /// Comprador
  buyer,

  /// Representante
  representative,

  /// Financeiro
  finance,

  /// Supervisor
  supervisor,

  /// Administrador
  admin;

  /// Converte o nome devolvido pela API (PascalCase) para o enum.
  static UserRole? fromApiName(String value) {
    final normalized = value.trim().toLowerCase();
    for (final role in UserRole.values) {
      if (role.name.toLowerCase() == normalized) return role;
    }
    return null;
  }

  /// Nome esperado pela API.
  String get apiName => switch (this) {
    UserRole.buyer => 'Buyer',
    UserRole.representative => 'Representative',
    UserRole.finance => 'Finance',
    UserRole.supervisor => 'Supervisor',
    UserRole.admin => 'Admin',
  };
}
