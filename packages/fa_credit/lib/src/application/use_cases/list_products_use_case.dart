import '../../domain/entities/credit_product.dart';
import '../../domain/ports/i_credit_repository.dart';

class ListProductsUseCase {
  const ListProductsUseCase(this._repo);
  final ICreditRepository _repo;
  Future<List<CreditProduct>> call() => _repo.listProducts();
}
