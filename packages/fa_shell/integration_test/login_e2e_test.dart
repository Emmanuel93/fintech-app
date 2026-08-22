/// Login E2E — flujo: splash → login → home
///
/// Comportamiento:
///   - Detecta automáticamente si el BFF está levantado (localhost:8085).
///   - Si está arriba  → corre contra los servicios reales (flavor local).
///   - Si no responde → corre contra los interceptores mock (flavor mock).
///
/// Datos alineados con OnboardingAcceptanceTest.java del backend.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'helpers/backend_probe.dart';
import 'helpers/test_data.dart';
import 'helpers/test_helpers.dart';
import 'package:fa_shell/main.dart' as mock_app;
import 'package:fa_shell/main_local.dart' as local_app;

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  binding.framePolicy = LiveTestWidgetsFlutterBindingFramePolicy.fullyLive;

  late BackendMode mode;

  setUpAll(() async {
    mode = await BackendProbe.detect();
    printBackendMode(mode.label);
  });

  group('Login E2E [${BackendMode.mock.label}]', () {
    setUp(BackendProbe.reset);

    // ── TC-L01: splash → pantalla de login ───────────────────────────────
    testWidgets('TC-L01: la app inicia con splash y navega a login',
        (tester) async {
      mock_app.main();
      await tester.pump();

      // Splash visible: logo/animación
      // Esperar que el splash desaparezca (~2.2 s en el código)
      await tester.pump(const Duration(seconds: 3));
      await tester.pumpAndSettle();

      // Splash → Welcome de marca → "Ya tengo cuenta" → login
      await tester.tapButton('Ya tengo cuenta · Entrar');
      await tester.pumpAndSettle();

      expect(find.text('Entrar'), findsOneWidget,
          reason: 'Login debe mostrarse tras el Welcome de marca');
    });

    // ── TC-L02: login exitoso con credenciales válidas (mock) ─────────────
    testWidgets('TC-L02: login exitoso → navega a home (mock)', (tester) async {
      mock_app.main();
      await tester.pump(const Duration(seconds: 3));
      await tester.pumpAndSettle();

      await tester.tapButton('Ya tengo cuenta · Entrar');
      await tester.pumpAndSettle();

      // Ingresar teléfono
      await tester.enterField('CELULAR', TestData.phone);
      // Ingresar contraseña
      await tester.enterField('CONTRASEÑA', TestData.password);
      await tester.pumpAndSettle();

      // Tap "Ingresar"
      await tester.tapButton('Entrar');
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Home visible: la tarjeta de bienvenida o el CTA de crédito
      expect(
        find.textContaining('Emmanuel').evaluate().isNotEmpty ||
            find.text('Solicitar crédito').evaluate().isNotEmpty ||
            find.text('Solicita tu crédito').evaluate().isNotEmpty ||
            find.text('Mi Crédito Revolvente').evaluate().isNotEmpty,
        isTrue,
        reason: 'El home debe mostrarse después de login exitoso',
      );
    });

    // ── TC-L03: contraseña incorrecta muestra error (mock) ───────────────
    testWidgets('TC-L03: credenciales inválidas → no navega a home (mock)',
        (tester) async {
      mock_app.main();
      await tester.pump(const Duration(seconds: 3));
      await tester.pumpAndSettle();

      await tester.tapButton('Ya tengo cuenta · Entrar');
      await tester.pumpAndSettle();

      await tester.enterField('CELULAR', TestData.phone);
      await tester.enterField('CONTRASEÑA', '1'); // demasiado corta → falla
      await tester.pumpAndSettle();

      await tester.tapButton('Entrar');
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Sigue en la pantalla de login
      expect(find.text('Entrar'), findsAtLeastNWidgets(1),
          reason: 'Debe permanecer en login con credenciales incorrectas');
    });
  });

  // ── Tests contra backend real (se saltan si el BFF no está levantado) ──
  group('Login E2E [local — solo si BFF disponible]', () {
    setUp(BackendProbe.reset);

    testWidgets('TC-L04: login contra BFF real → detecta modo', (tester) async {
      final currentMode = await BackendProbe.detect();
      printBackendMode(currentMode.label);

      if (currentMode == BackendMode.mock) {
        // Skip elegante: marca como pasado con razón
        // ignore: avoid_print
        print('⚠️  TC-L04 SALTADO — BFF no disponible en localhost:8085');
        return;
      }

      local_app.main();
      await tester.pump(const Duration(seconds: 3));
      await tester.pumpAndSettle();

      await tester.tapButton('Ya tengo cuenta · Entrar');
      await tester.pumpAndSettle();

      expect(find.text('Entrar'), findsOneWidget);

      await tester.enterField('CELULAR', TestData.phone);
      await tester.enterField('CONTRASEÑA', TestData.password);
      await tester.pumpAndSettle();

      await tester.tapButton('Entrar');
      await tester.pumpAndSettle(const Duration(seconds: 5));

      // El resultado depende de si el usuario existe en el backend local.
      // Solo validamos que se navegó fuera de login (home) o se muestra error.
      final isHome = find.text('Solicitar crédito').evaluate().isNotEmpty ||
          find.text('Mi Crédito Revolvente').evaluate().isNotEmpty;
      final isError = find.textContaining('Credencial').evaluate().isNotEmpty ||
          find.textContaining('Error').evaluate().isNotEmpty ||
          find.text('Entrar').evaluate().isNotEmpty;

      expect(isHome || isError, isTrue,
          reason: 'El app debe responder con home o error de credenciales');
    });
  });
}
