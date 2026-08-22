import 'dart:convert';

import 'package:fa_core/fa_core.dart';
import '../../domain/entities/kyc_documents.dart';
import '../../domain/entities/kyc_state.dart';
import '../../domain/ports/i_kyc_repository.dart';

class KycRepositoryImpl implements IKycRepository {
  KycRepositoryImpl({required ApiClient apiClient}) : _client = apiClient;
  final ApiClient _client;

  Map<String, String> _bearer(String preAuthToken) =>
      {'Authorization': 'Bearer $preAuthToken'};

  @override
  Future<String> submitApplication(KycState state) async {
    final pd = state.personalData;
    final body = <String, dynamic>{
      'phone': state.phone,
      'nombres': pd.nombres,
      'apellidoPaterno': pd.apellidoPaterno,
      'curp': pd.curp,
      'fechaNacimiento': pd.fechaNacimiento != null
          ? '${pd.fechaNacimiento!.year.toString().padLeft(4, '0')}'
            '-${pd.fechaNacimiento!.month.toString().padLeft(2, '0')}'
            '-${pd.fechaNacimiento!.day.toString().padLeft(2, '0')}'
          : null,
      'genero': pd.genero,
      'estadoNacimiento': pd.estadoNacimiento,
      // Domicilio estructurado (el BFF lo prefiere sobre el parse del OCR).
      'calle': pd.calle,
      'numeroExterior': pd.numeroExterior,
      'colonia': pd.colonia,
      'ciudad': pd.ciudad,
      'estado': pd.estado,
      'codigoPostal': pd.codigoPostal,
      'aceptaAvisoPrivacidad': state.aceptaAvisoPrivacidad,
      'aceptaCirculo': state.aceptaCirculo,
    };
    if (pd.apellidoMaterno.isNotEmpty) body['apellidoMaterno'] = pd.apellidoMaterno;
    if (pd.rfc.isNotEmpty) body['rfc'] = pd.rfc;
    if (pd.email.isNotEmpty) body['email'] = pd.email;
    if (pd.numeroInterior.isNotEmpty) body['numeroInterior'] = pd.numeroInterior;
    if (pd.municipio.isNotEmpty) body['municipio'] = pd.municipio;
    // Fallback: si no se capturó domicilio estructurado, manda el string del OCR.
    if (pd.calle.isEmpty &&
        state.ocrData != null &&
        state.ocrData!.domicilio.isNotEmpty) {
      body['domicilio'] = state.ocrData!.domicilio;
    }
    final json = await _client.post(
      '/kyc/submit',
      body: body,
      headers: _bearer(state.preAuthToken),
    );
    return json['folioKyc'] as String? ?? 'KYC-000000';
  }

  @override
  Future<String> createAccount({
    required String password,
    required String folioKyc,
    required String preAuthToken,
    String phone = '',
    KycDocuments? documents,
  }) async {
    final json = await _client.post(
      '/auth/register',
      body: {
        'folioKyc': folioKyc,
        'password': password,
        if (documents != null && documents.files.isNotEmpty)
          'documents': _documentsPayload(documents),
      },
      headers: _bearer(preAuthToken),
    );
    // El BFF serializa el id del prospecto bajo la clave "userId" en
    // RegisterResponse (channel-mobile-service), no "prospectId" — el valor
    // es el mismo prospectId de origination-service, solo cambia el nombre
    // del campo JSON. Se acepta "prospectId" como fallback por si el
    // contrato cambia.
    final prospectId =
        (json['userId'] ?? json['prospectId']) as String? ?? '';

    // `/auth/register` **no devuelve token**: sólo confirma el alta. Sin
    // iniciar sesión aquí, todo lo que sigue —productos, precalificación,
    // solicitud, cuenta— saldría 401 recién creada la cuenta, que es
    // justamente cuando el usuario entra por primera vez. En el flavor mock no
    // se nota porque el interceptor responde sin mirar el token.
    await _signIn(phone: phone, password: password);
    return prospectId;
  }

  /// El expediente, en el vocabulario de origination.
  ///
  /// La app nombra los documentos para que una persona los entienda («INE ·
  /// frente»); el dominio los nombra para relacionarlos entre servicios. La
  /// traducción vive aquí, en el borde, y no en la entidad: cambiar el nombre de
  /// una pantalla no debería tocar el contrato.
  static List<Map<String, String>> _documentsPayload(KycDocuments docs) {
    const tipos = <KycDocumentKind, String>{
      KycDocumentKind.ineFrente: 'INE_FRONT',
      KycDocumentKind.ineReverso: 'INE_BACK',
      KycDocumentKind.selfie: 'SELFIE',
      KycDocumentKind.comprobanteDomicilio: 'ADDRESS_PROOF',
    };
    return [
      for (final entry in docs.files.entries)
        if (tipos[entry.key] != null)
          {
            'documentType': tipos[entry.key]!,
            'fileName': entry.value.fileName,
            'contentType': _mimeOf(entry.value.fileName),
            'contentBase64': base64Encode(entry.value.bytes),
          },
    ];
  }

  /// El tipo se deduce de la extensión: `image_picker` devuelve el nombre del
  /// archivo original y no su MIME, y el visor del backoffice necesita saber si
  /// pintar una imagen o delegar en el navegador.
  static String _mimeOf(String fileName) {
    final ext = fileName.toLowerCase().split('.').last;
    return switch (ext) {
      'png' => 'image/png',
      'heic' || 'heif' => 'image/heic',
      'pdf' => 'application/pdf',
      _ => 'image/jpeg',
    };
  }

  /// Deja la sesión lista tras el alta. Falla en silencio a propósito: la
  /// cuenta ya quedó creada y bloquear el alta por esto sería peor — el
  /// usuario puede entrar desde el login, que es el camino normal.
  /// Inicia sesión con la cuenta recién creada, **reintentando**.
  ///
  /// `/auth/register` deja el alta hecha, pero la credencial con la que se
  /// entra la crea identity al consumir el evento del alta: entre una cosa y
  /// otra hay un instante en que la cuenta existe y todavía no se puede usar.
  /// Un solo intento cae justo en esa ventana y el primer login de la vida del
  /// usuario devuelve 401 — que en pantalla se ve como un análisis que falla
  /// sin explicar por qué, con la cuenta ya creada.
  ///
  /// Se reintenta con espera creciente y un tope: si de verdad no se puede
  /// entrar, el usuario tiene el login de siempre y su cuenta ya existe.
  Future<void> _signIn({required String phone, required String password}) async {
    if (phone.isEmpty) return;

    const delays = [
      Duration(milliseconds: 400),
      Duration(seconds: 1),
      Duration(seconds: 2),
      Duration(seconds: 3),
      Duration(seconds: 4),
    ];

    for (var attempt = 0; attempt <= delays.length; attempt++) {
      try {
        final json = await _client.post(
          '/auth/login',
          body: {'phone': phone, 'password': password},
        );
        final token = (json['token'] ?? json['accessToken']) as String? ?? '';
        if (token.isNotEmpty) {
          _client.setBearerToken(token);
          return;
        }
      } catch (_) {
        // 401 mientras la credencial no existe todavía: es esperado en los
        // primeros intentos y no hay nada que reportar.
      }
      if (attempt < delays.length) {
        await Future<void>.delayed(delays[attempt]);
      }
    }
    // Sin sesión tras todos los intentos: el usuario entra por el login.
  }
}
