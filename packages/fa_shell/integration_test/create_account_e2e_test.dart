/// Crear cuenta E2E — flujo completo de alta de prospecto (ADR-001)
///
/// Flujo cubierto:
///   splash → welcome → privacy → phone → OTP
///   → identidad (pestaña **Documentos** → pestaña **Datos**)
///   → password → success
///
/// El paso de identidad ya no son tres pantallas (`ine-capture`,
/// `ocr-review`, `personal-data`): el diseño Kredius lo resuelve en una sola
/// con segmented control, y con el orden **invertido** — primero los cuatro
/// documentos, y de su OCR se prellenan los datos.
///
/// ImagePicker se mockea con FakeImagePickerPlatform — el OCR stub del BFF
/// ignora el contenido real de los bytes.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:fa_design_system/fa_design_system.dart';

import 'package:fa_core/fa_core.dart';

import 'helpers/backend_probe.dart';
import 'helpers/test_data.dart';
import 'helpers/test_helpers.dart';
import 'helpers/onboarding_steps.dart';
import 'helpers/image_picker_mock.dart';
import 'package:fa_shell/main.dart' as mock_app;
import 'package:fa_shell/main_local.dart' as local_app;

/// Los cuatro documentos, con el nombre exacto que pinta la pestaña.
const _documentos = [
  'INE · frente',
  'INE · reverso',
  'Selfie de vida',
  'Comprobante de domicilio',
];

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  binding.framePolicy = LiveTestWidgetsFlutterBindingFramePolicy.fullyLive;

  setUpAll(() async {
    final mode = await BackendProbe.detect();
    printBackendMode(mode.label);
    await FakeImagePickerPlatform.setup();
  });

  group('Crear cuenta E2E (mock)', () {
    // ── TC-CA01: splash → welcome de marca ───────────────────────────────
    testWidgets('TC-CA01: splash → welcome (héroe de marca)', (tester) async {
      mock_app.main();
      await tester.pump(const Duration(seconds: 3));
      await tester.pumpAndSettle();

      expect(find.text('Empezar solicitud'), findsOneWidget,
          reason: 'WelcomeScreen debe mostrarse tras el splash');
      // El welcome trae los tres datos del prototipo.
      expect(find.text('SOLICITUD'), findsOneWidget);
      expect(find.text('DEPÓSITO'), findsOneWidget);
    });

    // ── TC-CA02: privacidad → propósito ───────────────────────────────────
    testWidgets('TC-CA02: tras autorizar, para qué es el crédito',
        (tester) async {
      mock_app.main();
      await tester.pump(const Duration(seconds: 3));
      await tester.pumpAndSettle();

      await tester.goToPurposeStep();

      // El propósito define qué productos se evalúan y a dónde lleva el
      // análisis, así que preguntarlo después obligaría a rehacerlo.
      expect(find.text('¿Cómo vas a usar tu crédito?'), findsOneWidget);
      expect(find.text('Para mí'), findsOneWidget);
      expect(find.text('Para colocar a terceros'), findsOneWidget);

      await tester.tapButton('Para mí');
      await tester.pumpAndSettle();
      await tester.tapButton('Continuar');
      await tester.pumpAndSettle();

      expect(find.text('¿A qué celular te mandamos el código?'), findsOneWidget);
    });

    // ── TC-CA03: welcome → celular (paso 1) ───────────────────────────────
    testWidgets('TC-CA03: welcome → captura de celular y correo',
        (tester) async {
      mock_app.main();
      await tester.pump(const Duration(seconds: 3));
      await tester.pumpAndSettle();

      await tester.goToPhoneEntry();

      expect(find.text('¿A qué celular te mandamos el código?'), findsOneWidget,
          reason: 'El celular se captura después de autorizar y elegir para qué');
      expect(find.text('NÚMERO CELULAR'), findsOneWidget);
      expect(find.text('CORREO ELECTRÓNICO'), findsOneWidget,
          reason: 'El correo se captura junto al celular');
    });

    // ── TC-CA04: el alta abre con privacidad (paso 1) ─────────────────────
    testWidgets('TC-CA04: el alta abre con privacidad y autorización',
        (tester) async {
      mock_app.main();
      await tester.pump(const Duration(seconds: 3));
      await tester.pumpAndSettle();

      await tester.goToPrivacyStep();

      expect(find.text('Tu privacidad y tu autorización'), findsOneWidget);
      // Los documentos legales se pueden abrir antes de aceptar.
      expect(find.text('Aviso de privacidad integral'), findsOneWidget);
      expect(find.text('Términos de uso de Kredius'), findsOneWidget);
      // Las dos SIC, con nombre.
      expect(find.text('SE CONSULTAN'), findsOneWidget);
      expect(find.text('Buró de crédito'), findsOneWidget);
      expect(find.text('Círculo de crédito'), findsOneWidget);
      // Dos obligatorios y uno opcional.
      expect(find.text('OBLIGATORIO'), findsNWidgets(2));
      expect(find.text('OPCIONAL'), findsOneWidget);
    });

    // ── TC-CA04b: sin los obligatorios el CTA no habilita ─────────────────
    testWidgets('TC-CA04b: el CTA exige los dos consentimientos obligatorios',
        (tester) async {
      mock_app.main();
      await tester.pump(const Duration(seconds: 3));
      await tester.pumpAndSettle();

      await tester.goToPrivacyStep();

      final cta = find.widgetWithText(DsButton, 'Autorizar y continuar');
      expect(tester.widget<DsButton>(cta).onPressed, isNull,
          reason: 'sin aceptar nada, el CTA está deshabilitado');

      // Sólo el primero: sigue deshabilitado.
      await tester.tap(find.textContaining('Leí y acepto el aviso de privacidad'));
      await tester.pumpAndSettle();
      expect(tester.widget<DsButton>(cta).onPressed, isNull,
          reason: 'falta la autorización de buró');
    });

    // ── TC-CA05: OTP → identidad, pestaña Documentos ─────────────────────
    testWidgets('TC-CA05: verificar OTP → identidad en pestaña Documentos',
        (tester) async {
      mock_app.main();
      await tester.pump(const Duration(seconds: 3));
      await tester.pumpAndSettle();

      await tester.goToIdentityStep();

      expect(find.text('Sube tus documentos'), findsOneWidget,
          reason: 'IdentityScreen debe mostrarse tras verificar el OTP');
      // Documentos es la PRIMERA pestaña — el orden invertido del prototipo.
      expect(find.text('1 · Documentos'), findsOneWidget);
      expect(find.text('2 · Verifica tus datos'), findsOneWidget);
      for (final doc in _documentos) {
        expect(find.text(doc), findsOneWidget,
            reason: 'Falta el documento "$doc" en la pestaña');
      }
    });

    // ── TC-CA06: la pestaña Datos está bloqueada sin documentos ──────────
    testWidgets('TC-CA06: sin documentos, Datos está bloqueada y el CTA off',
        (tester) async {
      mock_app.main();
      await tester.pump(const Duration(seconds: 3));
      await tester.pumpAndSettle();

      await tester.goToIdentityStep();

      // El CTA de documentos existe pero no navega.
      expect(find.text('Leer mis documentos'), findsOneWidget);

      await tester.tap(find.text('2 · Verifica tus datos'));
      await tester.pumpAndSettle();

      // Sigue en Documentos: los tiles de captura continúan visibles.
      expect(find.text('INE · frente'), findsOneWidget,
          reason: 'La pestaña Datos no debe abrirse sin documentos');
    });

    // ── TC-CA07: capturar los 4 documentos → OCR prellena Datos ──────────
    testWidgets('TC-CA07: capturar documentos → OCR extrae y desbloquea Datos',
        (tester) async {
      mock_app.main();
      await tester.pump(const Duration(seconds: 3));
      await tester.pumpAndSettle();

      await tester.goToIdentityStep();
      await tester.captureDocumentsOnly();

      // El OCR corre solo al completar frente + reverso, y lo dice en su
      // tarjeta — todavía en la pestaña Documentos.
      expect(find.text('EXTRAÍDO'), findsOneWidget,
          reason: 'La tarjeta de OCR debe marcar EXTRAÍDO tras leer el INE');

      await tester.tapButton('Leer mis documentos');
      await tester.pumpAndSettle();

      // Y el título cambia al de la segunda pestaña.
      expect(find.text('Confirma que esté bien'), findsOneWidget);

      // Ya en Datos: los grupos del diseño, con sus chips de procedencia.
      expect(find.text('IDENTIDAD'), findsOneWidget);
      expect(find.text('INE · OCR'), findsOneWidget,
          reason: 'El chip de procedencia dice de dónde salió cada dato');
    });

    // ── TC-CA08: datos → password screen ─────────────────────────────────
    testWidgets('TC-CA08: llenar datos → password screen', (tester) async {
      mock_app.main();
      await tester.pump(const Duration(seconds: 3));
      await tester.pumpAndSettle();

      await tester.goToIdentityStep();
      await tester.captureAllDocuments();

      await tester.fillIdentityData();
      await tester.tapButton('Todo está correcto');
      await tester.pumpAndSettle();

      expect(find.text('Crear cuenta'), findsOneWidget,
          reason: 'PasswordCreationScreen debe mostrarse');
    });

    // ── TC-CA09: FLUJO COMPLETO → success screen ─────────────────────────
    testWidgets(
        'TC-CA09: flujo completo de alta de prospecto → pantalla de éxito',
        (tester) async {
      mock_app.main();
      await tester.pump(const Duration(seconds: 3));
      await tester.pumpAndSettle();

      await tester.goToIdentityStep();
      await tester.captureAllDocuments();
      await tester.fillIdentityData();
      await tester.tapButton('Todo está correcto');
      await tester.pumpAndSettle();

      await tester.completePasswordStep();

      // El alta desemboca en el análisis y de ahí en las oportunidades: es el
      // análisis el que decide qué se le ofrece al usuario.
      expect(find.text('Tus oportunidades'), findsOneWidget);
      expect(find.text('APROBADAS PARA TI'), findsOneWidget,
          reason: 'uso propio abre líneas de persona, ya aprobadas');
    });

    // ── TC-CA11: el alta de distribuidor termina en revisión ─────────────
    testWidgets('TC-CA11: como distribuidor, el análisis deja la solicitud en revisión',
        (tester) async {
      mock_app.main();
      await tester.pump(const Duration(seconds: 3));
      await tester.pumpAndSettle();

      await tester.goToIdentityStep(purpose: CreditPurpose.distribuidor);
      await tester.captureAllDocuments();
      await tester.fillIdentityData();
      await tester.tapButton('Todo está correcto');
      await tester.pumpAndSettle();

      await tester.enterField('Contraseña', TestData.password);
      await tester.pumpAndSettle();
      await tester.enterField('Confirmar contraseña', TestData.password);
      await tester.pumpAndSettle();
      await tester.tapButton('Crear cuenta');

      // Las líneas de colocación pasan a comité: no hay oferta que tomar hoy,
      // así que el análisis lleva al home y lo dice ahí.
      final llego = await tester.pumpUntilFound(
        find.text('Tu solicitud está en revisión'),
        maxTicks: 60,
        tick: const Duration(milliseconds: 500),
      );
      expect(llego, isTrue,
          reason: 'el distribuidor termina en el home, en revisión');
      expect(find.text('Ver mis oportunidades'), findsNothing,
          reason: 'no se empuja a un catálogo que todavía no puede contratar');
    });
  });

  // ── Test contra BFF real (se omite si no hay backend) ──────────────────
  group('Crear cuenta E2E [local — solo si BFF disponible]', () {
    testWidgets('TC-CA10: flujo completo contra BFF real', (tester) async {
      final currentMode = await BackendProbe.detect();
      printBackendMode(currentMode.label);

      if (currentMode == BackendMode.mock) {
        // ignore: avoid_print
        print('⚠️  TC-CA10 SALTADO — gateway no disponible en localhost:8090');
        return;
      }

      // Para backend real: teléfono único para evitar DUPLICATE_PROSPECT.
      final uniquePhone = TestData.uniquePhone();
      // ignore: avoid_print
      print('📱 Teléfono único para este run: $uniquePhone');

      local_app.main();
      await tester.pump(const Duration(seconds: 3));
      await tester.pumpAndSettle();

      await tester.goToIdentityStep(phone: uniquePhone);
      // CURP única por corrida: origination rechaza duplicados **por CURP**, así que
      // con una fija este test sólo pasaba la primera vez contra una base persistente.
      await tester.completeIdentityStep(curp: TestData.uniqueCurp());
      // `completePasswordStep` ya espera el desenlace del análisis. Lo que se
      // afirma aquí es lo que sólo se puede comprobar contra el backend real:
      // que la sesión quedó iniciada —el alta hace login con la cuenta recién
      // creada— y que las oportunidades salieron del scoring de verdad.
      await tester.completePasswordStep();

      expect(find.text('APROBADAS PARA TI').evaluate().isNotEmpty ||
             find.text('PUEDES SOLICITARLAS').evaluate().isNotEmpty, isTrue,
          reason: 'el análisis real debe clasificar las oportunidades');
      expect(AppSession.instance.prospectId.isNotEmpty, isTrue,
          reason: 'el alta debe dejar el prospecto creado en la sesión');
    });
  });
}
