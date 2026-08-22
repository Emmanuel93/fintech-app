import 'package:fa_core/fa_core.dart';
import '../../domain/entities/auth_user.dart';
import '../../domain/ports/i_auth_repository.dart';

class AuthRepositoryImpl implements IAuthRepository {
  AuthRepositoryImpl({required ApiClient apiClient}) : _client = apiClient;

  final ApiClient _client;

  @override
  Future<AuthUser?> login({required String phone, required String password}) async {
    final json = await _client.post('/auth/login', body: {
      'phone': phone,
      'password': password,
      // El BFF/identity vincula la sesión a un dispositivo. Estable por usuario.
      'deviceId': 'mobile-app-$phone',
    });
    // Contrato real del BFF: { accessToken, refreshToken, expiresIn, tokenType }.
    // Fallback a `token` para compatibilidad con el interceptor mock.
    final token = (json['accessToken'] ?? json['token']) as String? ?? '';
    if (token.isEmpty) return null;
    final user = AuthUser(
      phone: phone,
      userId: json['userId'] as String? ?? '',
      token: token,
      refreshToken: json['refreshToken'] as String?,
      expiresIn: json['expiresIn'] as int?,
    );
    _client.setBearerToken(token);
    return user;
  }

  @override
  Future<void> logout() async {
    await _client.post('/auth/logout');
    _client.setBearerToken(null);
  }
}
