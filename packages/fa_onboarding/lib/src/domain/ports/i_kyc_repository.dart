import '../entities/kyc_documents.dart';
import '../entities/kyc_state.dart';

abstract interface class IKycRepository {
  /// Almacena los datos KYC del prospecto → devuelve `folioKyc`.
  Future<String> submitApplication(KycState state);

  /// Crea las credenciales y da de alta al prospecto (persona, sin crédito).
  /// Devuelve el `prospectId`.
  ///
  /// [documents] viaja en la misma petición porque es el único momento en que
  /// existen a la vez los archivos —que hasta aquí sólo vivían en el teléfono— y
  /// la autorización para asociarlos: el `preAuthToken` de un solo tramo. El alta
  /// no falla si un documento no entra; lo que falte se vuelve a pedir.
  Future<String> createAccount({
    required String password,
    required String folioKyc,
    required String preAuthToken,
    String phone,
    KycDocuments? documents,
  });
}
