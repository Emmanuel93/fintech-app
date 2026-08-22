import '../../domain/entities/credit_application.dart';
import '../../domain/ports/i_credit_repository.dart';

class GetApplicationUseCase {
  const GetApplicationUseCase(this._repo);
  final ICreditRepository _repo;
  Future<CreditApplication> call(String applicationId) =>
      _repo.getApplication(applicationId);
}
