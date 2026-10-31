/// CASO 2/3 · ACTO 1 — alta de una distribuidora; su línea nace sujeta a revisión.
///
/// `DL-DIST-STD-V1` tiene la banda BAJO inalcanzable en su política de scoring, así que cae a
/// revisión humana por el camino natural: aquí no se toca ninguna configuración.
///
/// **Hueco de producto que este acto deja documentado:** el alta no crea la solicitud de línea, y
/// una distribuidora recién dada de alta no tiene cómo crearla desde la app —su bottom nav es
/// Inicio/Movimientos/Colocaciones/Beneficiarios, sin «Oportunidades», y el home oculta la tarjeta
/// que lleva al catálogo mientras está «en revisión». Por eso el orquestador crea la solicitud por
/// el BFF (el mismo canal de la app) inmediatamente después de este acto, igual que hace hoy
/// `scripts/seed-distribuidoras.py`.
///
///   flutter test integration_test/regresion/c2_solicitud_test.dart -d <device>
library;

import 'package:fa_core/fa_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../helpers/image_picker_mock.dart';
import '../helpers/onboarding_steps.dart';
import '../helpers/test_data.dart';
import '../helpers/test_helpers.dart';
import 'gestos.dart';
import 'soporte.dart';
import 'package:fa_shell/main_local.dart' as local_app;

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  binding.framePolicy = LiveTestWidgetsFlutterBindingFramePolicy.fullyLive;

  setUpAll(() async => FakeImagePickerPlatform.setup());

  testWidgets('CASO 2/3 · alta de distribuidora con línea en revisión', (tester) async {
    final anterior = FlutterError.onError;
    FlutterError.onError = (d) {
      if (d.exception.toString().contains('overflowed by')) return;
      anterior?.call(d);
    };

    final phone = TestData.uniquePhone();
    // La CURP la puede fijar el orquestador: es la que lleva la INE de muestra que generó para
    // esta corrida, y la mesa de cumplimiento compara una contra la otra.
    const curpDefinida = String.fromEnvironment('RE2E_CURP');
    final curp = curpDefinida.isNotEmpty ? curpDefinida : TestData.uniqueCurp();
    const password = TestData.password;
    paso('Distribuidora — teléfono $phone · CURP $curp');

    local_app.main();
    await tester.waitSplash();

    // El alta va desarmada en sus pasos —el mismo orden que goToIdentityStep— para poder marcar
    // cada momento de la historia del video donde de verdad ocurre.
    historia('proposito');
    await tester.goToPhoneEntry(purpose: CreditPurpose.distribuidor);
    paso('CHECKPOINT — propósito «Para colocar a terceros»');
    historia('celular');
    await tester.enterField('Número celular', phone);
    await tester.enterField('Correo electrónico', TestData.email);
    await tester.pumpAndSettle();
    await tester.respira();
    await tester.tapButton('Continuar');
    await tester.pumpAndSettle(const Duration(seconds: 2));
    await tester.enterPinCode(TestData.otp);
    await tester.pumpAndSettle(const Duration(seconds: 3));
    historia('documentos');
    await tester.captureDocumentsOnly();
    // Mismo orden que en el caso 1: el chip de OCR se afirma en la pestaña Documentos, antes de
    // que «Leer mis documentos» pase a Datos.
    final ocr = await tester.esperaCualquiera(const ['EXTRAÍDO', 'ERROR'], maxTicks: 120);
    tester.volcarPantalla();
    expect(ocr, 'EXTRAÍDO',
        reason: 'el OCR real debe marcar los documentos como extraídos');
    await tester.respira();
    await tester.tapButton('Leer mis documentos');
    await tester.pumpAndSettle();

    historia('datos');
    await tester.fillIdentityData(curp: curp);
    await tester.tapButton('Todo está correcto');
    await tester.pumpAndSettle();

    historia('contrasena');
    await tester.completePasswordStep(
      landing: find.text('Inicio'),
      reason: 'la línea de distribuidor pasa a comité: el análisis lleva al home',
    );
    paso('CHECKPOINT — cuenta de distribuidora creada');
    await tester.respira(const Duration(seconds: 3));

    // HUECO DE PRODUCTO (la otra mitad del §4.2 del plan): el home de la distribuidora **no**
    // puede decir "tu línea está en revisión" recién dada de alta, y no por un fallo de la
    // prueba. El copy de comité depende de `isPendingReview`, que mira los productos
    // precalificados del propósito (credit_application_provider.dart:122-149), y la
    // precalificación del BFF móvil es **sólo B2C** por construcción:
    // `creditProductClient.listActiveProducts("B2C")` (CreditController.java:85), que pide a
    // scoring [CREDIT_CARD, GROUP_LOAN, MICRO_LOAN, PERSONAL_LOAN, PAYROLL_LOAN,
    // REVOLVING_LINE] — nunca DISTRIBUTOR_LINE, que es B2B2C.
    //
    // Con `purposeProducts` vacío para el propósito distribuidor, el home cae al estado vacío
    // genérico ("Todavía no tienes un crédito") y el nav conserva «Oportunidades», que sólo
    // desaparece cuando ya hay línea viva. Se deja constancia en el log en vez de afirmar un
    // copy que hoy no existe; la comprobación del nav se hace en el acto de la colocación,
    // que es donde de verdad aplica.
    tester.volcarPantalla();
    paso('🎬 HUECO — la precalificación del BFF es sólo B2C: el home de la distribuidora no '
        'muestra su línea en revisión (§4.2 del plan)');
    await tester.respira(const Duration(seconds: 4));

    handoff('PHONE', phone);
    handoff('PASSWORD', password);
    handoff('PROSPECT_ID', AppSession.instance.prospectId);
    paso('Prospecto ${AppSession.instance.prospectId}');
  });
}
