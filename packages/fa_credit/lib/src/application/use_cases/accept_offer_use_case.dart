import '../../domain/entities/credit_application.dart';
import '../../domain/ports/i_credit_repository.dart';

class AcceptOfferUseCase {
  const AcceptOfferUseCase(this._repo);
  final ICreditRepository _repo;
  Future<CreditApplication> call(String applicationId) => _repo.acceptOffer(applicationId);
}
