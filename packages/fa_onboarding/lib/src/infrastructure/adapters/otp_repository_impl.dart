import 'package:fa_core/fa_core.dart';
import '../../domain/ports/i_otp_repository.dart';

class OtpRepositoryImpl implements IOtpRepository {
  OtpRepositoryImpl({required ApiClient apiClient}) : _client = apiClient;
  final ApiClient _client;

  @override
  Future<bool> send(String phone) async {
    final json = await _client.post('/otp/send', body: {'phone': phone});
    return json['success'] as bool? ?? false;
  }

  @override
  Future<String?> verify(String phone, String code) async {
    final json = await _client.post('/otp/verify', body: {'phone': phone, 'code': code});
    final verified = json['verified'] as bool? ?? false;
    if (!verified) return null;
    return json['preAuthToken'] as String?;
  }

  @override
  Future<bool> resend(String phone) async {
    final json = await _client.post('/otp/resend', body: {'phone': phone});
    return json['success'] as bool? ?? false;
  }
}
