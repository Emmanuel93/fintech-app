/// Journey E2E de demostración — los dos caminos del producto, en una corrida.
///
/// Es el guion del video: se recorren los dos perfiles, porque la app se bifurca
/// en el segundo paso del alta y desde ahí no vuelven a parecerse.
///
///   1. **Uso propio** — alta → análisis → oportunidades → **préstamo personal**
///      → configurador → tabla de amortización → resolución → contrato PDF con
///      firma autógrafa → código → desembolso → home con el crédito activo.
///
///   2. **Distribuidora** — entra con su cuenta (su línea la aprobó un comité;
///      una recién dada de alta está en revisión y no tiene nada que colocar) →
///      home con su línea y el nav de cuatro pestañas → enviar préstamo (a quién
///      → monto, plazo y bonificación → liga enviada) → la beneficiaria se
///      verifica sola → su historial de buró → asumir el riesgo → aprobar →
///      colocaciones y beneficiarios.
///
/// Corre en flavor **mock**: es determinista y no depende de que el stack esté
/// arriba, que es lo que hace que el video sea reproducible. La verificación
/// contra los servicios reales vive en `placement_connected_e2e_test.dart`.
///
/// Grabar:
///   xcrun simctl io booted recordVideo --codec h264 --force salida.mov &
///   flutter test integration_test/journey_e2e_showcase_test.dart -d <device>
library;

import 'package:fa_core/fa_core.dart';
import 'package:fa_credit/fa_credit.dart';
import 'package:fa_design_system/fa_design_system.dart';
import 'package:fa_notifications/fa_notifications.dart';
import 'package:fa_placements/fa_placements.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'helpers/image_picker_mock.dart';
import 'helpers/onboarding_steps.dart';
import 'helpers/test_helpers.dart';
import 'package:fa_shell/main.dart' as mock_app;

/// Pausa para que la grabación muestre la pantalla antes de seguir.
Future<void> _beat(WidgetTester tester,
    [Duration d = const Duration(milliseconds: 1500)]) async {
  await tester.pump(d);
}

void _log(String msg) {
  // ignore: avoid_print
  print('🎬 $msg');
}

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  binding.framePolicy = LiveTestWidgetsFlutterBindingFramePolicy.fullyLive;

  setUpAll(FakeImagePickerPlatform.setup);

  /// Cada camino arranca de cero: sin crédito, sin colocaciones y sin avisos de
  /// la corrida anterior. Sin esto, el segundo journey heredaría el crédito del
  /// primero y el home abriría en un estado que nadie recorrió.
  setUp(() {
    CreditMockInterceptor.reset();
    NotificationsMockInterceptor.reset();
    PlacementsMockInterceptor.reset();
    AppSession.instance.clear();
  });

  // ═══════════════════════════════════════════════════════════════════════
  // 1 · USO PROPIO — préstamo personal
  // ═══════════════════════════════════════════════════════════════════════

  testWidgets('Uso propio: préstamo personal de punta a punta', (tester) async {
    mock_app.main();
    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();

    _log('▶ CAMINO 1 · USO PROPIO');
    await _beat(tester, const Duration(seconds: 2));

    // ── Alta ─────────────────────────────────────────────────────────────
    await tester.goToIdentityStep();
    _log('Alta — documentos');
    await _beat(tester);

    await tester.captureDocumentsOnly();
    expect(find.text('EXTRAÍDO'), findsOneWidget,
        reason: 'el OCR debe haber leído el INE');
    _log('OCR extraído del INE');
    await _beat(tester);

    await tester.tapButton('Leer mis documentos');
    await tester.pumpAndSettle();
    await tester.fillIdentityData();
    await tester.tapButton('Todo está correcto');
    await tester.pumpAndSettle();

    _log('Análisis del alta');
    await tester.completePasswordStep();
    await _beat(tester, const Duration(seconds: 2));

    // Con "Para mí" sólo se evalúan productos de persona y todos salen
    // aprobados: no hay sección de comité.
    expect(find.text('APROBADAS PARA TI'), findsOneWidget);
    _log('Oportunidades aprobadas');
    await _beat(tester, const Duration(seconds: 2));

    // ── Préstamo personal ────────────────────────────────────────────────
    await tester.scrollAndTap(find.text('Préstamo personal'));
    await tester.pumpAndSettle(const Duration(seconds: 1));
    _log('Préstamo personal');
    await _beat(tester, const Duration(seconds: 2));

    await tester.tap(find.textContaining('Continuar con'));
    await tester.pumpAndSettle(const Duration(seconds: 2));

    expect(find.text('Arma tu préstamo'), findsOneWidget);
    expect(find.textContaining('el primero el'), findsOneWidget,
        reason: 'el compromiso no es sólo la cuota: cuántas son y cuándo empieza');
    _log('Configurador — monto, plazo y primera fecha');
    await _beat(tester, const Duration(seconds: 3));

    await tester.scrollAndTap(find.text('Ver tabla de amortización'));
    await tester.pumpAndSettle(const Duration(seconds: 3));
    expect(find.text('Tabla de amortización'), findsOneWidget);
    _log('Tabla de amortización');
    await _beat(tester, const Duration(seconds: 3));
    await tester.tap(find.bySemanticsLabel('Cerrar'));
    await tester.pumpAndSettle(const Duration(seconds: 2));

    await tester.scrollAndTap(find.text('Revisar solicitud'));
    await tester.pump(const Duration(milliseconds: 600));

    // De aquí a "Aprobado" no se puede usar pumpAndSettle: el anillo del
    // análisis y el punto del badge son animaciones en bucle.
    final aprobado = await tester.pumpUntilFound(
      find.text('SÍ CUMPLES LOS CRITERIOS'),
      maxTicks: 60,
      tick: const Duration(milliseconds: 500),
    );
    expect(aprobado, isTrue);
    _log('Resolución — aprobado');
    await tester.pump(const Duration(seconds: 2));

    // ── Contrato y firma ─────────────────────────────────────────────────
    await tester.scrollAndTap(find.text('Aceptar y continuar'));
    await tester.pumpAndSettle(const Duration(seconds: 3));
    _log('Resumen y destino del depósito');

    const clabeLabel = 'CLABE interbancaria (18 dígitos)';
    if (find.byKey(const ValueKey('ds-field:$clabeLabel')).evaluate().isNotEmpty) {
      await tester.enterField(clabeLabel, '012180000000000000');
      await tester.pumpAndSettle();
    }
    await tester.scrollAndTap(find.textContaining('Acepto el contrato de crédito'));
    await tester.pumpAndSettle();
    await _beat(tester);
    await tester.scrollAndTap(find.text('Leer y firmar contrato'));
    await tester.pumpAndSettle(const Duration(seconds: 3));

    _log('Contrato en PDF');
    expect(find.text('Tu contrato'), findsOneWidget);
    await _beat(tester, const Duration(seconds: 3));

    final pad = find.byType(DsSignaturePad);
    expect(pad, findsOneWidget);
    final box = tester.getRect(pad);
    final gesture = await tester.startGesture(
        Offset(box.left + box.width * 0.25, box.center.dy));
    for (final dx in [0.35, 0.45, 0.55, 0.65, 0.75]) {
      await gesture.moveTo(
          Offset(box.left + box.width * dx, box.center.dy + (dx * 100 % 30) - 15));
      await tester.pump(const Duration(milliseconds: 60));
    }
    await gesture.up();
    await tester.pumpAndSettle();
    _log('Firma autógrafa');
    await _beat(tester, const Duration(seconds: 2));

    await tester.tapButton('Estampar firma y continuar');
    await tester.pumpAndSettle(const Duration(seconds: 3));

    _log('Firma con código');
    await tester.enterPinCode('123456');
    await tester.pumpAndSettle(const Duration(seconds: 3));

    _log('Desembolso');
    await _beat(tester, const Duration(seconds: 3));
    await tester.tapButton('Ir a mi crédito');
    await tester.pumpAndSettle(const Duration(seconds: 3));

    // ── Home con el crédito vivo ─────────────────────────────────────────
    expect(find.text('CRÉDITO ACTIVO'), findsOneWidget);
    _log('Home — crédito activo');
    await _beat(tester, const Duration(seconds: 4));

    // El nav de quien pide para sí: sin pestañas de colocación.
    expect(find.text('Oportunidades'), findsOneWidget);
    expect(find.text('Colocaciones'), findsNothing,
        reason: 'quien pide para sí no coloca: el módulo no existe para él');
    _log('Nav de 3 pestañas — sin colocación');
    await _beat(tester, const Duration(seconds: 3));

    _log('◀ FIN DEL CAMINO 1');
    await _beat(tester, const Duration(seconds: 2));
  });

  // ═══════════════════════════════════════════════════════════════════════
  // 2 · DISTRIBUIDORA — colocación B2B2C
  // ═══════════════════════════════════════════════════════════════════════

  testWidgets('Distribuidora: enviar un préstamo y decidir con su historial',
      (tester) async {
    mock_app.main();
    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();

    _log('▶ CAMINO 2 · DISTRIBUIDORA');
    await _beat(tester, const Duration(seconds: 2));

    // ── Entra una distribuidora que ya tiene línea ───────────────────────
    //
    // Entra con su cuenta y no por el alta, y no es un atajo del guion: la
    // línea de colocación la aprueba un comité, así que una distribuidora
    // recién dada de alta está **en revisión** y todavía no tiene nada que
    // colocar. Quien envía préstamos es la que ya fue aprobada.
    await tester.tapButton('Ya tengo cuenta · Entrar');
    await tester.pumpAndSettle();
    _log('Login de la distribuidora');
    await _beat(tester, const Duration(seconds: 2));

    await tester.enterField('CELULAR', '5510026001');
    await tester.enterField('CONTRASEÑA', 'SecurePass1!');
    await tester.pumpAndSettle();
    await tester.tapButton('Entrar');
    await tester.pumpAndSettle(const Duration(seconds: 3));

    // ── Home del distribuidor ────────────────────────────────────────────
    final conLinea = await tester.pumpUntilFound(
      find.text('MI LÍNEA DE DISTRIBUIDOR'),
      maxTicks: 30,
      tick: const Duration(milliseconds: 500),
    );
    expect(conLinea, isTrue);
    _log('Home — MI LÍNEA DE DISTRIBUIDOR');
    await _beat(tester, const Duration(seconds: 3));

    expect(find.text('Colocaciones'), findsOneWidget);
    expect(find.text('Beneficiarios'), findsOneWidget);
    expect(find.text('Oportunidades'), findsNothing,
        reason: 'quien ya coloca no tiene el catálogo en el nav');
    _log('Nav de 4 pestañas');
    await _beat(tester, const Duration(seconds: 2));

    await tester.tap(find.text('Colocaciones'));
    await tester.pumpAndSettle(const Duration(seconds: 2));
    expect(find.textContaining('ATRASO'), findsWidgets,
        reason: 'la cartera trae atrasos de distinta gravedad');
    _log('Colocaciones — cartera viva');
    await _beat(tester, const Duration(seconds: 3));

    // ── Enviar préstamo ──────────────────────────────────────────────────
    await tester.scrollAndTap(find.text('Enviar préstamo'));
    await tester.pumpAndSettle(const Duration(seconds: 2));
    expect(find.text('Ella se verifica sola'), findsOneWidget);
    _log('¿A quién le vas a prestar?');
    await _beat(tester, const Duration(seconds: 3));

    await tester.enterField(
        'Nombre completo, como en su INE', 'Rosa Elena Díaz Fuentes');
    await tester.enterField('Su celular a 10 dígitos', '5549029037');
    await tester.enterField('Cómo la conoces', 'Clienta de mi tienda desde 2023');
    await tester.pumpAndSettle();
    _log('Datos de la beneficiaria');
    await _beat(tester, const Duration(seconds: 2));

    await tester.scrollAndTap(find.text('Continuar'));
    await tester.pumpAndSettle(const Duration(seconds: 2));

    expect(find.text('CUÁNTO LE PRESTAS'), findsOneWidget);
    expect(find.textContaining('Tu bonificación'), findsWidgets);
    _log('Monto y plazo — las dos caras de la operación');
    await _beat(tester, const Duration(seconds: 3));

    final mas = find.bySemanticsLabel('Aumentar plazo');
    if (mas.evaluate().isNotEmpty) {
      await tester.tap(mas.first);
      await tester.pumpAndSettle();
      _log('El plazo salta al siguiente permitido');
      await _beat(tester, const Duration(seconds: 2));
    }
    expect(find.textContaining('al quinto día, cero'), findsOneWidget);
    await _beat(tester, const Duration(seconds: 2));

    await tester.scrollAndTap(find.text('Enviarle la liga por WhatsApp'));
    await tester.pumpAndSettle(const Duration(seconds: 3));

    expect(find.text('Le mandamos la liga'), findsOneWidget);
    expect(find.textContaining('Nada queda apartado mientras tanto'), findsOneWidget,
        reason: 'la promesa sobre la línea es lo que hay que dejar claro aquí');
    _log('Liga enviada — la línea sigue intacta');
    await _beat(tester, const Duration(seconds: 4));

    await tester.tapButton('Ver mis colocaciones');
    await tester.pumpAndSettle(const Duration(seconds: 2));

    // ── La beneficiaria se verifica sola ─────────────────────────────────
    _log('Esperando a que Rosa Elena termine su verificación…');
    await tester.tap(find.text('Colocaciones'));
    await tester.pumpAndSettle(const Duration(seconds: 2));

    var lista = false;
    for (var i = 0; i < 14 && !lista; i++) {
      await tester.fling(find.byType(ListView).first, const Offset(0, 320), 800);
      await tester.pumpAndSettle(const Duration(seconds: 3));
      lista = find.text('ESPERA TU OK').evaluate().isNotEmpty;
    }
    expect(lista, isTrue, reason: 'la colocación llega a "espera tu OK" sola');
    _log('Terminó — la colocación espera decisión');
    await _beat(tester, const Duration(seconds: 3));

    // ── Su historial y la decisión ───────────────────────────────────────
    await tester.scrollAndTap(find.text('Rosa Elena Díaz Fuentes'));
    await tester.pumpAndSettle(const Duration(seconds: 3));

    expect(find.text('SCORE'), findsOneWidget);
    expect(find.text('Kredius no aprueba ni rechaza: tú decides'), findsOneWidget);
    _log('Su historial de buró — Kredius no decide');
    await _beat(tester, const Duration(seconds: 5));

    await tester.scrollAndTap(
        find.textContaining('asumo el riesgo de esta colocación'));
    await tester.pumpAndSettle();
    _log('Asume el riesgo');
    await _beat(tester, const Duration(seconds: 2));

    await tester.scrollAndTap(find.text('Aprobar y armar su crédito'));
    await tester.pumpAndSettle(const Duration(seconds: 3));
    _log('Aprobada — la línea ya se descontó');
    await _beat(tester, const Duration(seconds: 3));

    // ── El directorio ────────────────────────────────────────────────────
    await tester.tap(find.text('Beneficiarios'));
    await tester.pumpAndSettle(const Duration(seconds: 2));
    expect(find.text('Mis beneficiarios'), findsOneWidget);
    _log('Beneficiarios — su ficha nueva');
    await _beat(tester, const Duration(seconds: 3));

    await tester.scrollAndTap(find.text('Rosa Elena Díaz Fuentes'));
    await tester.pumpAndSettle(const Duration(seconds: 2));
    _log('Ficha desplegada');
    await _beat(tester, const Duration(seconds: 4));

    // ── Los avisos de todo lo que pasó ───────────────────────────────────
    await tester.scrollAndTap(find.text('Inicio'));
    await tester.pumpAndSettle(const Duration(seconds: 2));
    final campana = find.bySemanticsLabel(RegExp('Notificaciones'));
    if (campana.evaluate().isNotEmpty) {
      await tester.tap(campana.first, warnIfMissed: false);
      await tester.pumpAndSettle(const Duration(seconds: 3));
      _log('Notificaciones');
      await _beat(tester, const Duration(seconds: 4));
    }

    _log('◀ FIN DEL CAMINO 2 — journey completo');
    await _beat(tester, const Duration(seconds: 3));
  });
}
