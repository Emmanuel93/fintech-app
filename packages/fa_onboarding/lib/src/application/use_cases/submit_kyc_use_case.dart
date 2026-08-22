import '../../domain/entities/kyc_documents.dart';
import '../../domain/entities/kyc_state.dart';
import '../../domain/ports/i_kyc_repository.dart';

class SubmitKycUseCase {
  const SubmitKycUseCase(this._repository);
  final IKycRepository _repository;

  Future<String> submitApplication(KycState state) =>
      _repository.submitApplication(state);

  Future<String> createAccount({
    required String password,
    required String folioKyc,
    required String preAuthToken,
    String phone = '',
    KycDocuments? documents,
  }) =>
      _repository.createAccount(
        password: password,
        folioKyc: folioKyc,
        preAuthToken: preAuthToken,
        phone: phone,
        documents: documents,
      );
}
