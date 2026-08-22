import 'kyc_status.dart';
import 'personal_data.dart';
import 'ocr_extracted_data.dart';
import 'kyc_documents.dart';

class KycState {
  const KycState({
    this.phone = '',
    this.status = KycStatus.initial,
    this.personalData = const PersonalData(),
    this.documents = const KycDocuments(),
    this.ocrData,
    this.preAuthToken = '',
    this.folioKyc = '',
    this.prospectId = '',
    this.aceptaAvisoPrivacidad = false,
    this.aceptaCirculo = false,
    this.aceptaMarketing = false,
    this.email = '',
  });

  final String phone;
  final KycStatus status;
  final PersonalData personalData;
  final KycDocuments documents;
  final OcrExtractedData? ocrData;

  /// JWT de corta vida emitido por `/otp/verify`. Bearer para OCR/KYC/register.
  final String preAuthToken;
  final String folioKyc;

  /// Id del prospecto creado por `/auth/register` (persona, sin crédito).
  final String prospectId;

  final bool aceptaAvisoPrivacidad;
  final bool aceptaCirculo;

  /// Consentimiento **opcional** de comunicaciones comerciales (Journey L1178).
  final bool aceptaMarketing;

  /// Correo capturado junto con el celular, antes del OTP (Journey L183–L186).
  final String email;

  KycState copyWith({
    String? phone,
    KycStatus? status,
    PersonalData? personalData,
    KycDocuments? documents,
    OcrExtractedData? ocrData,
    String? preAuthToken,
    String? folioKyc,
    String? prospectId,
    bool? aceptaAvisoPrivacidad,
    bool? aceptaCirculo,
    bool? aceptaMarketing,
    String? email,
  }) =>
      KycState(
        phone: phone ?? this.phone,
        status: status ?? this.status,
        personalData: personalData ?? this.personalData,
        documents: documents ?? this.documents,
        ocrData: ocrData ?? this.ocrData,
        preAuthToken: preAuthToken ?? this.preAuthToken,
        folioKyc: folioKyc ?? this.folioKyc,
        prospectId: prospectId ?? this.prospectId,
        aceptaAvisoPrivacidad: aceptaAvisoPrivacidad ?? this.aceptaAvisoPrivacidad,
        aceptaCirculo: aceptaCirculo ?? this.aceptaCirculo,
        aceptaMarketing: aceptaMarketing ?? this.aceptaMarketing,
        email: email ?? this.email,
      );
}
