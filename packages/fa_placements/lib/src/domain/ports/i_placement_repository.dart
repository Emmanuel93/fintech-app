import '../entities/beneficiary.dart';
import '../entities/bureau_report.dart';
import '../entities/distributor_line.dart';
import '../entities/placement.dart';

/// Puerto del dominio de colocación.
///
/// Cada método corresponde uno a uno con un endpoint del BFF propuesto en
/// `docs/KREDIUS_COLOCACION_PLAN.md` §6. Hoy lo resuelve un interceptor mock;
/// conectar es cambiar el interceptor, no esta interfaz.
abstract interface class IPlacementRepository {
  /// `GET /distributor/line-summary` — `null` si el titular no tiene línea de
  /// colocación (no es un error: es el caso de quien pidió para sí).
  Future<DistributorLine?> getLine();

  /// `GET /placements`
  Future<List<Placement>> listPlacements();

  /// `GET /placements/{id}`
  Future<Placement> getPlacement(String id);

  /// `POST /placements` — crea la colocación y manda la liga al beneficiario.
  /// No descuenta línea todavía (L1375).
  Future<Placement> createPlacement({
    required String fullName,
    required String phone,
    required String relationship,
    required double amount,
    required int termFortnights,
  });

  /// `POST /placements/{id}/resend`
  Future<Placement> resendInvite(String id);

  /// `POST /placements/{id}/cancel`
  Future<Placement> cancelPlacement(String id);

  /// `GET /placements/{id}/bureau` — sólo tiene sentido con la colocación en
  /// `bureauReady`.
  Future<BureauReport> getBureauReport(String id);

  /// `POST /placements/{id}/approve` — el distribuidor asume el riesgo y se
  /// dispara la disposición a tercero.
  Future<Placement> approvePlacement(String id);

  /// `POST /placements/{id}/reject`
  Future<Placement> rejectPlacement(String id);

  /// `GET /beneficiaries`
  Future<List<Beneficiary>> listBeneficiaries();
}
