import '../entities/credit_account.dart';
import '../entities/credit_product.dart';
import '../entities/credit_application.dart';
import '../entities/prequalified_product.dart';

abstract interface class ICreditRepository {
  /// Cuenta de crédito activa, o `null` si el prospecto aún no tiene crédito.
  Future<CreditAccount?> getCreditAccount();

  /// Todas las cuentas del prospecto (vigentes e históricas) — para el tab
  /// "Créditos" del home. El BFF ya las devuelve sin filtrar por estado.
  Future<List<CreditAccount>> listCreditAccounts();
  Future<bool> makePayment({required double amount});

  /// Dispara un endpoint de soporte del BFF (`/internal/test-support/*`).
  ///
  /// Existe para las pruebas E2E: correr el devengo, disparar el corte o mover
  /// un vencimiento sin esperar días en tiempo real. En QA y producción esos
  /// endpoints están apagados por configuración del BFF, así que llamarlos
  /// devuelve 404 y no hay forma de usarlos desde la app instalada.
  Future<bool> runTestSupport(String path, {Map<String, dynamic>? query});
  Future<bool> dispose({required double amount});

  // ── Flujo de aplicación de crédito (ADR-001) ──────────────────────────────
  Future<List<CreditProduct>> listProducts();

  /// Créditos B2C preaprobados para el usuario autenticado (home "créditos
  /// disponibles"). El BFF resuelve el prospecto del JWT, no hace falta pasarlo.
  Future<List<PrequalifiedProduct>> listPrequalifiedProducts();
  Future<CreditApplication> submitApplication({
    required String prospectId,
    required String productType,
    double? requestedAmount,
    int? requestedTerm,
  });
  Future<CreditApplication> getApplication(String applicationId);

  // ── Oferta y contrato ──────────────────────────────────────────────────────
  Future<CreditApplication> presentOffer(String applicationId);
  Future<CreditApplication> acceptOffer(String applicationId);
  Future<CreditApplication> generateContract(String applicationId);
  Future<CreditApplication> signContract({
    required String applicationId,
    required String clabeAccount,
    required String signatureProof,
  });
}
