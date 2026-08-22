import 'package:flutter_test/flutter_test.dart';
import 'package:fa_auth/src/application/use_cases/login_use_case.dart';
import 'package:fa_auth/src/domain/ports/i_auth_repository.dart';
import 'package:fa_auth/src/domain/entities/auth_user.dart';

// ─── Fake repository ──────────────────────────────────────────────────────────

class _FakeAuthRepository implements IAuthRepository {
  _FakeAuthRepository({required this.user});
  final AuthUser? user;

  @override
  Future<AuthUser?> login({required String phone, required String password}) async =>
      user;

  @override
  Future<void> logout() async {}
}

class _ThrowingAuthRepository implements IAuthRepository {
  @override
  Future<AuthUser?> login({required String phone, required String password}) =>
      throw Exception('Network error');

  @override
  Future<void> logout() async {}
}

// ─── Tests ────────────────────────────────────────────────────────────────────

void main() {
  group('LoginUseCase', () {
    test('devuelve el usuario cuando el repositorio acepta las credenciales', () async {
      const user = AuthUser(phone: '6671234567', userId: 'u1', token: 'jwt');
      final useCase = LoginUseCase(_FakeAuthRepository(user: user));
      final result = await useCase(phone: '6671234567', password: 'pass123');
      expect(result, isNotNull);
      expect(result!.token, 'jwt');
    });

    test('devuelve null cuando el repositorio rechaza las credenciales', () async {
      final useCase = LoginUseCase(_FakeAuthRepository(user: null));
      final result = await useCase(phone: '6671234567', password: 'wrong');
      expect(result, isNull);
    });

    test('propaga excepciones del repositorio', () async {
      final useCase = LoginUseCase(_ThrowingAuthRepository());
      expect(
        () => useCase(phone: '6671234567', password: 'pass123'),
        throwsException,
      );
    });
  });
}
