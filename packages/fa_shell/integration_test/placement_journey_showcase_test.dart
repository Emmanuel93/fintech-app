/// Journey de demostración — colocación B2B2C (7ª pasada).
///
/// Recorre el camino completo del distribuidor en el flavor mock, deteniéndose
/// en cada pantalla lo suficiente para que la grabación se pueda ver:
///
///   welcome → alta **como distribuidora** (privacidad → propósito → celular →
///   código → documentos → datos → contraseña → análisis)
///   → home con **MI LÍNEA DE DISTRIBUIDOR** y el nav de 4 pestañas
///   → Enviar préstamo: a quién → monto, plazo y bonificación → liga enviada
///   → la beneficiaria se verifica **sola, en su teléfono** (el mock avanza su
///     KYC con el reloj) → llega el aviso
///   → su historial de buró → asumir el riesgo → aprobar
///   → Colocaciones y Beneficiarios con la nueva ficha
///
/// Lo que esta corrida demuestra, y que es el corazón del diseño: el
/// distribuidor **nunca** captura la INE de su clienta. Da tres datos, define
/// condiciones, manda la liga y espera. El expediente lo llena ella.
library;

import 'package:fa_core/fa_core.dart';
import 'package:fa_notifications/fa_notifications.dart';
import 'package:fa_credit/fa_credit.dart';
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

  setUpAll(() async {
    await FakeImagePickerPlatform.setup();
    CreditMockInterceptor.reset();
    NotificationsMockInterceptor.reset();
    PlacementsMockInterceptor.reset();
  });

  testWidgets('Journey de colocación: enviar préstamo, buró y decisión',
      (tester) async {
    mock_app.main();
    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();

    // ── Alta como distribuidora ──────────────────────────────────────────
    _log('Bienvenida');
    await _beat(tester);

    await tester.goToPrivacyStep();
    await tester.acceptLegalConsents();
    await tester.tapButton('Autorizar y continuar');
    await tester.pumpAndSettle();

    // El paso del propósito, con lo nuevo de la Fase A: las viñetas sólo se
    // despliegan en la opción elegida y el aviso ámbar fija la regla del KYC.
    _log('Propósito — para colocar a terceros');
    expect(find.textContaining('Tú no puedes firmar por ella'), findsOneWidget,
        reason: 'la regla del KYC propio debe estar a la vista antes de elegir');
    await _beat(tester, const Duration(seconds: 2));

    await tester.tapButton(CreditPurpose.distribuidor.title);
    await tester.pumpAndSettle();
    expect(find.textContaining('20% de comisión'), findsOneWidget,
        reason: 'al elegir distribuidora se despliegan sus tres viñetas');
    _log('Propósito — viñetas desplegadas');
    await _beat(tester, const Duration(seconds: 2));
    await tester.tapButton('Continuar');
    await tester.pumpAndSettle();

    // Celular + correo → código → documentos.
    await tester.enterField('Número celular', '5510026001');
    await tester.enterField('Correo electrónico', 'distribuidora@correo.com');
    await tester.pumpAndSettle();
    await tester.tapButton('Continuar');
    await tester.pumpAndSettle(const Duration(seconds: 2));
    await tester.enterPinCode('123456');
    await tester.pumpAndSettle(const Duration(seconds: 3));

    _log('Identidad — documentos');
    await tester.captureDocumentsOnly();
    await _beat(tester);
    await tester.tapButton('Leer mis documentos');
    await tester.pumpAndSettle();
    await tester.fillIdentityData();
    await tester.tapButton('Todo está correcto');
    await tester.pumpAndSettle();

    // El análisis de quien coloca no termina en oportunidades: su línea la
    // decide un comité, así que cae directo en su home.
    _log('Análisis del alta');
    await tester.completePasswordStep(
      landing: find.text('Inicio'),
      reason: 'el alta del distribuidor termina en su home, no en el catálogo',
    );
    await _beat(tester, const Duration(seconds: 2));

    // ── Home del distribuidor ────────────────────────────────────────────
    final enHome = await tester.pumpUntilFound(
      find.text('MI LÍNEA DE DISTRIBUIDOR'),
      maxTicks: 30,
      tick: const Duration(milliseconds: 500),
    );
    expect(enHome, isTrue,
        reason: 'el home de quien coloca abre con su línea, no con un crédito');
    _log('Home — MI LÍNEA DE DISTRIBUIDOR');
    await _beat(tester, const Duration(seconds: 3));

    // El nav cambia de forma: 4 pestañas en vez de 3, sin Oportunidades.
    expect(find.text('Colocaciones'), findsOneWidget);
    expect(find.text('Beneficiarios'), findsOneWidget);
    expect(find.text('Oportunidades'), findsNothing,
        reason: 'quien ya coloca no tiene el catálogo en el nav');
    _log('Nav de 4 pestañas');
    await _beat(tester, const Duration(seconds: 2));

    // ── Pestaña Colocaciones ─────────────────────────────────────────────
    await tester.tap(find.text('Colocaciones'));
    await tester.pumpAndSettle(const Duration(seconds: 2));
    _log('Colocaciones — cartera viva con sus atrasos');
    expect(find.textContaining('ATRASO'), findsWidgets,
        reason: 'la cartera sembrada trae atrasos de distinta gravedad');
    await _beat(tester, const Duration(seconds: 3));

    // ── Enviar préstamo · paso 1: a quién ────────────────────────────────
    await tester.scrollAndTap(find.text('Enviar préstamo'));
    await tester.pumpAndSettle(const Duration(seconds: 2));
    _log('Enviar préstamo — ¿a quién le vas a prestar?');
    expect(find.text('Ella se verifica sola'), findsOneWidget);
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

    // ── Paso 2: monto, plazo y bonificación ──────────────────────────────
    _log('Monto y plazo — las dos caras de la operación');
    expect(find.text('CUÁNTO LE PRESTAS'), findsOneWidget);
    expect(find.text('EN CUÁNTAS QUINCENAS TE PAGA'), findsOneWidget);
    expect(find.textContaining('Tu bonificación'), findsWidgets);
    await _beat(tester, const Duration(seconds: 3));

    // El plazo es discreto: 12 / 24 / 36 / 48. Un toque al "+" salta a 36.
    final mas = find.bySemanticsLabel('Aumentar plazo');
    if (mas.evaluate().isNotEmpty) {
      await tester.tap(mas.first);
      await tester.pumpAndSettle();
      _log('Plazo — salta al siguiente permitido, no de uno en uno');
      await _beat(tester, const Duration(seconds: 2));
    }

    // La comisión decreciente está escrita, no escondida en el contrato.
    expect(find.textContaining('al quinto día, cero'), findsOneWidget);
    await _beat(tester, const Duration(seconds: 2));

    await tester.scrollAndTap(find.text('Enviarle la liga por WhatsApp'));
    await tester.pumpAndSettle(const Duration(seconds: 3));

    // ── Paso 3: liga enviada ─────────────────────────────────────────────
    _log('Liga enviada — qué sigue y la promesa sobre la línea');
    expect(find.text('Le mandamos la liga'), findsOneWidget);
    expect(find.textContaining('Nada queda apartado mientras tanto'),
        findsOneWidget,
        reason: 'la promesa sobre la línea es lo que hay que dejar claro aquí');
    await _beat(tester, const Duration(seconds: 4));

    await tester.tapButton('Ver mis colocaciones');
    await tester.pumpAndSettle(const Duration(seconds: 2));

    // ── La beneficiaria se verifica sola ─────────────────────────────────
    //
    // El mock la hace avanzar con el reloj: invited → kycInProgress →
    // bureauReady. Es la espera real del flujo, comprimida a segundos.
    _log('Esperando a que Rosa Elena termine su verificación…');
    await tester.tap(find.text('Colocaciones'));
    await tester.pumpAndSettle(const Duration(seconds: 2));

    // Se refresca jalando la lista, como lo haría el distribuidor esperando
    // noticias. El mock avanza el estado en cada lectura, así que sin el
    // refresco la pantalla se quedaría en "LIGA ENVIADA" para siempre.
    var lista = false;
    for (var i = 0; i < 14 && !lista; i++) {
      await tester.fling(
          find.byType(ListView).first, const Offset(0, 320), 800);
      await tester.pumpAndSettle(const Duration(seconds: 3));
      lista = find.text('ESPERA TU OK').evaluate().isNotEmpty;
    }
    expect(lista, isTrue,
        reason: 'la colocación debe llegar a "espera tu OK" sola');
    _log('Rosa Elena terminó — la colocación espera decisión');
    await _beat(tester, const Duration(seconds: 3));

    // ── Su historial y la decisión ───────────────────────────────────────
    await tester.scrollAndTap(find.text('Rosa Elena Díaz Fuentes'));
    await tester.pumpAndSettle(const Duration(seconds: 3));

    _log('Historial de buró — score, banda y desglose');
    expect(find.text('SCORE'), findsOneWidget);
    expect(find.text('Kredius no aprueba ni rechaza: tú decides'), findsOneWidget,
        reason: 'la regla que gobierna la pantalla tiene que estar escrita');
    await _beat(tester, const Duration(seconds: 5));

    await tester.scrollAndTap(
        find.textContaining('asumo el riesgo de esta colocación'));
    await tester.pumpAndSettle();
    _log('Asume el riesgo — constancia de que vio el historial');
    await _beat(tester, const Duration(seconds: 2));

    await tester.scrollAndTap(find.text('Aprobar y armar su crédito'));
    await tester.pumpAndSettle(const Duration(seconds: 3));

    // ── Después de aprobar ───────────────────────────────────────────────
    _log('Aprobada — la línea ya se descontó');
    await _beat(tester, const Duration(seconds: 3));

    await tester.tap(find.text('Beneficiarios'));
    await tester.pumpAndSettle(const Duration(seconds: 2));
    _log('Beneficiarios — el directorio con su ficha nueva');
    expect(find.text('Mis beneficiarios'), findsOneWidget);
    await _beat(tester, const Duration(seconds: 3));

    // La ficha se despliega con sus cuatro datos y las tres acciones.
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
      _log('Notificaciones — liga enviada, se verificó y depósito');
      await _beat(tester, const Duration(seconds: 5));
    }

    _log('FIN — journey de colocación completo');
    await _beat(tester, const Duration(seconds: 2));
  });
}
