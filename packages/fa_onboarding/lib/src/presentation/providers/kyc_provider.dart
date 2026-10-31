import 'package:flutter/material.dart';
import 'package:fa_core/fa_core.dart';
import '../../application/use_cases/extract_ocr_use_case.dart';
import '../../application/use_cases/send_otp_use_case.dart';
import '../../application/use_cases/submit_kyc_use_case.dart';
import '../../application/use_cases/verify_otp_use_case.dart';
import '../../domain/entities/kyc_state.dart';
import '../../domain/entities/document_file.dart';
import '../../domain/entities/kyc_documents.dart';
import '../../domain/entities/kyc_status.dart';
import '../../domain/entities/ocr_extracted_data.dart';
import '../../domain/services/estado_de_domicilio.dart';
import '../../domain/entities/personal_data.dart';

class KycProvider extends ChangeNotifier with SafeNotifier {
  KycProvider({
    required SendOtpUseCase sendOtp,
    required VerifyOtpUseCase verifyOtp,
    required ExtractOcrUseCase extractOcr,
    required SubmitKycUseCase submitKyc,
  })  : _sendOtp = sendOtp,
        _verifyOtp = verifyOtp,
        _extractOcr = extractOcr,
        _submitKyc = submitKyc;

  final SendOtpUseCase _sendOtp;
  final VerifyOtpUseCase _verifyOtp;
  final ExtractOcrUseCase _extractOcr;
  final SubmitKycUseCase _submitKyc;

  KycState _state = const KycState();
  KycState get state => _state;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _error;
  String? get error => _error;

  void _setLoading(bool v) {
    _isLoading = v;
    notificar();
  }

  void _setError(String? e) {
    _error = e;
    notificar();
  }

  void clearError() {
    _error = null;
    notificar();
  }

  // ── Paso 1: Contacto (celular + correo) ───────────────────────────────────
  //
  // El diseño captura ambos ANTES del consentimiento (Journey L172–L187): el
  // usuario dice a dónde mandarle el código, y sólo después autoriza. Guardarlo
  // aquí (y no al enviar el OTP) permite volver atrás sin perderlo.
  void setContacto({required String phone, required String email}) {
    _state = _state.copyWith(
      phone: phone,
      email: email,
      // El correo también alimenta el formulario de datos, donde se muestra
      // ya lleno bajo "CONTACTO E INGRESO".
      personalData: _state.personalData.copyWith(email: email, celular: phone),
    );
    notificar();
  }

  // ── Paso 2: Consentimientos ───────────────────────────────────────────────
  void setConsents({
    required bool privacidad,
    required bool circulo,
    bool marketing = false,
  }) {
    _state = _state.copyWith(
      aceptaAvisoPrivacidad: privacidad,
      aceptaCirculo: circulo,
      aceptaMarketing: marketing,
    );
    notificar();
  }

  // ── Paso 3: OTP ───────────────────────────────────────────────────────────
  /// Envía el código al celular ya capturado en el paso 1.
  Future<bool> sendOtp([String? phone]) async {
    final target = phone ?? _state.phone;
    if (target.isEmpty) {
      _setError('Falta el número de celular.');
      return false;
    }
    _setLoading(true);
    _setError(null);
    try {
      final ok = await _sendOtp(target);
      if (ok) {
        _state = _state.copyWith(phone: target);
        notificar();
      }
      return ok;
    } catch (_) {
      _setError('Error al enviar el código. Intenta de nuevo.');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> verifyOtp(String code) async {
    _setLoading(true);
    _setError(null);
    try {
      final preAuthToken = await _verifyOtp(_state.phone, code);
      if (preAuthToken != null) {
        _state = _state.copyWith(
          status: KycStatus.phoneVerified,
          preAuthToken: preAuthToken,
        );
        // El celular verificado lo necesita la firma del contrato, en otro
        // módulo, para mostrarlo enmascarado.
        AppSession.instance.phone = _state.phone;
        notificar();
        return true;
      }
      _setError('Código incorrecto. Verifica e intenta de nuevo.');
      return false;
    } catch (_) {
      _setError('Error de verificación. Intenta de nuevo.');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> resendOtp() async {
    // Delegate directly — resend shares the OTP port
    try {
      return await _sendOtp(_state.phone);
    } catch (_) {
      return false;
    }
  }

  // ── Paso 2: Documentos (INE, selfie, comprobante) ─────────────────────────

  /// `true` mientras corre el OCR, para que la pestaña de documentos pueda
  /// mostrar el spinner sin bloquear toda la pantalla con el overlay.
  bool _isOcrRunning = false;
  bool get isOcrRunning => _isOcrRunning;

  /// Guarda un documento capturado. Cuando quedan listos frente **y** reverso,
  /// dispara el OCR solo: el diseño apalanca el llenado de la pestaña Datos en
  /// esa extracción, así que no tiene sentido pedirle al usuario que la lance.
  Future<void> setDocument(KycDocumentKind kind, DocumentFile file) async {
    _state = _state.copyWith(documents: _state.documents.withDocument(kind, file));
    notificar();

    if (kind.feedsOcr && _state.documents.canRunOcr && _state.ocrData == null) {
      await processOcr();
    }
  }

  void removeDocument(KycDocumentKind kind) {
    _state = _state.copyWith(documents: _state.documents.without(kind));
    notificar();
  }

  bool get documentsComplete => _state.documents.isComplete;

  Future<OcrExtractedData?> processOcr() async {
    final docs = _state.documents;
    if (!docs.canRunOcr) return null;
    _isOcrRunning = true;
    _setError(null);
    try {
      final ocr = await _extractOcr(
        frente: docs[KycDocumentKind.ineFrente]!,
        reverso: docs[KycDocumentKind.ineReverso]!,
      );
      // El OCR es la fuente del prellenado: se vuelca sobre `personalData`
      // respetando lo que el usuario ya hubiera escrito a mano.
      _state = _state.copyWith(
        ocrData: ocr,
        status: KycStatus.ineUploaded,
        personalData: _mergeOcr(_state.personalData, ocr),
      );
      return ocr;
    } catch (_) {
      _setError('No pudimos leer tu INE. Vuelve a capturar las fotos.');
      return null;
    } finally {
      _isOcrRunning = false;
      notificar();
    }
  }

  /// Vuelca el OCR sobre los datos personales **sin pisar** lo ya capturado.
  static PersonalData _mergeOcr(PersonalData current, OcrExtractedData ocr) {
    DateTime? fecha = current.fechaNacimiento;
    if (fecha == null && ocr.fechaNacimiento.isNotEmpty) {
      final parts = ocr.fechaNacimiento.split('/');
      if (parts.length == 3) {
        final d = int.tryParse(parts[0]);
        final m = int.tryParse(parts[1]);
        final y = int.tryParse(parts[2]);
        if (d != null && m != null && y != null) fecha = DateTime(y, m, d);
      }
    }
    String pick(String mine, String fromOcr) => mine.isNotEmpty ? mine : fromOcr;

    return current.copyWith(
      nombres: pick(current.nombres, ocr.nombres),
      apellidoPaterno: pick(current.apellidoPaterno, ocr.apellidoPaterno),
      apellidoMaterno: pick(current.apellidoMaterno, ocr.apellidoMaterno),
      curp: pick(current.curp, ocr.curp),
      genero: pick(current.genero, ocr.genero),
      estadoNacimiento: pick(current.estadoNacimiento, ocr.estadoNacimiento),
      // El estado del domicilio también viene en la INE, dentro de la dirección.
      estado: pick(current.estado, estadoDesdeDomicilio(ocr.domicilio)),
      fechaNacimiento: fecha,
    );
  }

  void confirmOcrData(PersonalData confirmed) {
    _state = _state.copyWith(
        personalData: confirmed, status: KycStatus.ocrVerified);
    notificar();
  }

  // ── Paso 3: Datos personales ──────────────────────────────────────────────
  void savePersonalData(PersonalData data) {
    _state = _state.copyWith(
        personalData: data, status: KycStatus.personalDataComplete);
    notificar();
  }

  // ── Paso 5: Contraseña ────────────────────────────────────────────────────
  //
  // La contraseña se captura en una pantalla y se usa en la siguiente (el
  // análisis), que es la que crea la cuenta. Vive aquí en medio, no en la ruta.
  String _stagedPassword = '';
  String get stagedPassword => _stagedPassword;

  void stagePassword(String password) => _stagedPassword = password;

  // ── Paso 4: Password + Submit ─────────────────────────────────────────────
  // El alta crea SÓLO el prospecto (persona + identidad + consentimientos).
  // Los comprobantes de ingreso/domicilio son documentos por-producto y viven
  // en el flujo de aplicación de crédito (fa_credit), no aquí.
  Future<bool> submitAndCreateAccount(String password) async {
    _setLoading(true);
    _setError(null);
    try {
      final folio = await _submitKyc.submitApplication(_state);
      final prospectId = await _submitKyc.createAccount(
        password: password,
        folioKyc: folio,
        preAuthToken: _state.preAuthToken,
        // Para dejar la sesión iniciada: el alta no devuelve token.
        phone: _state.phone,
        // El expediente sube con el alta. Hasta aquí las fotos sólo existían en
        // memoria del teléfono: el analista veía «INE · frente · capturada» y no
        // tenía nada que abrir para decidir.
        documents: _state.documents,
      );
      _state = _state.copyWith(
        folioKyc: folio,
        prospectId: prospectId,
        status: KycStatus.submitted,
      );
      // Comparte con el resto de la app lo que el flujo de crédito necesita:
      // el prospecto para crear la solicitud, y el titular para el clausulado
      // del contrato, que se arma en otro módulo.
      AppSession.instance.prospectId = prospectId;
      AppSession.instance.holderName = _state.personalData.nombreCompleto;
      AppSession.instance.holderCurp = _state.personalData.curp;
      notificar();
      return true;
    } catch (_) {
      _setError('Error al crear tu cuenta. Intenta de nuevo.');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  void reset() {
    _stagedPassword = '';
    _state = const KycState();
    _isLoading = false;
    _error = null;
    notificar();
  }
}
