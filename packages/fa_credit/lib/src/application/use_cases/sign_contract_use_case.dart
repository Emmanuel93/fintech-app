import '../../domain/entities/credit_application.dart';
import '../../domain/ports/i_credit_repository.dart';

class SignContractUseCase {
  const SignContractUseCase(this._repo);
  final ICreditRepository _repo;
  Future<CreditApplication> call({
    required String applicationId,
    required String clabeAccount,
    required String signatureProof,
  }) =>
      _repo.signContract(
        applicationId: applicationId,
        clabeAccount: clabeAccount,
        signatureProof: signatureProof,
      );
}
