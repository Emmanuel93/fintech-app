/// CASO 1 · ACTO 1 — alta de un cliente de uso propio y primer intento de solicitud.
///
/// Sin proveedor biométrico conectado, toda identidad queda en revisión hasta que una persona la
/// confirma en la mesa de cumplimiento, y mientras tanto origination no recibe solicitudes. Este
/// acto comprueba que la app lo dice como es —«Estamos verificando tu identidad»— y no con un
/// «no pudimos enviar tu solicitud». La solicitud se reenvía en `c1_reenvio_test.dart`, después
/// del dictamen.
///
/// Precondición que pone el orquestador: la banda BAJO de la política de `PERSONAL_LOAN` está
/// elevada, así que el motor devuelve MANUAL_REVIEW para cualquier solicitante. No es un mock:
/// es el mismo motor, con otra configuración.
///
/// Con esa configuración el análisis del alta no abre nada "aprobado", así que aterriza en el
/// home con el estado en revisión. El catálogo se alcanza por la pestaña **Oportunidades** del
/// bottom nav, donde el producto aparece bajo «PUEDES SOLICITARLAS».
///
/// Termina imprimiendo los identificadores del journey para los siguientes actos.
///
///   flutter test integration_test/regresion/c1_solicitud_test.dart -d <device>
library;

// widgets.dart cubre foundation y además Scrollable/AxisDirection, que hacen falta para
// recorrer a mano el carrusel horizontal de productos.
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../helpers/image_picker_mock.dart';
import '../helpers/onboarding_steps.dart';
import '../helpers/test_data.dart';
import '../helpers/test_helpers.dart';
import 'c1_pasos.dart';
import 'gestos.dart';
import 'soporte.dart';
import 'package:fa_core/fa_core.dart';
import 'package:fa_shell/main_local.dart' as local_app;

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  binding.framePolicy = LiveTestWidgetsFlutterBindingFramePolicy.fullyLive;

  setUpAll(() async => FakeImagePickerPlatform.setup());

  testWidgets('CASO 1 · alta de uso propio y solicitud a revisión manual',
      (tester) async {
    // Overflow cosmético preexistente en una card del home: sin este filtro el binding marca
    // el acto completo como fallido por un warning de layout que no es funcional.
    final anterior = FlutterError.onError;
    FlutterError.onError = (d) {
      if (d.exception.toString().contains('overflowed by')) return;
      anterior?.call(d);
    };

    final phone = TestData.uniquePhone();
    // La CURP la fija el orquestador cuando trae documentos de muestra: es la que lleva el INE, y
    // en la mesa de cumplimiento una persona compara una contra otra.
    const curpDefinida = String.fromEnvironment('RE2E_CURP');
    final curp = curpDefinida.isNotEmpty ? curpDefinida : TestData.uniqueCurp();
    const password = TestData.password;
    paso('Teléfono $phone · CURP $curp');

    local_app.main();
    await tester.waitSplash();

    // ── Alta ────────────────────────────────────────────────────────────────
    await tester.goToIdentityStep(phone: phone, purpose: CreditPurpose.usoPropio);
    await tester.captureDocumentsOnly();
    // La tarjeta de OCR vive en la pestaña Documentos: «Leer mis documentos» pasa a Datos y se
    // la lleva por delante. Y contra el backend real el chip tarda en resolverse
    // (identity_screen.dart:775-779 — LISTO PARA LEER → spinner → EXTRAÍDO/ERROR), así que se
    // espera a que se decida en vez de dar por hecho que ya está.
    final ocr = await tester.esperaCualquiera(const ['EXTRAÍDO', 'ERROR'], maxTicks: 120);
    tester.volcarPantalla();
    expect(ocr, 'EXTRAÍDO',
        reason: 'el OCR real debe marcar los documentos como extraídos');
    paso('CHECKPOINT — 4 documentos capturados y OCR extraído');
    await tester.respira();
    await tester.tapButton('Leer mis documentos');
    await tester.pumpAndSettle();

    await tester.fillIdentityData(curp: curp);
    await tester.tapButton('Todo está correcto');
    await tester.pumpAndSettle();

    await tester.completePasswordStep(
      landing: find.text('Inicio'),
      reason: 'sin nada auto-aprobado, el análisis del alta lleva al home',
    );
    paso('CHECKPOINT — cuenta creada');
    await tester.respira(const Duration(seconds: 3));

    // ── El home dice en qué va ──────────────────────────────────────────────
    tester.volcarPantalla();
    expect(find.text('Tu solicitud está en revisión'), findsOneWidget,
        reason: 'con la banda elevada nada queda auto-aprobado: el home lo dice');
    paso('CHECKPOINT — home en revisión');
    await tester.respira(const Duration(seconds: 3));

    // ── Primer intento: la compuerta de identidad ──────────────────────────
    await solicitarPrestamoPersonal(tester);

    final resultado = await tester.esperaCualquiera(
      const ['Estamos verificando tu identidad', 'Tu solicitud pasa a comité', 'No pudimos enviar'],
      maxTicks: 60,
    );
    tester.volcarPantalla();
    expect(resultado, 'Estamos verificando tu identidad',
        reason: 'con la identidad en revisión la solicitud no se recibe, y la app lo dice como es');
    expect(find.textContaining('Un analista está revisando tus documentos'), findsOneWidget);
    paso('🎬 CHECKPOINT — la app dice que está verificando la identidad');
    await tester.respira(const Duration(seconds: 4));

    // ── Handoff al orquestador ──────────────────────────────────────────────
    // Todavía no hay solicitud: lo que necesita la mesa es la persona.
    handoff('PHONE', phone);
    handoff('PASSWORD', password);
    handoff('PROSPECT_ID', AppSession.instance.prospectId);
    handoff('CURP', curp);

    await tester.tapButton('Entendido');
    await tester.pumpAndSettle(const Duration(seconds: 2));
    expect(find.text('Estamos verificando tu identidad'), findsOneWidget,
        reason: 'de vuelta en el home, se sigue diciendo qué se espera');
    paso('🎬 CHECKPOINT — home, a la espera de la verificación');
    await tester.respira(const Duration(seconds: 4));
  });
}
