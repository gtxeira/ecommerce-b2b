// ignore_for_file: prefer_initializing_formals
import 'dart:async';

import 'package:ecommerce_b2b/app/core/network/session_events.dart';
import 'package:ecommerce_b2b/modules/identity_access/application/login/login_use_case.dart';
import 'package:ecommerce_b2b/modules/identity_access/model/repositories/auth_repository.dart';
import 'package:ecommerce_b2b/modules/identity_access/model/user_session.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';

part 'auth_state.dart';

class AuthCubit extends Cubit<AuthState> {
  final LoginUseCase _loginUseCase;
  final AuthRepository _authRepository;
  final SessionEvents? _sessionEvents;
  StreamSubscription<void>? _expiredSubscription;

  AuthCubit({
    required LoginUseCase loginUseCase,
    required AuthRepository authRepository,
    SessionEvents? sessionEvents,
  }) : _loginUseCase = loginUseCase,
       _authRepository = authRepository,
       _sessionEvents = sessionEvents,
       super(AuthInitial()) {
    _expiredSubscription = _sessionEvents?.onExpired.listen((_) {
      if (!isClosed) emit(AuthUnauthenticated());
    });
    _checkInitialSession();
  }

  Future<void> _checkInitialSession() async {
    final session = await _authRepository.getCurrentSession();
    if (isClosed || state is! AuthInitial) return;

    if (session != null) {
      emit(AuthAuthenticated(session));
    } else {
      emit(AuthUnauthenticated());
    }
  }

  Future<void> login(String email, String password) async {
    emit(AuthLoading());
    final result = await _loginUseCase.execute(email, password);

    result.fold(
      (error) => emit(AuthFailure(error.message)),
      (session) => emit(AuthAuthenticated(session)),
    );
  }

  Future<void> logout() async {
    emit(AuthLoading());
    await _authRepository.logout();
    if (!isClosed) emit(AuthUnauthenticated());
  }

  @override
  Future<void> close() async {
    await _expiredSubscription?.cancel();
    return super.close();
  }
}
