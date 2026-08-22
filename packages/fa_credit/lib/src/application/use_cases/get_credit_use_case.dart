import '../../domain/entities/credit_account.dart';
import '../../domain/ports/i_credit_repository.dart';

class GetCreditUseCase {
  const GetCreditUseCase(this._repo);
  final ICreditRepository _repo;
  Future<CreditAccount?> call() => _repo.getCreditAccount();
}
