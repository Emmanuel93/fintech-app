import '../../domain/entities/credit_application.dart';
import '../../domain/ports/i_credit_repository.dart';

class SubmitApplicationUseCase {
  const SubmitApplicationUseCase(this._repo);
  final ICreditRepository _repo;

  Future<CreditApplication> call({
    required String prospectId,
    required String productType,
    double? requestedAmount,
    int? requestedTerm,
  }) =>
      _repo.submitApplication(
        prospectId: prospectId,
        productType: productType,
        requestedAmount: requestedAmount,
        requestedTerm: requestedTerm,
      );
}
