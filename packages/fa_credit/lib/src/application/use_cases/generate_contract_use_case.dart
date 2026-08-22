import '../../domain/entities/credit_application.dart';
import '../../domain/ports/i_credit_repository.dart';

class GenerateContractUseCase {
  const GenerateContractUseCase(this._repo);
  final ICreditRepository _repo;
  Future<CreditApplication> call(String applicationId) => _repo.generateContract(applicationId);
}
