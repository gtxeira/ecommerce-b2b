import 'package:ecommerce_b2b/app/core/errors/app_error.dart';
import 'package:ecommerce_b2b/modules/identity_access/application/login/login_use_case.dart';
import '../../fakes/fake_auth_repository.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late FakeAuthRepository authRepository;
  late LoginUseCase loginUseCase;

  setUp(() {
    authRepository = FakeAuthRepository();
    loginUseCase = LoginUseCase(authRepository);
  });

  group('LoginUseCase', () {
    // Deve realizar o login com sucesso utilizando credenciais de comprador válidas.
    test('should login successfully with valid buyer credentials', () async {
      final result = await loginUseCase.execute(
        'buyer@test.com',
        'password123',
      );

      expect(result.isSuccess, isTrue);
      final session = result.getOrThrow();
      expect(session.isBuyer, isTrue);
    });

    test(
      'should login successfully with valid supervisor credentials',
      () async {
        final result = await loginUseCase.execute(
          'supervisor@test.com',
          'password123',
        );

        expect(result.isSuccess, isTrue);
        final session = result.getOrThrow();
        expect(session.isSupervisor, isTrue);
      },
    );

    // Deve retornar falha para senha inválida.
    test('should return failure for invalid password', () async {
      final result = await loginUseCase.execute(
        'buyer@test.com',
        'wrongpassword',
      );

      expect(result.isFailure, isTrue);
      expect(result.getFailureOrThrow().code, AppErrorCodes.invalidCredentials);
    });

    // Deve retornar falha para email inválido
    test('should return failure for invalid email format', () async {
      final result = await loginUseCase.execute('invalid-email', 'password123');

      expect(result.isFailure, isTrue);
      expect(result.getFailureOrThrow().code, AppErrorCodes.invalidCredentials);
    });
  });
}
