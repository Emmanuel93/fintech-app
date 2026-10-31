/// CASO 1 · ACTO 1c — con la identidad ya dictaminada, la solicitud se reenvía y pasa a revisión.
///
/// Corre después de que la mesa de cumplimiento confirma la identidad (acto 1b, en el
/// backoffice). Es la misma persona que entra con su cuenta y pide el mismo producto: ahora la
/// compuerta abre, y con la banda BAJO elevada por el orquestador la solicitud va a un analista.
///
///   flutter test integration_test/regresion/c1_reenvio_test.dart -d <device> \
///     --dart-define=RE2E_PHONE=... --dart-define=RE2E_PASSWORD=...
library;

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../helpers/test_helpers.dart';
import 'c1_pasos.dart';
import 'gestos.dart';
import 'soporte.dart';
import 'package:fa_shell/main_local.dart' as local_app;

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  binding.framePolicy = LiveTestWidgetsFlutterBindingFramePolicy.fullyLive;

  testWidgets('CASO 1 · identidad verificada: la solicitud se reenvía y pasa a revisión manual',
      (tester) async {
    final anterior = FlutterError.onError;
    FlutterError.onError = (d) {
      if (d.exception.toString().contains('overflowed by')) return;
      anterior?.call(d);
    };

    expect(rePhone.isNotEmpty, isTrue,
        reason: 'este acto necesita --dart-define=RE2E_PHONE');

    local_app.main();
    await tester.waitSplash();

    await entrar(tester, rePhone, rePassword);
    paso('🎬 CHECKPOINT — home autenticado, identidad ya verificada');
    await tester.respira(const Duration(seconds: 3));

    await solicitarPrestamoPersonal(tester);

    // ── La resolución real: revisión humana ─────────────────────────────────
    final resultado = await tester.esperaCualquiera(
      const ['Tu solicitud pasa a comité', 'SÍ CUMPLES LOS CRITERIOS', 'NO ALCANZASTE',
             'Estamos verificando tu identidad'],
      maxTicks: 150,
    );
    tester.volcarPantalla();
    expect(resultado, 'Tu solicitud pasa a comité',
        reason: 'con la identidad dictaminada la compuerta abre, y la banda elevada manda a un analista');
    expect(find.textContaining('Un analista la va a revisar'), findsOneWidget);
    paso('🎬 CHECKPOINT — la app dice que un analista la revisará');
    await tester.respira(const Duration(seconds: 4));

    // ── Handoff al orquestador ──────────────────────────────────────────────
    await publicarIdentificadores(phone: rePhone, password: rePassword);

    await tester.tapButton('Entendido');
    await tester.pumpAndSettle(const Duration(seconds: 2));
    expect(find.text('Tu solicitud está en revisión'), findsOneWidget,
        reason: 'de vuelta en el home, el estado sigue siendo el mismo');
    paso('🎬 CHECKPOINT — home, a la espera del analista');
    await tester.respira(const Duration(seconds: 4));
  });
}
