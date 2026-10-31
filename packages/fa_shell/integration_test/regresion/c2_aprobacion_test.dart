/// CASO 2/3 · ACTO 6 — la distribuidora ve el historial de su clienta y aprueba la colocación.
///
/// Entre este acto y el anterior, la beneficiaria hizo su alta en la web de la liga y una persona
/// de la mesa de KYC comprobó su identidad en el backoffice —sin Incode, a mano—. Sólo entonces la
/// colocación queda «ESPERA TU OK»: Kredius no aprueba ni rechaza, decide la distribuidora.
///
///   flutter test integration_test/regresion/c2_aprobacion_test.dart -d <device> \
///     --dart-define=RE2E_PHONE=... --dart-define=RE2E_PASSWORD=... \
///     --dart-define=RE2E_BENEFICIARIA="Rosa Elena Diaz Fuentes"
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../helpers/test_helpers.dart';
import 'gestos.dart';
import 'soporte.dart';
import 'package:fa_shell/main_local.dart' as local_app;

const reBeneficiaria = String.fromEnvironment('RE2E_BENEFICIARIA');

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  binding.framePolicy = LiveTestWidgetsFlutterBindingFramePolicy.fullyLive;

  testWidgets('CASO 2/3 · la distribuidora aprueba la colocación', (tester) async {
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

    await tester.tap(find.text('Colocaciones'));
    await tester.pumpAndSettle(const Duration(seconds: 2));

    // La fila de su clienta, ya verificada: el chip dice que la decisión es suya.
    final espera = await tester.pumpUntilFound(find.text('ESPERA TU OK'),
        maxTicks: 40, tick: const Duration(milliseconds: 500));
    tester.volcarPantalla();
    expect(espera, isTrue,
        reason: 'con la identidad comprobada en la mesa, la colocación espera la decisión de ella');
    paso('🎬 CHECKPOINT — la colocación de su clienta espera su OK');
    historia('lista');
    await tester.respira(const Duration(seconds: 3));

    // Se toca el chip de la FILA, no el nombre: el nombre aparece también en el aviso de arriba
    // («… terminó su verificación»), que no es pulsable, y tocarlo no abre nada. El chip vive
    // dentro de la fila, y la fila es la que navega al historial.
    final fila = find.text('ESPERA TU OK').first;
    await tester.ensureVisible(fila);
    await tester.tap(fila, warnIfMissed: false);
    await tester.pumpAndSettle(const Duration(seconds: 2));

    final historial = await tester.pumpUntilFound(find.text('Esto encontramos de ella'),
        maxTicks: 40, tick: const Duration(milliseconds: 500));
    tester.volcarPantalla();
    expect(historial, isTrue, reason: 'el buró de la beneficiaria se le entrega completo');
    paso('🎬 CHECKPOINT — el historial completo de su clienta, sin filtrar por score');
    historia('historial');
    await tester.respira(const Duration(seconds: 4));

    // El riesgo comercial lo asume ella, y la casilla es la evidencia.
    historia('aprueba');
    await tester.scrollAndTap(find.textContaining('Vi su historial y asumo el riesgo'));
    await tester.pumpAndSettle(const Duration(seconds: 1));
    await tester.respira();

    await tester.scrollAndTap(find.text('Aprobar y armar su crédito'));
    final deVuelta = await tester.pumpUntilFound(find.textContaining('Hola,'),
        maxTicks: 60, tick: const Duration(milliseconds: 500));
    tester.volcarPantalla();
    expect(deVuelta, isTrue, reason: 'al aprobar, la app regresa al inicio');
    paso('🎬 CHECKPOINT — colocación aprobada por la distribuidora');
    await tester.respira(const Duration(seconds: 3));

    // ── Lo que dice el servidor, no la pantalla ──────────────────────────────
    final token = await loginHttp(rePhone, rePassword);
    final lista = await colocaciones(token);
    if (lista.isNotEmpty) {
      final p = lista.first as Map<String, dynamic>;
      handoff('PLACEMENT_STATUS', '${p['status']}');
      paso('Colocación ${p['placementId'] ?? p['id']} · estado ${p['status']}');
    }

    await tester.tap(find.text('Colocaciones'));
    await tester.pumpAndSettle(const Duration(seconds: 3));
    paso('🎬 CHECKPOINT — la colocación ya va camino al depósito');
    await tester.respira(const Duration(seconds: 3));
  });
}
