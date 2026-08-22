import 'package:fa_core/fa_core.dart';
import '../../domain/entities/transaction.dart';
import '../../domain/entities/wallet_balance.dart';
import '../../domain/ports/i_wallet_repository.dart';
import '../dtos/transaction_dto.dart';
import '../dtos/wallet_balance_dto.dart';

class WalletRepositoryImpl implements IWalletRepository {
  WalletRepositoryImpl({required ApiClient apiClient}) : _client = apiClient;

  final ApiClient _client;

  @override
  Future<WalletBalance> getBalance() async {
    final json = await _client.get('/wallet/balance');
    return WalletBalanceDto.fromJson(json).toDomain();
  }

  @override
  Future<List<Transaction>> getTransactions({int limit = 20}) async {
    final json = await _client.get(
      '/wallet/transactions',
      queryParams: {'limit': limit},
    );
    final list = json['transactions'] as List<dynamic>;
    return list
        .map((e) => TransactionDto.fromJson(e as Map<String, dynamic>).toDomain())
        .take(limit)
        .toList();
  }

  @override
  Future<bool> sendTransfer({
    required String recipientPhone,
    required double amount,
    required String concept,
  }) async {
    final json = await _client.post('/wallet/transfer', body: {
      'recipientPhone': recipientPhone,
      'amount': amount,
      'concept': concept,
    });
    return json['success'] as bool? ?? false;
  }
}
