import '../../domain/entities/auth_user.dart';
import '../../domain/ports/i_auth_repository.dart';

class LoginUseCase {
  const LoginUseCase(this._repository);
  final IAuthRepository _repository;

  Future<AuthUser?> call({required String phone, required String password}) =>
      _repository.login(phone: phone, password: password);
}
