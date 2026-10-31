import 'package:ecommerce_b2b/modules/identity_access/domain/enums/user_role.dart';
import 'package:ecommerce_b2b/modules/identity_access/domain/repositories/user_repository.dart';
import 'package:ecommerce_b2b/modules/identity_access/domain/user_account.dart';
import 'package:ecommerce_b2b/modules/identity_access/presentation/cubit/user_management_cubit.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockUserRepository extends Mock implements UserRepository {}

void main() {
  late MockUserRepository repository;
  late UserManagementCubit cubit;

  const user = UserAccount(
    id: 'u1',
    fullName: 'Usuário Teste',
    email: 'user@test.com',
    role: UserRole.buyer,
    companyId: 'c1',
    active: true,
  );

  setUpAll(() {
    registerFallbackValue(UserRole.buyer);
  });

  setUp(() {
    repository = MockUserRepository();
    cubit = UserManagementCubit(repository);
  });

  tearDown(() => cubit.close());

  group('UserManagementCubit', () {
    test('should load users and keep the filters', () async {
      when(
        () => repository.findAll(role: UserRole.buyer, search: 'teste'),
      ).thenAnswer((_) async => [user]);

      await cubit.load(role: UserRole.buyer, search: 'teste');

      final state = cubit.state as UserManagementLoaded;
      expect(state.users, [user]);
      expect(state.role, UserRole.buyer);
      expect(state.search, 'teste');
    });

    test('should emit Failure when the API fails', () async {
      when(() => repository.findAll()).thenThrow(Exception('403'));

      await cubit.load();

      expect(cubit.state, isA<UserManagementFailure>());
    });

    test('should create a user, reload and emit success', () async {
      when(
        () => repository.create(
          fullName: any(named: 'fullName'),
          email: any(named: 'email'),
          password: any(named: 'password'),
          role: any(named: 'role'),
          companyId: any(named: 'companyId'),
        ),
      ).thenAnswer((_) async => user);
      when(() => repository.findAll()).thenAnswer((_) async => [user]);

      await cubit.createUser(
        fullName: 'Usuário Teste',
        email: 'user@test.com',
        password: 'senha1234',
        role: UserRole.buyer,
        companyId: 'c1',
      );

      expect(cubit.state, isA<UserManagementSuccess>());
      verify(() => repository.findAll()).called(1);
    });

    test('should update a user and reload', () async {
      when(
        () => repository.update(
          id: any(named: 'id'),
          fullName: any(named: 'fullName'),
          role: any(named: 'role'),
          companyId: any(named: 'companyId'),
          active: any(named: 'active'),
        ),
      ).thenAnswer((_) async => user);
      when(() => repository.findAll()).thenAnswer((_) async => [user]);

      await cubit.updateUser(
        id: 'u1',
        fullName: 'Novo Nome',
        role: UserRole.buyer,
        companyId: 'c1',
        active: true,
      );

      expect(cubit.state, isA<UserManagementSuccess>());
    });

    test('should reset the password', () async {
      when(
        () => repository.resetPassword(
          id: any(named: 'id'),
          newPassword: any(named: 'newPassword'),
        ),
      ).thenAnswer((_) async {});

      await cubit.resetPassword(id: 'u1', newPassword: 'novaSenha1');

      expect(cubit.state, isA<UserManagementSuccess>());
    });
  });
}
