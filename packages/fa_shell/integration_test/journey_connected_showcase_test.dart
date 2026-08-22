/// Journeys E2E **conectados** — sin un solo mock.
///
/// Cada test es el guion de un video. Corren en flavor `local`: app → gateway →
/// BFF → dominio. Lo único simulado son los servicios externos (buró y SPEI),
/// que están stubbeados dentro de los servicios, como corresponde.
///
/// Grabar uno:
///   xcrun simctl io booted recordVideo --codec h264 --force out.mov &
///   flutter test integration_test/journey_connected_showcase_test.dart \
///     -d <device> --plain-name "<nombre del test>"
library;

import 'package:fa_core/fa_core.dart';
import 'package:fa_design_system/fa_design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'helpers/image_picker_mock.dart';
import 'helpers/onboarding_steps.dart';
import 'helpers/test_data.dart';
import 'helpers/test_helpers.dart';
import 'package:fa_shell/main_local.dart' as local_app;

/// Distribuidora sembrada con línea `DL-DIST-STD-V1` activa. Cambia al
/// resembrar; se sobreescribe con `--dart-define=DIST_PHONE=…`.
/// Distribuidora sembrada con línea aprobada.
///
/// `seed-distribuidoras.py` genera los teléfonos al azar (`55` + 8 dígitos), así que
/// este valor caduca en cuanto se resiembra la base: el login devuelve
/// `credential_not_found` y el flujo muere en el home. Para reapuntarlo:
///
/// ```sh
/// docker exec fintech-services-postgres-1 psql -U fintech -d fintech -c "
///   select c.username, ca.available_credit
///   from credit_portfolio.credit_accounts ca
///   join identity.credentials c on c.party_id = ca.obligor_party_id
///   where ca.product_code='DL-DIST-STD-V1' and ca.status='ACTIVE'
///   order by ca.available_credit desc limit 5;"
/// ```
///
/// y correr con `--dart-define=DIST_PHONE=<el que salga>`.
const _distPhone = String.fromEnvironment('DIST_PHONE', defaultValue: '5546645958');
/// Contraseña de la distribuidora sembrada.
///
/// Se sobreescribe con `--dart-define=DIST_PASSWORD=...`. El valor por omisión
/// es el mismo de [TestData.password] porque las cuentas que deja el sembrado
/// —y las que crean estos propios E2E— se dan de alta con él.
const _distPassword =
    String.fromEnvironment('DIST_PASSWORD', defaultValue: TestData.password);

Future<void> _beat(WidgetTester tester,
    [Duration d = const Duration(milliseconds: 1500)]) async {
  await tester.pump(d);
}

void _log(String m) {
  // ignore: avoid_print
  print('🎬 $m');
}

/// La originación completa contra los servicios reales.
Future<void> _originacion(WidgetTester tester,
    {CreditPurpose purpose = CreditPurpose.usoPropio,
    required Finder landing,
    required String landingReason}) async {
  await tester.goToIdentityStep(
      phone: TestData.uniquePhone(), purpose: purpose);
  _log('Alta — documentos');
  await tester.captureDocumentsOnly();
  await _beat(tester);
  await tester.tapButton('Leer mis documentos');
  await tester.pumpAndSettle();
  // CURP única: origination rechaza duplicados por CURP.
  await tester.fillIdentityData(curp: TestData.uniqueCurp());
  await tester.tapButton('Todo está correcto');
  await tester.pumpAndSettle();
  _log('Análisis — buró y círculo reales');
  await tester.completePasswordStep(landing: landing, reason: landingReason);
  await _beat(tester, const Duration(seconds: 2));
}

/// Toma un préstamo personal de punta a punta: configurador → contrato → firma.
Future<void> _creditoUsoPropio(WidgetTester tester) async {
  // El nombre sale del catálogo real (`credit-product`), no de un mock: allí el
  // producto a plazo se llama «Préstamo Personal Estándar».
  //
  // Las oportunidades son un **carrusel horizontal** (Journey L461: `overflow-x`
  // con scroll-snap), así que hay que arrastrarlo de lado. `scrollAndTap` y un
  // delta vertical no lo mueven, y la tarjeta que cae fuera del viewport nunca
  // llega a montarse.
  final producto = find.textContaining('Préstamo Personal');
  final encontrado = await tester.findScrolling(
    producto,
    scrollable: find.byType(Scrollable).last,
    delta: const Offset(-260, 0),
  );
  expect(encontrado, isTrue,
      reason: 'el catálogo real debe ofrecer el préstamo personal');
  await tester.ensureVisible(producto.first);
  await tester.pumpAndSettle();
  await tester.tap(producto.first, warnIfMissed: false);
  await tester.pumpAndSettle(const Duration(seconds: 2));
  _log('Préstamo personal');
  await _beat(tester, const Duration(seconds: 2));

  await tester.tap(find.textContaining('Continuar con'));
  await tester.pumpAndSettle(const Duration(seconds: 3));
  _log('Configurador');
  await _beat(tester, const Duration(seconds: 3));

  await tester.scrollAndTap(find.text('Revisar solicitud'));
  final aprobado = await tester.pumpUntilFound(
    find.text('SÍ CUMPLES LOS CRITERIOS'),
    maxTicks: 90,
    tick: const Duration(milliseconds: 500),
  );
  expect(aprobado, isTrue, reason: 'la resolución real debe aprobar');
  _log('Aprobado');
  await tester.pump(const Duration(seconds: 2));

  await tester.scrollAndTap(find.text('Aceptar y continuar'));
  await tester.pumpAndSettle(const Duration(seconds: 3));
  _log('Resumen y destino del depósito');

  const clabe = 'CLABE interbancaria (18 dígitos)';
  if (find.byKey(const ValueKey('ds-field:$clabe')).evaluate().isNotEmpty) {
    await tester.enterField(clabe, '012180000000000000');
    await tester.pumpAndSettle();
  }
  await tester.scrollAndTap(find.textContaining('Acepto el contrato de crédito'));
  await tester.pumpAndSettle();
  await tester.scrollAndTap(find.text('Leer y firmar contrato'));
  await tester.pumpAndSettle(const Duration(seconds: 3));
  _log('Contrato en PDF');
  await _beat(tester, const Duration(seconds: 3));

  final pad = find.byType(DsSignaturePad);
  final box = tester.getRect(pad);
  final g = await tester
      .startGesture(Offset(box.left + box.width * 0.25, box.center.dy));
  for (final dx in [0.35, 0.45, 0.55, 0.65, 0.75]) {
    await g.moveTo(Offset(
        box.left + box.width * dx, box.center.dy + (dx * 100 % 30) - 15));
    await tester.pump(const Duration(milliseconds: 60));
  }
  await g.up();
  await tester.pumpAndSettle();
  _log('Firma autógrafa');
  await _beat(tester, const Duration(seconds: 2));

  await tester.tapButton('Estampar firma y continuar');
  await tester.pumpAndSettle(const Duration(seconds: 3));
  await tester.enterPinCode('123456');
  await tester.pumpAndSettle(const Duration(seconds: 4));
  _log('Desembolso');
  await _beat(tester, const Duration(seconds: 3));
  await tester.tapButton('Ir a mi crédito');
  await tester.pumpAndSettle(const Duration(seconds: 3));
}

/// Entra con la distribuidora sembrada — la que ya tiene línea aprobada.
Future<void> _entrarComoDistribuidora(WidgetTester tester) async {
  await tester.tapButton('Ya tengo cuenta · Entrar');
  await tester.pumpAndSettle();
  await tester.enterField('CELULAR', _distPhone);
  await tester.enterField('CONTRASEÑA', _distPassword);
  await tester.pumpAndSettle();
  await tester.tapButton('Entrar');
  final enHome = await tester.pumpUntilFound(find.textContaining('Hola,'),
      maxTicks: 40, tick: const Duration(milliseconds: 500));
  expect(enHome, isTrue,
      reason: 'el login de $_distPhone no llevó al home.\n'
          'Si en los logs de identity dice `credential_not_found`, la cuenta '
          'sembrada ya no existe: la base se resembró. Saca una vigente con la '
          'consulta de docs/KREDIUS_E2E_VIDEOS.md y pásala con '
          '--dart-define=DIST_PHONE=<teléfono> '
          '[--dart-define=DIST_PASSWORD=<clave>].');

  final conLinea = await tester.pumpUntilFound(
      find.text('MI LÍNEA DE DISTRIBUIDOR'),
      maxTicks: 30,
      tick: const Duration(milliseconds: 500));
  expect(conLinea, isTrue, reason: 'su línea sale de credit-portfolio');
  _log('Home — MI LÍNEA DE DISTRIBUIDOR');
  await _beat(tester, const Duration(seconds: 3));
}

/// El envío a una beneficiaria, hasta la liga.
Future<void> _envioABeneficiaria(WidgetTester tester) async {
  await tester.tap(find.text('Colocaciones'));
  await tester.pumpAndSettle(const Duration(seconds: 2));
  _log('Colocaciones');
  await _beat(tester, const Duration(seconds: 2));

  await tester.scrollAndTap(find.text('Enviar préstamo'));
  await tester.pumpAndSettle(const Duration(seconds: 2));
  _log('¿A quién le vas a prestar?');
  await _beat(tester, const Duration(seconds: 2));

  final tel = TestData.uniquePhone();
  await tester.enterField(
      'Nombre completo, como en su INE', 'Rosa Elena Diaz Fuentes');
  await tester.enterField('Su celular a 10 dígitos', tel);
  await tester.enterField('Cómo la conoces', 'Clienta de mi tienda desde 2023');
  await tester.pumpAndSettle();
  await _beat(tester, const Duration(seconds: 2));

  await tester.scrollAndTap(find.text('Continuar'));
  await tester.pumpAndSettle(const Duration(seconds: 2));
  _log('Monto, plazo y bonificación');
  await _beat(tester, const Duration(seconds: 3));

  await tester.scrollAndTap(find.text('Enviarle la liga por WhatsApp'));
  await tester.pumpAndSettle(const Duration(seconds: 4));
  expect(find.text('Le mandamos la liga'), findsOneWidget,
      reason: 'la colocación se creó en beneficiary-service');
  _log('Liga enviada — colocación creada de verdad');
  await _beat(tester, const Duration(seconds: 4));

  await tester.tapButton('Ver mis colocaciones');
  await tester.pumpAndSettle(const Duration(seconds: 3));
  _log('Su colocación ya aparece en la cartera');
  await _beat(tester, const Duration(seconds: 3));
}

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  binding.framePolicy = LiveTestWidgetsFlutterBindingFramePolicy.fullyLive;

  setUpAll(FakeImagePickerPlatform.setup);
  setUp(() => AppSession.instance.clear());

  Future<void> boot(WidgetTester tester) async {
    local_app.main();
    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();
  }

  /// Reinicia la app **de verdad**, para los flujos que arrancan de cero y
  /// luego vuelven a entrar como otra persona.
  ///
  /// Llamar a `main()` una segunda vez no reinicia nada: `runApp` recibe la
  /// misma raíz (`const KrediusApp()`), Flutter reconcilia el árbol en vez de
  /// remontarlo y el router se queda donde estaba —el segundo arranque se
  /// quedaba en el home buscando el botón del welcome—. Desmontar primero
  /// fuerza el arranque, y la sesión en memoria se limpia porque un arranque
  /// real tampoco la conserva.
  Future<void> reboot(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
    AppSession.instance.clear();
    await boot(tester);
  }

  // ── 1 ────────────────────────────────────────────────────────────────────
  testWidgets('1 Originacion y credito de uso propio', (tester) async {
    await boot(tester);
    _log('▶ ORIGINACIÓN + CRÉDITO DE USO PROPIO');
    await _beat(tester, const Duration(seconds: 2));

    await _originacion(tester,
        landing: find.text('Tus oportunidades'),
        landingReason: 'uso propio cae en las oportunidades');
    _log('Oportunidades del scoring real');
    await _beat(tester, const Duration(seconds: 2));

    await _creditoUsoPropio(tester);
    _log('◀ FIN');
    await _beat(tester, const Duration(seconds: 3));
  });

  // ── 2 ────────────────────────────────────────────────────────────────────
  testWidgets('2 Originacion distribuidor y envio a beneficiario',
      (tester) async {
    await boot(tester);
    _log('▶ ORIGINACIÓN DISTRIBUIDORA + ENVÍO A BENEFICIARIA');
    await _beat(tester, const Duration(seconds: 2));

    // Su línea la decide un comité: el alta termina en el home, en revisión.
    await _originacion(tester,
        purpose: CreditPurpose.distribuidor,
        landing: find.text('Inicio'),
        landingReason: 'la línea de colocación pasa por comité');
    _log('Alta de distribuidora — su línea queda en revisión');
    await _beat(tester, const Duration(seconds: 3));

    // Con la línea ya aprobada, la operación es ésta.
    await reboot(tester);
    await _entrarComoDistribuidora(tester);
    await _envioABeneficiaria(tester);
    _log('◀ FIN');
    await _beat(tester, const Duration(seconds: 3));
  });

  // ── 3 ────────────────────────────────────────────────────────────────────
  testWidgets('3 Originacion distribuidor uso propio y envio', (tester) async {
    await boot(tester);
    _log('▶ ORIGINACIÓN DISTRIBUIDORA + USO PROPIO + ENVÍO');
    await _beat(tester, const Duration(seconds: 2));

    await _originacion(tester,
        purpose: CreditPurpose.distribuidor,
        landing: find.text('Inicio'),
        landingReason: 'la línea de colocación pasa por comité');
    await _beat(tester, const Duration(seconds: 3));

    await reboot(tester);
    await _entrarComoDistribuidora(tester);

    // Además de colocar, toma un crédito para sí. Su nav no tiene
    // "Oportunidades" —quien coloca ve Colocaciones y Beneficiarios—, así que
    // el catálogo se abre desde el CTA de la tarjeta de oportunidades, que es
    // el que el diseño pone en el home (Journey L779–L794). Se prefiere a la
    // tarjeta de estado vacío porque ésa desaparece en cuanto la distribuidora
    // ya tiene un crédito, y entonces el flujo no tendría por dónde entrar.
    await tester.scrollAndTap(find.text('Ver mis oportunidades'));
    await tester.pumpAndSettle(const Duration(seconds: 3));
    _log('La distribuidora también pide para sí');
    await _beat(tester, const Duration(seconds: 2));
    await _creditoUsoPropio(tester);

    await tester.scrollAndTap(find.text('Inicio'));
    await tester.pumpAndSettle(const Duration(seconds: 2));
    await _envioABeneficiaria(tester);
    _log('◀ FIN');
    await _beat(tester, const Duration(seconds: 3));
  });

  // ── 4 ────────────────────────────────────────────────────────────────────
  testWidgets('4 Originacion distribuidor y uso propio', (tester) async {
    await boot(tester);
    _log('▶ ORIGINACIÓN DISTRIBUIDORA + USO PROPIO');
    await _beat(tester, const Duration(seconds: 2));

    await _originacion(tester,
        purpose: CreditPurpose.distribuidor,
        landing: find.text('Inicio'),
        landingReason: 'la línea de colocación pasa por comité');
    await _beat(tester, const Duration(seconds: 3));

    await reboot(tester);
    await _entrarComoDistribuidora(tester);

    await tester.scrollAndTap(find.text('Ver mis oportunidades'));
    await tester.pumpAndSettle(const Duration(seconds: 3));
    _log('Crédito para sí misma');
    await _beat(tester, const Duration(seconds: 2));
    await _creditoUsoPropio(tester);
    _log('◀ FIN');
    await _beat(tester, const Duration(seconds: 3));
  });

  // ── 5 ────────────────────────────────────────────────────────────────────
  testWidgets('5 Home con linea de distribuidor y credito propio',
      (tester) async {
    await boot(tester);
    _log('▶ HOME CON LÍNEA Y CRÉDITO PROPIO');
    await _beat(tester, const Duration(seconds: 2));

    await _entrarComoDistribuidora(tester);

    // Este flujo necesita que la distribuidora **ya tenga** un crédito propio,
    // y una recién sembrada sólo tiene su línea. Antes eso lo cubría de rebote
    // el flujo 3, así que el 5 sólo pasaba si se corría después: una
    // dependencia de orden que no estaba escrita en ningún lado y que aparecía
    // como un fallo suyo. Si le falta, se lo toma aquí.
    if (find.text('MIS CRÉDITOS').evaluate().isEmpty) {
      _log('Aún sin crédito propio — lo contrata para poder mostrarlos juntos');
      await tester.scrollAndTap(find.text('Ver mis oportunidades'));
      await tester.pumpAndSettle(const Duration(seconds: 3));
      await _creditoUsoPropio(tester);
      await tester.scrollAndTap(find.text('Inicio'));
      await tester.pumpAndSettle(const Duration(seconds: 3));
    }

    // Aquí está lo que este video viene a enseñar: la misma persona tiene su
    // línea de colocación **y** créditos que tomó para sí, y el home los pone
    // en orden de prelación — primero el dinero del que responde, después el
    // que pidió, y hasta abajo lo que se le ofrece.
    await tester.scrollAndTap(find.text('Inicio'));
    await tester.pumpAndSettle(const Duration(seconds: 2));
    await _verificarPrelacionDelHome(tester);
    _log('Home — línea arriba, créditos propios debajo, oportunidades al final');
    await _beat(tester, const Duration(seconds: 5));

    // Y con ambas cosas vivas, coloca.
    await _envioABeneficiaria(tester);

    // De vuelta al home: la colocación ya movió su línea, y el orden aguanta.
    await tester.scrollAndTap(find.text('Inicio'));
    await tester.pumpAndSettle(const Duration(seconds: 3));
    await _verificarPrelacionDelHome(tester);
    _log('Home tras colocar — el orden se mantiene');
    await _beat(tester, const Duration(seconds: 5));

    _log('◀ FIN');
    await _beat(tester, const Duration(seconds: 3));
  });
}

/// Afirma el orden de las cards del home: línea de distribuidor arriba,
/// créditos propios en medio, oportunidades al final.
///
/// Se compara la posición vertical real en pantalla y no el orden de los
/// finders, porque lo que se quiere fijar es lo que el usuario ve.
Future<void> _verificarPrelacionDelHome(WidgetTester tester) async {
  final linea = find.text('MI LÍNEA DE DISTRIBUIDOR');
  expect(linea, findsOneWidget,
      reason: 'la distribuidora debe ver su línea en el home');

  // La cartera y la línea se piden a servicios distintos, así que la card de
  // créditos puede montarse un instante después de la de la línea.
  final creditos = find.text('MIS CRÉDITOS');
  final llegaron = await tester.pumpUntilFound(creditos,
      maxTicks: 30, tick: const Duration(milliseconds: 500));
  expect(llegaron, isTrue,
      reason: 'y también los créditos que tomó para sí');

  expect(tester.getTopLeft(linea).dy, lessThan(tester.getTopLeft(creditos).dy),
      reason: 'la línea va antes que los créditos propios');

  // Las oportunidades cierran. Puede quedar fuera del viewport inicial, así
  // que sólo se compara si ya está montada.
  final promo = find.textContaining('para ti');
  if (promo.evaluate().isNotEmpty) {
    expect(
        tester.getTopLeft(creditos).dy, lessThan(tester.getTopLeft(promo.first).dy),
        reason: 'lo que se ofrece va al final, nunca encima de lo que ya se debe');
  }
}
