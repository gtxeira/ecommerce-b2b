import 'package:ecommerce_b2b/app/core/network/api_client.dart';
import 'package:ecommerce_b2b/app/core/network/json_read.dart';
import 'package:ecommerce_b2b/modules/identity_access/domain/enums/user_role.dart';
import 'package:ecommerce_b2b/modules/identity_access/domain/repositories/user_repository.dart';
import 'package:ecommerce_b2b/modules/identity_access/domain/user_account.dart';

class ApiUserRepository implements UserRepository {
  final ApiClient _api;

  ApiUserRepository(this._api);

  @override
  Future<List<UserAccount>> findAll({
    UserRole? role,
    String? companyId,
    bool? active,
    String? search,
  }) async {
    final data = await _api.get(
      '/api/users',
      query: {
        if (role != null) 'role': role.apiName,
        if (companyId != null && companyId.isNotEmpty) 'companyId': companyId,
        if (active != null) 'active': active.toString(),
        if (search != null && search.trim().isNotEmpty) 'search': search.trim(),
      },
    );
    if (data is! List) return const [];
    return data
        .whereType<Map>()
        .map((item) => _fromJson(Map<String, dynamic>.from(item)))
        .toList();
  }

  @override
  Future<UserAccount> create({
    required String fullName,
    required String email,
    required String password,
    required UserRole role,
    String? companyId,
  }) async {
    final data = await _api.post(
      '/api/users',
      data: {
        'fullName': fullName,
        'email': email,
        'password': password,
        'role': role.apiName,
        'companyId': companyId,
      },
    );
    return _fromJson(Map<String, dynamic>.from(data as Map));
  }

  @override
  Future<UserAccount> update({
    required String id,
    required String fullName,
    required UserRole role,
    String? companyId,
    required bool active,
  }) async {
    final data = await _api.patch(
      '/api/users/$id',
      data: {
        'fullName': fullName,
        'active': active,
        'roleAssignment': {'role': role.apiName, 'companyId': companyId},
      },
    );
    return _fromJson(Map<String, dynamic>.from(data as Map));
  }

  @override
  Future<void> resetPassword({
    required String id,
    required String newPassword,
  }) async {
    await _api.post(
      '/api/users/$id/password',
      data: {'newPassword': newPassword},
    );
  }

  UserAccount _fromJson(Map<String, dynamic> json) => UserAccount(
    id: readString(json, 'id'),
    fullName: readString(json, 'fullName'),
    email: readString(json, 'email'),
    role: UserRole.fromApiName(readString(json, 'role')) ?? UserRole.buyer,
    companyId: readNullableString(json, 'companyId'),
    active: readBool(json, 'active', true),
  );
}
