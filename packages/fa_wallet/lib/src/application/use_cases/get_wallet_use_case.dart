import '../../domain/entities/wallet_balance.dart';
import '../../domain/ports/i_wallet_repository.dart';

class GetWalletUseCase {
  const GetWalletUseCase(this._repo);
  final IWalletRepository _repo;
  Future<WalletBalance> call() => _repo.getBalance();
}
