part of 'user_management_cubit.dart';

abstract class UserManagementState extends Equatable {
  const UserManagementState();

  @override
  List<Object?> get props => [];
}

class UserManagementInitial extends UserManagementState {}

class UserManagementLoading extends UserManagementState {}

class UserManagementLoaded extends UserManagementState {
  final List<UserAccount> users;
  final UserRole? role;
  final bool? active;
  final String? search;

  const UserManagementLoaded({
    required this.users,
    this.role,
    this.active,
    this.search,
  });

  @override
  List<Object?> get props => [users, role, active, search];
}

class UserManagementSuccess extends UserManagementState {
  final String message;
  const UserManagementSuccess(this.message);

  @override
  List<Object?> get props => [message];
}

class UserManagementFailure extends UserManagementState {
  final String message;
  const UserManagementFailure(this.message);

  @override
  List<Object?> get props => [message];
}
