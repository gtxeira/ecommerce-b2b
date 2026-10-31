import 'package:ecommerce_b2b/modules/identity_access/model/enums/user_role.dart';
import 'package:ecommerce_b2b/modules/identity_access/model/repositories/user_repository.dart';
import 'package:ecommerce_b2b/modules/identity_access/model/user_account.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

part 'user_management_state.dart';

class UserManagementCubit extends Cubit<UserManagementState> {
  final UserRepository _repository;

  UserManagementCubit(this._repository) : super(UserManagementInitial());

  Future<void> load({UserRole? role, bool? active, String? search}) async {
    emit(UserManagementLoading());
    try {
      final users = await _repository.findAll(
        role: role,
        active: active,
        search: search,
      );
      emit(
        UserManagementLoaded(
          users: users,
          role: role,
          active: active,
          search: search,
        ),
      );
    } catch (error) {
      emit(UserManagementFailure(error.toString()));
    }
  }

  Future<void> createUser({
    required String fullName,
    required String email,
    required String password,
    required UserRole role,
    String? companyId,
    String? phone,
    String? positionTitle,
  }) async {
    try {
      await _repository.create(
        fullName: fullName,
        email: email,
        password: password,
        role: role,
        companyId: companyId,
        phone: phone,
        positionTitle: positionTitle,
      );
      await _reload();
      emit(const UserManagementSuccess('Usuário cadastrado com sucesso!'));
    } catch (error) {
      emit(UserManagementFailure(error.toString()));
    }
  }

  Future<void> updateUser({
    required String id,
    required String fullName,
    required UserRole role,
    String? companyId,
    required bool active,
  }) async {
    try {
      await _repository.update(
        id: id,
        fullName: fullName,
        role: role,
        companyId: companyId,
        active: active,
      );
      await _reload();
      emit(const UserManagementSuccess('Usuário atualizado com sucesso!'));
    } catch (error) {
      emit(UserManagementFailure(error.toString()));
    }
  }

  Future<void> resetPassword({
    required String id,
    required String newPassword,
  }) async {
    try {
      await _repository.resetPassword(id: id, newPassword: newPassword);
      emit(const UserManagementSuccess('Senha redefinida com sucesso!'));
    } catch (error) {
      emit(UserManagementFailure(error.toString()));
    }
  }

  Future<void> _reload() async {
    final current = state;
    final role = current is UserManagementLoaded ? current.role : null;
    final active = current is UserManagementLoaded ? current.active : null;
    final search = current is UserManagementLoaded ? current.search : null;
    final users = await _repository.findAll(
      role: role,
      active: active,
      search: search,
    );
    emit(
      UserManagementLoaded(
        users: users,
        role: role,
        active: active,
        search: search,
      ),
    );
  }
}
