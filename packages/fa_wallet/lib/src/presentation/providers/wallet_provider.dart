import 'package:flutter/material.dart';
import '../../application/use_cases/get_wallet_use_case.dart';
import '../../application/use_cases/get_transactions_use_case.dart';
import '../../application/use_cases/send_transfer_use_case.dart';
import '../../domain/entities/wallet_balance.dart';
import '../../domain/entities/transaction.dart';
import 'package:fa_core/fa_core.dart';

class WalletProvider extends ChangeNotifier with SafeNotifier {
  WalletProvider({
    required GetWalletUseCase getWallet,
    required GetTransactionsUseCase getTransactions,
    required SendTransferUseCase sendTransfer,
  })  : _getWallet = getWallet,
        _getTransactions = getTransactions,
        _sendTransfer = sendTransfer;

  final GetWalletUseCase _getWallet;
  final GetTransactionsUseCase _getTransactions;
  final SendTransferUseCase _sendTransfer;

  WalletBalance? wallet;
  List<Transaction> transactions = [];
  bool isLoading = false;
  bool isSending = false;
  String? error;

  Future<void> loadAll() async {
    isLoading = true;
    error = null;
    notificar();
    try {
      final results = await Future.wait([
        _getWallet(),
        _getTransactions(limit: 10),
      ]);
      wallet = results[0] as WalletBalance;
      transactions = results[1] as List<Transaction>;
    } catch (_) {
      error = 'Error al cargar la billetera.';
    } finally {
      isLoading = false;
      notificar();
    }
  }

  Future<void> refresh() async {
    try {
      final results = await Future.wait([
        _getWallet(),
        _getTransactions(limit: 10),
      ]);
      wallet = results[0] as WalletBalance;
      transactions = results[1] as List<Transaction>;
      notificar();
    } catch (_) {}
  }

  /// Called after a credit disposition succeeds — updates balance and
  /// prepends the disposition transaction without hitting the network.
  void applyDisposition({required double amount}) {
    if (wallet == null) return;
    wallet = wallet!.applyCredit(amount);
    transactions = [
      Transaction.disposition(amount: amount),
      ...transactions,
    ];
    notificar();
  }

  Future<bool> sendTransfer({
    required String destination,
    required String destinationType,
    required String bank,
    required String beneficiaryName,
    required double amount,
    required String concept,
  }) async {
    isSending = true;
    error = null;
    notificar();
    try {
      final ok = await _sendTransfer(
        recipientPhone: destination,
        amount: amount,
        concept: concept,
      );
      if (ok) await refresh();
      return ok;
    } catch (_) {
      error = 'Error al procesar la transferencia.';
      return false;
    } finally {
      isSending = false;
      notificar();
    }
  }
}
