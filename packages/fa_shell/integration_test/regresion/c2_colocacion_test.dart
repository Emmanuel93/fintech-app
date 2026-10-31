/// CASO 2/3 · ACTO 3 — la línea ya aprobada y la primera colocación a una beneficiaria.
///
/// Entre este acto y el anterior, un analista aprobó la línea desde la consola y el orquestador
/// la formalizó por API (oferta → contrato → firma), porque la app todavía no tiene esas
/// pantallas para `DISTRIBUTOR_LINE`.
///
///   flutter test integration_test/regresion/c2_colocacion_test.dart -d <device> \
///     --dart-define=RE2E_PHONE=... --dart-define=RE2E_PASSWORD=...
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../helpers/test_data.dart';
import '../helpers/test_helpers.dart';
import 'gestos.dart';
import 'soporte.dart';
import 'package:fa_shell/main_local.dart' as local_app;

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  binding.framePolicy = LiveTestWidgetsFlutterBindingFramePolicy.fullyLive;

  testWidgets('CASO 2/3 · línea activa y colocación enviada', (tester) async {
    final anterior = FlutterError.onError;
    FlutterError.onError = (d) {
      if (d.exception.toString().contains('overflowed by')) return;
      anterior?.call(d);
    };

    expect(rePhone.isNotEmpty, isTrue, reason: 'falta --dart-define=RE2E_PHONE');

    local_app.main();
    await tester.waitSplash();

    await tester.tapButton('Ya tengo cuenta · Entrar');
    await tester.settle();
    await tester.enterField('CELULAR', rePhone);
    await tester.enterField('CONTRASEÑA', rePassword);
    await tester.pump();
    await tester.tapButton('Entrar');
    final enHome = await tester.pumpUntilFound(find.textContaining('Hola,'),
        maxTicks: 40, tick: const Duration(milliseconds: 500));
    expect(enHome, isTrue);
    await tester.respira(const Duration(seconds: 2));

    // ── La aprobación del analista, vista desde la app ──────────────────────
    final conLinea = await tester.pumpUntilFound(find.text('MI LÍNEA DE DISTRIBUIDOR'),
        maxTicks: 40, tick: const Duration(milliseconds: 500));
    tester.volcarPantalla();
    expect(conLinea, isTrue,
        reason: 'aprobada la línea, el home debe mostrarla con su disponible');
    expect(find.text('Tu solicitud está en revisión'), findsNothing,
        reason: 'ya no está en revisión: el analista decidió');
    paso('🎬 CHECKPOINT — MI LÍNEA DE DISTRIBUIDOR, aprobada desde la consola');
    historia('linea');

    // Aquí sí aplica: el nav pierde «Oportunidades» cuando hay línea de colocación viva
    // (home_screen.dart, mismo criterio que home_nav_test.dart). En el alta todavía no la hay,
    // así que afirmarlo allá era afirmarlo antes de tiempo.
    expect(find.text('Oportunidades'), findsNothing,
        reason: 'documenta el hueco: con línea viva no hay pestaña que lleve al catálogo');
    await tester.respira(const Duration(seconds: 4));

    // ── Colocación ──────────────────────────────────────────────────────────
    await tester.tap(find.text('Colocaciones'));
    await tester.pumpAndSettle(const Duration(seconds: 2));
    paso('🎬 CHECKPOINT — pestaña Colocaciones');
    await tester.respira();

    historia('clienta');
    await tester.scrollAndTap(find.text('Enviar préstamo'));
    await tester.pumpAndSettle(const Duration(seconds: 2));

    final telBeneficiaria = TestData.uniquePhone();
    // El nombre de la beneficiaria tiene que cambiar entre corridas. La simulación de KYC arma
    // un CURP sintético a partir del nombre y **sólo dos dígitos** del teléfono
    // (`KycSimulationController.syntheticCurp`), así que con el nombre fijo hay 100 CURP
    // posibles y a la quinta corrida se repiten: origination responde «Duplicate prospect», el
    // KYC muere a medias y la colocación se queda clavada en KYC_IN_PROGRESS —de donde el
    // propio endpoint ya no la puede sacar, porque su reintento sólo contempla INVITED—.
    // Variando apellidos se mueve el prefijo del CURP y la colisión deja de ser cuestión de
    // suerte.
    const nombres = ['Rosa Elena', 'María Fernanda', 'Guadalupe', 'Ana Sofía'];
    const paternos = ['Diaz', 'Vargas', 'Mendoza', 'Cardenas', 'Ibarra'];
    const maternos = ['Fuentes', 'Quiroz', 'Salgado', 'Zamora', 'Rentería'];
    final semilla = int.parse(telBeneficiaria.substring(telBeneficiaria.length - 4));
    final nombreBeneficiaria = '${nombres[semilla % nombres.length]} '
        '${paternos[(semilla ~/ 4) % paternos.length]} '
        '${maternos[(semilla ~/ 20) % maternos.length]}';
    paso('Beneficiaria de esta corrida: $nombreBeneficiaria · $telBeneficiaria');
    await tester.enterField('Nombre completo, como en su INE', nombreBeneficiaria);
    await tester.enterField('Su celular a 10 dígitos', telBeneficiaria);
    await tester.enterField('Cómo la conoces', 'Clienta de mi tienda desde 2023');
    await tester.pumpAndSettle();
    await tester.respira();

    await tester.scrollAndTap(find.text('Continuar'));
    await tester.pumpAndSettle(const Duration(seconds: 2));
    paso('🎬 CHECKPOINT — monto, plazo y bonificación');
    historia('monto');
    await tester.respira(const Duration(seconds: 3));

    historia('liga');
    await tester.scrollAndTap(find.text('Enviarle la liga por WhatsApp'));
    await tester.pumpAndSettle(const Duration(seconds: 4));
    expect(find.text('Le mandamos la liga'), findsOneWidget,
        reason: 'la colocación se creó de verdad en beneficiary-service');
    paso('🎬 CHECKPOINT — colocación creada');
    await tester.respira(const Duration(seconds: 3));

    await tester.tapButton('Ver mis colocaciones');
    await tester.pumpAndSettle(const Duration(seconds: 3));
    paso('🎬 CHECKPOINT — la colocación ya está en su cartera');
    await tester.respira(const Duration(seconds: 3));

    // ── Handoff: el id de la colocación, para simular el KYC de la beneficiaria ──
    final token = await loginHttp(rePhone, rePassword);
    final lista = await colocaciones(token);
    if (lista.isNotEmpty) {
      final p = lista.first as Map<String, dynamic>;
      final id = p['placementId'] ?? p['id'];
      if (id != null) handoff('PLACEMENT_ID', '$id');
      handoff('BENEFICIARIA_TEL', telBeneficiaria);
      // El nombre lo necesitan la web de alta y la mesa de KYC para encontrarla.
      handoff('BENEFICIARIA_NOMBRE', nombreBeneficiaria);
      paso('Colocación $id · beneficiaria $telBeneficiaria · estado ${p['status']}');
    } else {
      paso('⚠️ el BFF no devolvió colocaciones');
    }
  });
}
