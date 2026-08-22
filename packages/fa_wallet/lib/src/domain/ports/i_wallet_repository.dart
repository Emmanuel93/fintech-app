import '../entities/wallet_balance.dart';
import '../entities/transaction.dart';

abstract interface class IWalletRepository {
  Future<WalletBalance> getBalance();
  Future<List<Transaction>> getTransactions({int limit = 20});
  Future<bool> sendTransfer({
    required String recipientPhone,
    required double amount,
    required String concept,
  });
}
