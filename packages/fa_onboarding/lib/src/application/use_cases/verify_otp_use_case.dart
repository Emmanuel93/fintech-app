import '../../domain/ports/i_otp_repository.dart';

class VerifyOtpUseCase {
  const VerifyOtpUseCase(this._repository);
  final IOtpRepository _repository;

  Future<String?> call(String phone, String code) =>
      _repository.verify(phone, code);
}
