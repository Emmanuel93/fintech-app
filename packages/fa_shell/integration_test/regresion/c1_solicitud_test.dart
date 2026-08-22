/// CASO 1 · ACTO 1 — alta de un cliente de uso propio y solicitud que cae en revisión manual.
///
/// Precondición que pone el orquestador: la banda BAJO de la política de `PERSONAL_LOAN` está
/// elevada, así que el motor devuelve MANUAL_REVIEW para cualquier solicitante. No es un mock:
/// es el mismo motor, con otra configuración.
///
/// Con esa configuración el análisis del alta no abre nada "aprobado", así que aterriza en el
/// home con el estado en revisión. El catálogo se alcanza por la pestaña **Oportunidades** del
/// bottom nav, donde el producto aparece bajo «PUEDES SOLICITARLAS».
///
/// Termina imprimiendo los identificadores del journey para el siguiente acto.
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
    final curp = TestData.uniqueCurp();
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

    // ── Catálogo por la pestaña Oportunidades ───────────────────────────────
    await tester.tap(find.text('Oportunidades'));
    await tester.pumpAndSettle(const Duration(seconds: 2));
    final enCatalogo = await tester.pumpUntilFound(find.text('Tus oportunidades'),
        maxTicks: 30, tick: const Duration(milliseconds: 500));
    expect(enCatalogo, isTrue, reason: 'la pestaña Oportunidades abre el catálogo');
    expect(find.text('PUEDES SOLICITARLAS'), findsOneWidget,
        reason: 'el producto está sujeto a revisión, no aprobado de antemano');
    paso('CHECKPOINT — catálogo con la sección PUEDES SOLICITARLAS');
    await tester.respira(const Duration(seconds: 3));

    // Las tarjetas viven en un carrusel **horizontal** (`_Section` →
    // `ListView(scrollDirection: Axis.horizontal)`, product_selection_screen.dart:310-313), y
    // con los seis productos B2C en «PUEDES SOLICITARLAS» el préstamo personal es la cuarta:
    // nace fuera de pantalla por la derecha. `findScrolling` arrastra en vertical por defecto
    // sobre `Scrollable.first` —la lista de secciones—, así que nunca lo traía.
    final carrusel = find.byWidgetPredicate((w) =>
        w is Scrollable &&
        (w.axisDirection == AxisDirection.right ||
            w.axisDirection == AxisDirection.left));
    final producto = find.textContaining('Préstamo Personal');
    final hay = await tester.findScrolling(
      producto,
      scrollable: carrusel.first,
      delta: const Offset(-260, 0),
    );
    tester.volcarPantalla();
    expect(hay, isTrue, reason: 'el catálogo real ofrece el préstamo personal');
    await tester.ensureVisible(producto.first);
    await tester.pumpAndSettle();
    await tester.tap(producto.first, warnIfMissed: false);
    await tester.pumpAndSettle(const Duration(seconds: 2));

    await tester.scrollAndTap(find.textContaining('Continuar con'));
    await tester.pumpAndSettle(const Duration(seconds: 3));

    // ── Configurador ────────────────────────────────────────────────────────
    expect(find.text('MONTO DEL PRÉSTAMO'), findsOneWidget);
    paso('CHECKPOINT — configurador de monto y plazo');
    await tester.respira(const Duration(seconds: 3));

    await tester.scrollAndTap(find.text('Revisar solicitud'));
    await tester.pumpAndSettle(const Duration(seconds: 2));

    // ── La resolución real: revisión humana ─────────────────────────────────
    final resultado = await tester.esperaCualquiera(
      const ['Tu solicitud pasa a comité', 'SÍ CUMPLES LOS CRITERIOS', 'NO ALCANZASTE'],
      maxTicks: 150,
    );
    tester.volcarPantalla();
    expect(resultado, 'Tu solicitud pasa a comité',
        reason: 'la banda elevada debe mandar la solicitud a un analista, no aprobarla');
    expect(find.textContaining('Un analista la va a revisar'), findsOneWidget);
    paso('🎬 CHECKPOINT — la app dice que un analista la revisará');
    await tester.respira(const Duration(seconds: 4));

    // ── Handoff al orquestador ──────────────────────────────────────────────
    await publicarIdentificadores(phone: phone, password: password);

    await tester.tapButton('Entendido');
    await tester.pumpAndSettle(const Duration(seconds: 2));
    expect(find.text('Tu solicitud está en revisión'), findsOneWidget,
        reason: 'de vuelta en el home, el estado sigue siendo el mismo');
    paso('🎬 CHECKPOINT — home, a la espera del analista');
    await tester.respira(const Duration(seconds: 4));
  });
}
