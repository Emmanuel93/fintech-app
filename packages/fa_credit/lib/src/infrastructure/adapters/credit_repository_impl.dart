import 'package:dio/dio.dart';
import 'package:fa_core/fa_core.dart';
import '../../domain/entities/identity_not_verified.dart';
import '../../domain/entities/credit_account.dart';
import '../../domain/entities/credit_product.dart';
import '../../domain/entities/credit_application.dart';
import '../../domain/entities/prequalified_product.dart';
import '../../domain/ports/i_credit_repository.dart';
import '../dtos/credit_account_dto.dart';
import '../dtos/credit_product_dto.dart';
import '../dtos/credit_application_dto.dart';
import '../dtos/prequalified_product_dto.dart';

class CreditRepositoryImpl implements ICreditRepository {
  CreditRepositoryImpl({required ApiClient apiClient}) : _client = apiClient;

  final ApiClient _client;

  @override
  Future<CreditAccount?> getCreditAccount() async {
    // El BFF devuelve la lista de cuentas activas del cliente ([] si aún no
    // tiene producto). Tomamos la primera cuenta activa; la app muestra una.
    final list = await _client.getList("/credit/account");
    if (list.isEmpty) return null;
    final first = list.first as Map<String, dynamic>;
    // Una cuenta activa existe aunque creditLimit sea null (productos a plazo /
    // INSTALLMENT no tienen línea). Sólo la ausencia de cuenta ([]) = sin crédito.
    return CreditAccountDto.fromJson(first).toDomain();
  }

  @override
  Future<List<CreditAccount>> listCreditAccounts() async {
    final list = await _client.getList("/credit/account");
    return list
        .cast<Map<String, dynamic>>()
        .map((e) => CreditAccountDto.fromJson(e).toDomain())
        .toList();
  }

  @override
  Future<bool> makePayment({required double amount}) async {
    final json = await _client.post("/credit/payment", body: {'amount': amount});
    return json['success'] as bool? ?? false;
  }

  @override
  Future<bool> dispose({required double amount}) async {
    final json = await _client.post("/credit/dispose", body: {'amount': amount});
    return json['success'] as bool? ?? false;
  }

  @override
  Future<List<CreditProduct>> listProducts() async {
    final json = await _client.get("/credit/products");
    final list = (json['products'] ?? json['items'] ?? json['data']) as List?;
    return (list ?? const [])
        .cast<Map<String, dynamic>>()
        .map((e) => CreditProductDto.fromJson(e).toDomain())
        .toList();
  }

  @override
  Future<List<PrequalifiedProduct>> listPrequalifiedProducts() async {
    // El BFF exige `prospectId` como query param en este endpoint (400 sin
    // él), a diferencia de `/credit/account`, que sí lo resuelve del JWT. Se
    // manda el de la sesión; cuando el BFF unifique el criterio, este
    // parámetro deja de hacer falta y no estorba.
    final prospectId = AppSession.instance.prospectId;
    final json = await _client.get(
      "/credit/prequalification",
      queryParams: prospectId.isEmpty ? null : {'prospectId': prospectId},
    );
    final list = (json['products'] ?? const []) as List;
    return list
        .cast<Map<String, dynamic>>()
        .map((e) => PrequalifiedProductDto.fromJson(e).toDomain())
        .toList();
  }

  @override
  Future<CreditApplication> submitApplication({
    required String prospectId,
    required String productType,
    double? requestedAmount,
    int? requestedTerm,
  }) async {
    try {
      final json = await _client.post("/credit/applications", body: {
        'prospectId': prospectId,
        'productType': productType,
        if (requestedAmount != null) 'requestedAmount': requestedAmount,
        if (requestedTerm != null) 'requestedTerm': requestedTerm,
      });
      return CreditApplicationDto.fromJson(json).toDomain();
    } on DioException catch (e) {
      throw identityGateOf(e) ?? e;
    }
  }

  @override
  Future<CreditApplication> getApplication(String applicationId) async {
    final json = await _client.get("/credit/applications/$applicationId");
    return CreditApplicationDto.fromJson(json).toDomain();
  }

  @override
  Future<CreditApplication> presentOffer(String applicationId) async {
    final json = await _client.post("/credit/applications/$applicationId/offer");
    return CreditApplicationDto.fromJson(json).toDomain();
  }

  @override
  Future<CreditApplication> acceptOffer(String applicationId) async {
    final json = await _client.post("/credit/applications/$applicationId/offer/accept");
    return CreditApplicationDto.fromJson(json).toDomain();
  }

  @override
  Future<CreditApplication> generateContract(String applicationId) async {
    final json = await _client.post("/credit/applications/$applicationId/contract");
    return CreditApplicationDto.fromJson(json).toDomain();
  }

  @override
  Future<CreditApplication> signContract({
    required String applicationId,
    required String clabeAccount,
    required String signatureProof,
  }) async {
    final json = await _client.post(
      "/credit/applications/$applicationId/contract/sign",
      body: {'clabeAccount': clabeAccount, 'signatureProof': signatureProof},
    );
    return CreditApplicationDto.fromJson(json).toDomain();
  }

  @override
  Future<bool> runTestSupport(String path, {Map<String, dynamic>? query}) async {
    try {
      await _client.post(path, body: const {}, queryParams: query);
      return true;
    } catch (_) {
      // Apagado (QA/producción) o sin permiso: no es un fallo de negocio.
      return false;
    }
  }
}

/// El 422 de la compuerta de identidad, si es eso lo que respondió el BFF.
///
/// Se reconoce por el `type` del ProblemDetail, no por el código: un 422 puede
/// ser también un periodo de espera o un monto fuera de rango, y a cada uno se
/// le dice algo distinto.
IdentityNotVerified? identityGateOf(DioException e) {
  final data = e.response?.data;
  if (e.response?.statusCode != 422 || data is! Map) return null;
  final type = data['type']?.toString() ?? '';
  if (!type.endsWith('ORIGINATION_PERSON_NOT_VERIFIED')) return null;
  return IdentityNotVerified(
    identityStatus: data['identityStatus']?.toString(),
    screeningStatus: data['screeningStatus']?.toString(),
  );
}
