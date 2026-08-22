import '../../domain/entities/credit_application.dart';
import '../../domain/ports/i_credit_repository.dart';

class PresentOfferUseCase {
  const PresentOfferUseCase(this._repo);
  final ICreditRepository _repo;
  Future<CreditApplication> call(String applicationId) => _repo.presentOffer(applicationId);
}
