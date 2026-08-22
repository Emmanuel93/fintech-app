import '../../domain/entities/transaction.dart';
import '../../domain/ports/i_wallet_repository.dart';

class GetTransactionsUseCase {
  const GetTransactionsUseCase(this._repo);
  final IWalletRepository _repo;
  Future<List<Transaction>> call({int limit = 20}) =>
      _repo.getTransactions(limit: limit);
}
