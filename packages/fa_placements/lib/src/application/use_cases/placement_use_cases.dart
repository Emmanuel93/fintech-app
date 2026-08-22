import '../../domain/entities/beneficiary.dart';
import '../../domain/entities/bureau_report.dart';
import '../../domain/entities/distributor_line.dart';
import '../../domain/entities/placement.dart';
import '../../domain/ports/i_placement_repository.dart';

/// Casos de uso de colocación.
///
/// Van juntos en un archivo, y no uno por archivo como en los módulos más
/// viejos, porque son envolturas de una línea sobre el mismo puerto: separarlos
/// daría ocho archivos de seis líneas que hay que abrir todos para entender el
/// flujo.

class GetDistributorLineUseCase {
  const GetDistributorLineUseCase(this._repo);
  final IPlacementRepository _repo;
  Future<DistributorLine?> call() => _repo.getLine();
}

class ListPlacementsUseCase {
  const ListPlacementsUseCase(this._repo);
  final IPlacementRepository _repo;
  Future<List<Placement>> call() => _repo.listPlacements();
}

class GetPlacementUseCase {
  const GetPlacementUseCase(this._repo);
  final IPlacementRepository _repo;
  Future<Placement> call(String id) => _repo.getPlacement(id);
}

class CreatePlacementUseCase {
  const CreatePlacementUseCase(this._repo);
  final IPlacementRepository _repo;

  Future<Placement> call({
    required String fullName,
    required String phone,
    required String relationship,
    required double amount,
    required int termFortnights,
  }) =>
      _repo.createPlacement(
        fullName: fullName,
        phone: phone,
        relationship: relationship,
        amount: amount,
        termFortnights: termFortnights,
      );
}

class GetBureauReportUseCase {
  const GetBureauReportUseCase(this._repo);
  final IPlacementRepository _repo;
  Future<BureauReport> call(String id) => _repo.getBureauReport(id);
}

/// Aprobar o no colocar. Es un solo caso de uso porque es una sola decisión con
/// dos salidas, y las dos cierran la colocación.
class DecidePlacementUseCase {
  const DecidePlacementUseCase(this._repo);
  final IPlacementRepository _repo;

  Future<Placement> call(String id, {required bool approve}) =>
      approve ? _repo.approvePlacement(id) : _repo.rejectPlacement(id);
}

class ResendInviteUseCase {
  const ResendInviteUseCase(this._repo);
  final IPlacementRepository _repo;
  Future<Placement> call(String id) => _repo.resendInvite(id);
}

class ListBeneficiariesUseCase {
  const ListBeneficiariesUseCase(this._repo);
  final IPlacementRepository _repo;
  Future<List<Beneficiary>> call() => _repo.listBeneficiaries();
}
