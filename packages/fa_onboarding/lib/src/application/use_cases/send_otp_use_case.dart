import '../../domain/ports/i_otp_repository.dart';

class SendOtpUseCase {
  const SendOtpUseCase(this._repository);
  final IOtpRepository _repository;

  Future<bool> call(String phone) => _repository.send(phone);
}
