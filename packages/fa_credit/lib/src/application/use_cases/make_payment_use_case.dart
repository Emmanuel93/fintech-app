import '../../domain/ports/i_credit_repository.dart';

class MakePaymentUseCase {
  const MakePaymentUseCase(this._repo);
  final ICreditRepository _repo;
  Future<bool> call({required double amount}) => _repo.makePayment(amount: amount);
}
