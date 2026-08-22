import '../../domain/ports/i_wallet_repository.dart';

class SendTransferUseCase {
  const SendTransferUseCase(this._repo);
  final IWalletRepository _repo;
  Future<bool> call({
    required String recipientPhone,
    required double amount,
    required String concept,
  }) =>
      _repo.sendTransfer(
          recipientPhone: recipientPhone, amount: amount, concept: concept);
}
