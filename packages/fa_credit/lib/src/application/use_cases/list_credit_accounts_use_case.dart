import '../../domain/entities/credit_account.dart';
import '../../domain/ports/i_credit_repository.dart';

class ListCreditAccountsUseCase {
  const ListCreditAccountsUseCase(this._repo);
  final ICreditRepository _repo;
  Future<List<CreditAccount>> call() => _repo.listCreditAccounts();
}
