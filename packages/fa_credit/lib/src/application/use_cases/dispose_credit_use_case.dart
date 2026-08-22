import '../../domain/ports/i_credit_repository.dart';

class DisposeCreditUseCase {
  const DisposeCreditUseCase(this._repo);
  final ICreditRepository _repo;
  Future<bool> call({required double amount}) => _repo.dispose(amount: amount);
}
