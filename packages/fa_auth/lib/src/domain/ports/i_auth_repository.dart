import '../entities/auth_user.dart';

abstract interface class IAuthRepository {
  Future<AuthUser?> login({required String phone, required String password});
  Future<void> logout();
}
