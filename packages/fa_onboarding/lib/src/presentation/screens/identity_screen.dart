import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'package:fa_design_system/fa_design_system.dart';

import '../../domain/entities/document_file.dart';
import '../../domain/entities/kyc_documents.dart';
import '../../domain/entities/personal_data.dart';
import '../alta_step.dart';
import '../providers/kyc_provider.dart';

/// Pantalla 1 del prototipo — "Cuéntanos de ti" (Journey L161–L229).
///
/// Unifica lo que antes eran tres pantallas sueltas (`ine-capture`,
/// `ocr-review`, `personal-data`) en **una sola con segmented control**, tal
/// como lo resuelve el diseño.
///
/// **El orden de las pestañas está invertido respecto del prototipo**: primero
/// Documentos, después Datos. El propio prototipo lo pide implícitamente
/// (L216: *"Leímos tu INE y llenamos nombre, CURP, fecha de nacimiento y
/// domicilio. Revísalos en la pestaña Datos"*) — el OCR sólo puede apalancar el
/// llenado si los documentos van antes. La pestaña Datos queda **bloqueada**
/// hasta que los cuatro documentos estén capturados.
class IdentityScreen extends StatefulWidget {
  const IdentityScreen({super.key});

  @override
  State<IdentityScreen> createState() => _IdentityScreenState();
}

class _IdentityScreenState extends State<IdentityScreen> {
  static const int _tabDocumentos = 0;
  static const int _tabDatos = 1;

  int _tab = _tabDocumentos;
  final _picker = ImagePicker();
  final _formKey = GlobalKey<FormState>();

  // Controllers de la pestaña Datos.
  final _nombres = TextEditingController();
  final _apPaterno = TextEditingController();
  final _apMaterno = TextEditingController();
  final _curp = TextEditingController();
  final _rfc = TextEditingController();
  final _email = TextEditingController();
  final _celular = TextEditingController();
  final _ingreso = TextEditingController();
  final _calle = TextEditingController();
  final _numExt = TextEditingController();
  final _numInt = TextEditingController();
  final _colonia = TextEditingController();
  final _municipio = TextEditingController();
  final _ciudad = TextEditingController();
  final _cp = TextEditingController();

  DateTime? _fechaNacimiento;
  String _estadoNacimiento = '';
  String _estadoDomicilio = '';
  String _genero = '';

  /// Qué se sincronizó ya desde el provider, para no pisar lo que el usuario
  /// está escribiendo en cada rebuild.
  bool _hydrated = false;

  static const _estados = [
    'Aguascalientes', 'Baja California', 'Baja California Sur',
    'Campeche', 'Chiapas', 'Chihuahua', 'Ciudad de México', 'Coahuila',
    'Colima', 'Durango', 'Estado de México', 'Guanajuato', 'Guerrero',
    'Hidalgo', 'Jalisco', 'Michoacán', 'Morelos', 'Nayarit',
    'Nuevo León', 'Oaxaca', 'Puebla', 'Querétaro', 'Quintana Roo',
    'San Luis Potosí', 'Sinaloa', 'Sonora', 'Tabasco', 'Tamaulipas',
    'Tlaxcala', 'Veracruz', 'Yucatán', 'Zacatecas',
  ];

  @override
  void dispose() {
    for (final c in [
      _nombres, _apPaterno, _apMaterno, _curp, _rfc, _email, _celular,
      _ingreso, _calle, _numExt, _numInt, _colonia, _municipio, _ciudad, _cp,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  /// Copia al formulario lo que el provider tenga (OCR + teléfono del OTP),
  /// respetando lo que el usuario ya escribió.
  void _hydrate(KycProvider provider) {
    final pd = provider.state.personalData;
    void set(TextEditingController c, String v) {
      if (c.text.isEmpty && v.isNotEmpty) c.text = v;
    }

    set(_nombres, pd.nombres);
    set(_apPaterno, pd.apellidoPaterno);
    set(_apMaterno, pd.apellidoMaterno);
    set(_curp, pd.curp);
    set(_rfc, pd.rfc);
    set(_email, pd.email);
    set(_celular, pd.celular.isNotEmpty ? pd.celular : provider.state.phone);
    set(_ingreso, pd.ingresoMensual);
    set(_calle, pd.calle);
    set(_numExt, pd.numeroExterior);
    set(_numInt, pd.numeroInterior);
    set(_colonia, pd.colonia);
    set(_municipio, pd.municipio);
    set(_ciudad, pd.ciudad);
    set(_cp, pd.codigoPostal);

    _fechaNacimiento ??= pd.fechaNacimiento;
    if (_genero.isEmpty) _genero = _normalizeGenero(pd.genero);
    if (_estadoNacimiento.isEmpty && _estados.contains(pd.estadoNacimiento)) {
      _estadoNacimiento = pd.estadoNacimiento;
    }
    if (_estadoDomicilio.isEmpty && _estados.contains(pd.estado)) {
      _estadoDomicilio = pd.estado;
    }
  }

  /// Etiqueta visible del género a partir del código guardado.
  /// Códigos **H / M / X**, los de la CURP y los que valida el BFF.
  ///
  /// Ojo con la trampa: en ese estándar `M` es **Mujer**, no "masculino". La
  /// app mandaba `M` para Masculino y `F` para Femenino, así que el backend
  /// registraba a los hombres como mujeres y rechazaba a las mujeres con
  /// "Género debe ser H, M o X". Se usan los códigos del estándar y las
  /// etiquetas en español sólo para mostrar.
  String? get _generoLabel => switch (_genero) {
        'H' => 'Hombre',
        'M' => 'Mujer',
        'X' => 'No binario',
        _ => null,
      };

  static const _generoOpciones = ['Hombre', 'Mujer', 'No binario'];

  static String _generoCode(String label) => switch (label) {
        'Hombre' => 'H',
        'Mujer' => 'M',
        'No binario' => 'X',
        _ => '',
      };

  /// El OCR devuelve "H"/"M"/"HOMBRE"/"MASCULINO"/"F"… y hay que caer siempre
  /// en H/M/X. "M" a secas se interpreta como Mujer, que es lo que dice la
  /// CURP; "MASCULINO" es lo único que empieza con M y significa hombre.
  static String _normalizeGenero(String raw) {
    final v = raw.trim().toUpperCase();
    if (v.isEmpty) return '';
    if (v.startsWith('MASC') || v.startsWith('H')) return 'H';
    if (v.startsWith('F') || v.startsWith('M')) return 'M';
    if (v.startsWith('X') || v.startsWith('N')) return 'X';
    return '';
  }

  // ── Captura ────────────────────────────────────────────────────────────────

  Future<void> _capture(KycDocumentKind kind) async {
    // La selfie de vida no tiene sentido desde galería: se toma en el momento.
    final source = kind == KycDocumentKind.selfie
        ? ImageSource.camera
        : await _pickSource(kind);
    if (source == null || !mounted) return;

    final file = await _picker.pickImage(
      source: source,
      imageQuality: 85,
      maxWidth: 1920,
      preferredCameraDevice: kind == KycDocumentKind.selfie
          ? CameraDevice.front
          : CameraDevice.rear,
    );
    if (file == null || !mounted) return;

    final bytes = await file.readAsBytes();
    if (!mounted) return;
    await context
        .read<KycProvider>()
        .setDocument(kind, DocumentFile(bytes: bytes, fileName: file.name));
  }

  Future<ImageSource?> _pickSource(KycDocumentKind kind) {
    final ds = context.ds;
    return showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(ds.r(AppRadii.card))),
      ),
      builder: (sheetContext) => SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.fromLTRB(
              ds.gutter, ds.h(14), ds.gutter, ds.h(20)),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: ds.w(40),
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.outlineVariant,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              SizedBox(height: ds.h(20)),
              Text(kind.label, style: AppTextStyles.cardTitle(fontSize: ds.sp(16))),
              SizedBox(height: ds.h(16)),
              _SourceTile(
                icon: Icons.camera_alt_outlined,
                label: 'Tomar foto con la cámara',
                onTap: () => Navigator.pop(sheetContext, ImageSource.camera),
              ),
              SizedBox(height: ds.h(10)),
              _SourceTile(
                icon: Icons.photo_library_outlined,
                label: 'Elegir de la galería',
                onTap: () => Navigator.pop(sheetContext, ImageSource.gallery),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Navegación del paso ────────────────────────────────────────────────────

  void _onCta(KycProvider provider) {
    if (_tab == _tabDocumentos) {
      if (!provider.documentsComplete) return;
      setState(() => _tab = _tabDatos);
      return;
    }
    if (!_formKey.currentState!.validate()) return;
    final missing = _missingSelection();
    if (missing != null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(missing)));
      return;
    }
    provider.savePersonalData(_collect());
    context.go('/onboarding/password');
  }

  String? _missingSelection() {
    if (_fechaNacimiento == null) return 'Selecciona tu fecha de nacimiento';
    if (_genero.isEmpty) return 'Selecciona tu género';
    if (_estadoNacimiento.isEmpty) return 'Selecciona tu estado de nacimiento';
    if (_estadoDomicilio.isEmpty) return 'Selecciona el estado de tu domicilio';
    return null;
  }

  PersonalData _collect() => PersonalData(
        nombres: _nombres.text.trim().toUpperCase(),
        apellidoPaterno: _apPaterno.text.trim().toUpperCase(),
        apellidoMaterno: _apMaterno.text.trim().toUpperCase(),
        fechaNacimiento: _fechaNacimiento,
        curp: _curp.text.trim().toUpperCase(),
        rfc: _rfc.text.trim().toUpperCase(),
        estadoNacimiento: _estadoNacimiento,
        genero: _genero,
        email: _email.text.trim(),
        celular: _celular.text.trim(),
        ingresoMensual: _ingreso.text.trim(),
        calle: _calle.text.trim(),
        numeroExterior: _numExt.text.trim(),
        numeroInterior: _numInt.text.trim(),
        colonia: _colonia.text.trim(),
        municipio: _municipio.text.trim(),
        ciudad: _ciudad.text.trim(),
        estado: _estadoDomicilio,
        codigoPostal: _cp.text.trim(),
      );

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _fechaNacimiento ?? DateTime(1990),
      firstDate: DateTime(1920),
      lastDate: DateTime(now.year - 18, now.month, now.day),
      helpText: 'Fecha de nacimiento',
    );
    if (picked != null) setState(() => _fechaNacimiento = picked);
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final ds = context.ds;
    final provider = context.watch<KycProvider>();
    final complete = provider.documentsComplete;

    if (!_hydrated || provider.state.ocrData != null) {
      _hydrate(provider);
      _hydrated = true;
    }

    // Si el usuario retrocede y borra un documento, no puede quedarse varado
    // en la pestaña Datos.
    if (_tab == _tabDatos && !complete) _tab = _tabDocumentos;

    return Scaffold(
      backgroundColor: AppColors.surfaceVariant,
      body: SafeArea(
        child: DsResponsiveBody(
          child: Column(
            children: [
              // Cabecera fija: no se va con el scroll del formulario largo.
              Padding(
                padding: EdgeInsets.fromLTRB(
                    ds.gutter, ds.topGap, ds.gutter, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    DsOnboardingTopBar(
                      step: AltaStep.identidad.number,
                      total: AltaStep.total,
                      onBack: () => _tab == _tabDatos
                          ? setState(() => _tab = _tabDocumentos)
                          : context.go('/onboarding/otp'),
                    ),
                    SizedBox(height: ds.h(24)),
                    // Título y subtítulo cambian con la pestaña — Journey
                    // L1231–L1234: en Documentos se pide subir, en Datos se
                    // pide revisar lo que el OCR ya leyó.
                    Text(
                      _tab == _tabDocumentos
                          ? 'Sube tus documentos'
                          : 'Confirma que esté bien',
                      style: AppTextStyles.screenTitle(fontSize: ds.sp(27)),
                    ),
                    SizedBox(height: ds.h(6)),
                    Text(
                      _tab == _tabDocumentos
                          ? 'Con tu INE llenamos tus datos automáticamente. Solo '
                              'tendrás que revisarlos.'
                          : 'Esto fue lo que leímos de tu INE y tu comprobante. '
                              'Corrige lo que no cuadre.',
                      style: AppTextStyles.body(fontSize: ds.sp(14)),
                    ),
                    SizedBox(height: ds.h(16)),
                    DsSegmentedTabs(
                      // Invertido respecto del prototipo, a propósito.
                      labels: const ['1 · Documentos', '2 · Verifica tus datos'],
                      index: _tab,
                      enabled: [true, complete],
                      onChanged: (i) {
                        if (i == _tabDatos && !complete) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                  'Primero sube tus documentos: de ahí llenamos tus datos.'),
                            ),
                          );
                          return;
                        }
                        setState(() => _tab = i);
                      },
                    ),
                    SizedBox(height: ds.h(18)),
                  ],
                ),
              ),

              Expanded(
                child: SingleChildScrollView(
                  padding: EdgeInsets.symmetric(horizontal: ds.gutter),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (_tab == _tabDocumentos)
                        _DocumentsTab(
                          provider: provider,
                          onCapture: _capture,
                        )
                      else
                        _buildDatosTab(ds, provider),
                      SizedBox(height: ds.h(18)),
                      const DsInfoBanner(
                        text:
                            'Tus datos viajan cifrados y solo se usan para evaluar esta solicitud.',
                      ),
                      SizedBox(height: ds.h(22)),
                      DsButton(
                        label: _tab == _tabDocumentos
                            ? 'Leer mis documentos'
                            : 'Todo está correcto',
                        onPressed:
                            (_tab == _tabDocumentos && !complete) || provider.isOcrRunning
                                ? null
                                : () => _onCta(provider),
                      ),
                      SizedBox(height: ds.bottomGap(28)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDatosTab(DsScale ds, KycProvider provider) {
    final fmt = DateFormat('dd/MM/yyyy');
    final hasOcr = provider.state.ocrData != null;

    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Journey L1069–L1077 — IDENTIDAD · INE · OCR
          DsFieldGroup(
            title: 'IDENTIDAD',
            source: hasOcr ? 'INE · OCR' : 'CAPTURA MANUAL',
            sourceTone: hasOcr ? DsChipTone.ok : DsChipTone.neutral,
            children: [
              DsFormField(
                label: 'Nombres',
                controller: _nombres,
                hint: 'Como aparece en tu INE',
                textCapitalization: TextCapitalization.words,
                validator: _required,
              ),
              DsFormField(
                label: 'Apellido paterno',
                controller: _apPaterno,
                textCapitalization: TextCapitalization.words,
                validator: _required,
              ),
              DsFormField(
                label: 'Apellido materno',
                controller: _apMaterno,
                textCapitalization: TextCapitalization.words,
                validator: _required,
              ),
              DsFormField(
                label: 'Fecha de nacimiento',
                hint: 'DD/MM/AAAA',
                readOnly: true,
                onTap: _pickDate,
                controller: TextEditingController(
                  text: _fechaNacimiento != null
                      ? fmt.format(_fechaNacimiento!)
                      : '',
                ),
                suffix: Icon(Icons.calendar_today_outlined,
                    size: ds.sp(18), color: AppColors.disabled),
              ),
              DsPickerField(
                label: 'Género',
                options: _generoOpciones,
                value: _generoLabel,
                onChanged: (v) => setState(() => _genero = _generoCode(v)),
                validator: (_) => _genero.isEmpty ? 'Selecciona tu género' : null,
              ),
              DsPickerField(
                label: 'Estado de nacimiento',
                sheetTitle: '¿En qué estado naciste?',
                searchHint: 'Buscar estado',
                options: _estados,
                value: _estadoNacimiento.isEmpty ? null : _estadoNacimiento,
                onChanged: (v) => setState(() => _estadoNacimiento = v),
                validator: (_) =>
                    _estadoNacimiento.isEmpty ? 'Selecciona el estado' : null,
              ),
            ],
          ),
          SizedBox(height: ds.h(18)),

          // Journey L1078–L1081 — CLAVES FISCALES · VALIDADO
          DsFieldGroup(
            title: 'CLAVES FISCALES',
            source: hasOcr ? 'VALIDADO' : 'PENDIENTE',
            sourceTone: hasOcr ? DsChipTone.ok : DsChipTone.neutral,
            children: [
              DsFormField(
                label: 'CURP',
                hint: '18 caracteres',
                controller: _curp,
                textCapitalization: TextCapitalization.characters,
                maxLength: 18,
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[A-Za-z0-9]')),
                  LengthLimitingTextInputFormatter(18),
                ],
                validator: (v) => (v == null || v.trim().length != 18)
                    ? 'CURP inválido (18 caracteres)'
                    : null,
              ),
              DsFormField(
                label: 'RFC',
                hint: '13 caracteres',
                controller: _rfc,
                textCapitalization: TextCapitalization.characters,
                maxLength: 13,
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[A-Za-z0-9]')),
                  LengthLimitingTextInputFormatter(13),
                ],
                validator: (v) =>
                    (v == null || v.trim().length < 12) ? 'RFC inválido' : null,
              ),
            ],
          ),
          SizedBox(height: ds.h(18)),

          // Journey L1082–L1091 — DOMICILIO · CP VALIDADO
          DsFieldGroup(
            title: 'DOMICILIO',
            source: _cp.text.length == 5 ? 'CP VALIDADO' : 'CP PENDIENTE',
            sourceTone:
                _cp.text.length == 5 ? DsChipTone.ok : DsChipTone.neutral,
            children: [
              // En pantallas angostas calle+número en una fila se aprieta:
              // se apilan por debajo de 360.
              if (ds.isCompact) ...[
                DsFormField(
                    label: 'Calle',
                    controller: _calle,
                    textCapitalization: TextCapitalization.words,
                    validator: _required),
                DsFormField(
                    label: 'Número exterior',
                    controller: _numExt,
                    validator: _required),
              ] else
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 3,
                      child: DsFormField(
                          label: 'Calle',
                          controller: _calle,
                          textCapitalization: TextCapitalization.words,
                          validator: _required),
                    ),
                    SizedBox(width: ds.w(12)),
                    Expanded(
                      child: DsFormField(
                          label: 'No. ext.',
                          controller: _numExt,
                          validator: (v) =>
                              (v == null || v.trim().isEmpty) ? 'Req.' : null),
                    ),
                  ],
                ),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: DsFormField(
                        label: 'No. int. (opcional)', controller: _numInt),
                  ),
                  SizedBox(width: ds.w(12)),
                  Expanded(
                    child: DsFormField(
                      label: 'Código postal',
                      controller: _cp,
                      keyboardType: TextInputType.number,
                      maxLength: 5,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(5),
                      ],
                      onChanged: (_) => setState(() {}),
                      validator: (v) => (v == null || v.length != 5)
                          ? 'CP de 5 dígitos'
                          : null,
                    ),
                  ),
                ],
              ),
              DsFormField(
                  label: 'Colonia',
                  controller: _colonia,
                  textCapitalization: TextCapitalization.words,
                  validator: _required),
              DsFormField(
                  label: 'Municipio / alcaldía',
                  controller: _municipio,
                  textCapitalization: TextCapitalization.words,
                  validator: _required),
              DsFormField(
                  label: 'Ciudad',
                  controller: _ciudad,
                  textCapitalization: TextCapitalization.words,
                  validator: _required),
              DsPickerField(
                label: 'Estado',
                sheetTitle: '¿En qué estado vives?',
                searchHint: 'Buscar estado',
                options: _estados,
                value: _estadoDomicilio.isEmpty ? null : _estadoDomicilio,
                onChanged: (v) => setState(() => _estadoDomicilio = v),
                validator: (_) =>
                    _estadoDomicilio.isEmpty ? 'Selecciona el estado' : null,
              ),
            ],
          ),
          SizedBox(height: ds.h(18)),

          // Journey L1092–L1096 — CONTACTO E INGRESO · OTP VERIFICADO
          DsFieldGroup(
            title: 'CONTACTO E INGRESO',
            source: provider.state.preAuthToken.isNotEmpty
                ? 'OTP VERIFICADO'
                : 'SIN VERIFICAR',
            sourceTone: provider.state.preAuthToken.isNotEmpty
                ? DsChipTone.ok
                : DsChipTone.neutral,
            children: [
              // Celular y correo **no se vuelven a capturar**: se dieron en el
              // paso 3 y el celular quedó verificado con el código. Dejarlos
              // editables aquí invita a cambiar el número que ya se verificó,
              // que es como tirar el OTP a la basura. Se muestran como dato,
              // con la vía para corregirlos si de verdad hace falta.
              DsReadonlyField(
                label: 'Celular',
                value: _celular.text.isEmpty ? '—' : _formatPhone(_celular.text),
                verified: provider.state.preAuthToken.isNotEmpty,
                onEdit: () => context.go('/onboarding/phone'),
              ),
              DsReadonlyField(
                label: 'Email',
                value: _email.text.isEmpty ? '—' : _email.text,
                onEdit: () => context.go('/onboarding/phone'),
              ),
              DsFormField(
                label: 'Ingreso mensual',
                hint: '\$18,500',
                controller: _ingreso,
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[0-9,\$. ]')),
                ],
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? 'Necesitamos tu ingreso para calcular tu capacidad'
                    : null,
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// "5510026001" → "55 1002 6001". Se lee de un vistazo, que es lo único que
  /// se necesita de un dato que ya no se edita aquí.
  static String _formatPhone(String raw) {
    final d = raw.replaceAll(RegExp(r'\D'), '');
    if (d.length != 10) return raw;
    return '${d.substring(0, 2)} ${d.substring(2, 6)} ${d.substring(6)}';
  }

  static String? _required(String? v) =>
      (v == null || v.trim().isEmpty) ? 'Requerido' : null;
}

// ─── Pestaña Documentos ───────────────────────────────────────────────────────

class _DocumentsTab extends StatelessWidget {
  const _DocumentsTab({required this.provider, required this.onCapture});

  final KycProvider provider;
  final Future<void> Function(KycDocumentKind) onCapture;

  @override
  Widget build(BuildContext context) {
    final ds = context.ds;
    final docs = provider.state.documents;

    Widget tile(KycDocumentKind kind) => DsDocumentTile(
          name: kind.label,
          hint: kind.hint,
          captured: docs.has(kind),
          icon: switch (kind) {
            KycDocumentKind.ineFrente => Icons.badge_outlined,
            KycDocumentKind.ineReverso => Icons.qr_code_2_outlined,
            KycDocumentKind.selfie => Icons.face_outlined,
            KycDocumentKind.comprobanteDomicilio => Icons.receipt_long_outlined,
          },
          preview: docs.has(kind) ? MemoryImage(docs[kind]!.bytes) : null,
          isBusy: provider.isOcrRunning && kind.feedsOcr,
          onTap: () => onCapture(kind),
        );

    // El orden cuenta una secuencia causal: primero el INE, e inmediatamente
    // después la tarjeta de OCR — porque es el INE el que dispara la lectura y
    // el que prellena la pestaña Datos. Poner el OCR al final de los cuatro
    // documentos (como quedó en la primera versión) rompía ese vínculo: se leía
    // como un resumen suelto en vez de como la consecuencia de la captura.
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DsFieldGroup(
          title: '1 · TU IDENTIFICACIÓN',
          source: docs.canRunOcr ? 'COMPLETA' : 'PENDIENTE',
          sourceTone: docs.canRunOcr ? DsChipTone.ok : DsChipTone.neutral,
          spacing: 11,
          children: [
            tile(KycDocumentKind.ineFrente),
            tile(KycDocumentKind.ineReverso),
            _OcrCard(
              done: provider.state.ocrData != null,
              running: provider.isOcrRunning,
              error: provider.error,
            ),
          ],
        ),
        SizedBox(height: ds.h(20)),
        DsFieldGroup(
          title: '2 · PRUEBA DE VIDA Y DOMICILIO',
          source: docs.isComplete ? 'COMPLETA' : 'PENDIENTE',
          sourceTone: docs.isComplete ? DsChipTone.ok : DsChipTone.neutral,
          spacing: 11,
          children: [
            tile(KycDocumentKind.selfie),
            tile(KycDocumentKind.comprobanteDomicilio),
          ],
        ),
      ],
    );
  }
}

class _OcrCard extends StatelessWidget {
  const _OcrCard({required this.done, required this.running, this.error});
  final bool done, running;
  final String? error;

  @override
  Widget build(BuildContext context) {
    final ds = context.ds;
    final bool failed = error != null && !running;

    return Container(
      padding: EdgeInsets.all(ds.w(16)),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(ds.r(AppRadii.cardSmall)),
        border: Border.all(
            color: failed ? AppColors.error : AppColors.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text('LECTURA AUTOMÁTICA (OCR)',
                    style: AppTextStyles.captionLabel(fontSize: ds.sp(10))),
              ),
              SizedBox(width: ds.w(8)),
              if (running)
                SizedBox(
                  width: ds.w(14),
                  height: ds.w(14),
                  child: const CircularProgressIndicator(strokeWidth: 2),
                )
              else
                DsStatusChip(
                  label: failed
                      ? 'ERROR'
                      : done
                          ? 'EXTRAÍDO'
                          : 'LISTO PARA LEER',
                  tone: failed
                      ? DsChipTone.warning
                      : done
                          ? DsChipTone.ok
                          : DsChipTone.neutral,
                ),
            ],
          ),
          SizedBox(height: ds.h(12)),
          Text(
            failed
                ? error!
                : running
                    ? 'Estamos leyendo tu INE…'
                    : done
                        ? 'Leímos tu INE y llenamos nombre, CURP, fecha de nacimiento '
                            'y domicilio. Revísalos en la pestaña Datos antes de continuar.'
                        : 'De tu INE sacamos nombre, CURP, fecha de nacimiento y '
                            'domicilio; del comprobante, tu dirección actual. No '
                            'escribes nada: solo revisas en el siguiente paso.',
            style: AppTextStyles.body(fontSize: ds.sp(12.5)),
          ),
        ],
      ),
    );
  }
}

// ─── Auxiliares ───────────────────────────────────────────────────────────────

class _SourceTile extends StatelessWidget {
  const _SourceTile({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ds = context.ds;
    return Material(
      color: AppColors.surfaceVariant,
      borderRadius: BorderRadius.circular(ds.r(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(ds.r(12)),
        child: Container(
          padding: EdgeInsets.all(ds.w(12)),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(ds.r(12)),
            border: Border.all(color: AppColors.outlineVariant),
          ),
          child: Row(
            children: [
              Container(
                padding: EdgeInsets.all(ds.w(10)),
                decoration: BoxDecoration(
                  color: AppColors.primaryContainer,
                  borderRadius: BorderRadius.circular(ds.r(10)),
                ),
                child: Icon(icon, color: AppColors.primary, size: ds.sp(20)),
              ),
              SizedBox(width: ds.w(12)),
              Expanded(
                child: Text(label,
                    style: AppTextStyles.body(
                        fontSize: ds.sp(14), color: AppColors.onSurface)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
