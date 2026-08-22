import '../../domain/entities/prequalified_product.dart';
import '../../domain/ports/i_credit_repository.dart';

class ListPrequalifiedProductsUseCase {
  const ListPrequalifiedProductsUseCase(this._repo);
  final ICreditRepository _repo;
  Future<List<PrequalifiedProduct>> call() => _repo.listPrequalifiedProducts();
}
