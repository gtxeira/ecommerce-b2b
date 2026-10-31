import 'package:ecommerce_b2b/app/core/errors/app_error.dart';
import 'package:ecommerce_b2b/app/core/network/session_events.dart';
import 'package:ecommerce_b2b/modules/identity_access/application/login/login_use_case.dart';
import 'package:ecommerce_b2b/modules/identity_access/domain/enums/user_role.dart';
import 'package:ecommerce_b2b/modules/identity_access/domain/repositories/auth_repository.dart';
import 'package:ecommerce_b2b/modules/identity_access/domain/user_session.dart';
import 'package:ecommerce_b2b/modules/identity_access/presentation/cubit/auth_cubit.dart';
import 'package:ecommerce_b2b/modules/shared_kernel/domain/common/ids/company_id.dart';
import 'package:ecommerce_b2b/modules/shared_kernel/domain/common/ids/user_id.dart';
import 'package:ecommerce_b2b/modules/shared_kernel/domain/contact/value_objects/email_address.dart';
import 'package:ecommerce_b2b/app/core/result/result.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockLoginUseCase extends Mock implements LoginUseCase {}

class _FakeAuthRepository implements AuthRepository {
  UserSession? session;
  int logoutCalls = 0;

  _FakeAuthRepository(this.session);

  @override
  Future<UserSession?> getCurrentSession() async => session;

  @override
  Future<Result<UserSession, AppError>> login(
    EmailAddress email,
    String password,
  ) async => session == null
      ? Failure(
          const AppError(
            AppErrorCodes.invalidCredentials,
            'E-mail ou senha inválidos.',
          ),
        )
      : Success(session!);

  @override
  Future<void> logout() async {
    logoutCalls++;
    session = null;
  }
}

void main() {
  late MockLoginUseCase loginUseCase;
  late SessionEvents sessionEvents;
  late _FakeAuthRepository authRepository;

  final buyerSession = UserSession(
    userId: const UserId('buyer-1'),
    role: UserRole.buyer,
    companyId: const CompanyId('c1'),
  );

  AuthCubit buildCubit() => AuthCubit(
    loginUseCase: loginUseCase,
    authRepository: authRepository,
    sessionEvents: sessionEvents,
  );

  setUp(() {
    loginUseCase = MockLoginUseCase();
    sessionEvents = SessionEvents();
    authRepository = _FakeAuthRepository(null);
  });

  tearDown(() async {
    await sessionEvents.dispose();
  });

  group('AuthCubit', () {
    test(
      'should emit Unauthenticated when there is no persisted session',
      () async {
        final cubit = buildCubit();
        await Future<void>.delayed(Duration.zero);

        expect(cubit.state, isA<AuthUnauthenticated>());
        await cubit.close();
      },
    );

    test('should restore a persisted session', () async {
      authRepository.session = buyerSession;
      final cubit = buildCubit();
      await Future<void>.delayed(Duration.zero);

      expect(cubit.state, isA<AuthAuthenticated>());
      expect((cubit.state as AuthAuthenticated).session, buyerSession);
      await cubit.close();
    });

    test('should emit Loading and Authenticated on successful login', () async {
      when(
        () => loginUseCase.execute(any(), any()),
      ).thenAnswer((_) async => Success(buyerSession));
      final cubit = buildCubit();
      await Future<void>.delayed(Duration.zero);

      final states = <AuthState>[];
      final subscription = cubit.stream.listen(states.add);

      await cubit.login('buyer@test.com', 'password123');
      await Future<void>.delayed(Duration.zero);

      expect(states, [isA<AuthLoading>(), isA<AuthAuthenticated>()]);
      await subscription.cancel();
      await cubit.close();
    });

    test('should emit AuthFailure when credentials are invalid', () async {
      when(() => loginUseCase.execute(any(), any())).thenAnswer(
        (_) async => Failure(
          const AppError(
            AppErrorCodes.invalidCredentials,
            'E-mail ou senha inválidos.',
          ),
        ),
      );
      final cubit = buildCubit();
      await Future<void>.delayed(Duration.zero);

      await cubit.login('buyer@test.com', 'x');

      expect(cubit.state, isA<AuthFailure>());
      expect(
        (cubit.state as AuthFailure).message,
        'E-mail ou senha inválidos.',
      );
      await cubit.close();
    });

    test('should force logout when the session expires elsewhere', () async {
      authRepository.session = buyerSession;
      final cubit = buildCubit();
      await Future<void>.delayed(Duration.zero);
      expect(cubit.state, isA<AuthAuthenticated>());

      sessionEvents.notifyExpired();
      await Future<void>.delayed(Duration.zero);

      expect(cubit.state, isA<AuthUnauthenticated>());
      await cubit.close();
    });

    test('should clear the repository session on logout', () async {
      authRepository.session = buyerSession;
      final cubit = buildCubit();
      await Future<void>.delayed(Duration.zero);

      await cubit.logout();

      expect(cubit.state, isA<AuthUnauthenticated>());
      expect(authRepository.logoutCalls, 1);
      await cubit.close();
    });
  });
}
