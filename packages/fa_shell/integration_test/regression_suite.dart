/// Suite de regresión E2E — orden OBLIGATORIO: CREAR CUENTA → LOGIN
///
/// El login es postcondición del alta: sin cuenta creada no existe sesión.
///
/// Diseño:
///   • Cada flujo completo vive en UN SOLO testWidgets → splash aparece una
///     sola vez por flujo, sin reiniciar entre pasos intermedios.
///   • El OTP screen tiene Timer.periodic → nunca usamos pumpAndSettle ahí;
///     usamos pump(Duration) en loop (pumpUntilFound).
///   • El backend se detecta automáticamente al inicio de la suite.
///   • SharedTestState.phone/password se llenan en el flujo de crear cuenta
///     y se reutilizan en el flujo de login.
///
/// Correr:
///   flutter test integration_test/regression_suite.dart \
///     -d 280BA0D6-F4F9-4B61-A71C-299EAF739917
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'helpers/backend_probe.dart';
import 'helpers/image_picker_mock.dart';
import 'helpers/shared_state.dart';
import 'helpers/test_data.dart';
import 'helpers/test_helpers.dart';
import 'helpers/onboarding_steps.dart';
import 'package:fa_shell/main.dart' as mock_app;
import 'package:fa_shell/main_local.dart' as local_app;

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  binding.framePolicy = LiveTestWidgetsFlutterBindingFramePolicy.fullyLive;

  late BackendMode mode;

  setUpAll(() async {
    mode = await BackendProbe.detect();

    // Mostrar modo detectado + razón detallada
    final modeLabel = mode == BackendMode.local
        ? mode.label
        : '${mode.label}\n║  Razón: ${BackendProbe.reason}';
    printBackendMode(modeLabel);

    if (mode == BackendMode.local) {
      // Identidad única por run: origination rechaza el alta con
      // DUPLICATE_PROSPECT, y valida **por CURP**, no sólo por teléfono. Con la
      // CURP fija esta suite sólo pasaba la primera vez contra una base viva.
      SharedTestState.phone = TestData.uniquePhone();
      SharedTestState.curp = TestData.uniqueCurp();
      // ignore: avoid_print
      print('📱 Identidad única para este run: ${SharedTestState.phone} '
          '/ ${SharedTestState.curp}');
    } else {
      SharedTestState.phone = TestData.phone;
      SharedTestState.curp = TestData.curp;
    }

    await FakeImagePickerPlatform.setup();
  });

  void runApp() {
    if (mode == BackendMode.local) {
      local_app.main();
    } else {
      mock_app.main();
    }
  }

  // ══════════════════════════════════════════════════════════════════════════
  // FLUJO 1: CREAR CUENTA — un solo testWidgets, sin reinicios entre pasos
  // ══════════════════════════════════════════════════════════════════════════
  group('Flujo 1 — Crear cuenta (precondición del login)', () {
    testWidgets(
      'Alta de prospecto: splash → welcome → privacidad → propósito → celular '
      '→ OTP → documentos y datos → clave → análisis',
      (tester) async {
        runApp();

        // ── Splash ────────────────────────────────────────────────────────
        await tester.waitSplash();
        _log('Splash superado');

        // ── Welcome de marca ──────────────────────────────────────────────
        expect(find.text('Empezar solicitud'), findsOneWidget,
            reason: 'Tras el splash debe verse el Welcome de marca');
        // El alta completa hasta identidad vive en OnboardingSteps: celular →
        // privacidad → OTP. Una sola definición para los cuatro E2E.
        await tester.goToIdentityStep(phone: SharedTestState.phone);

        await tester.captureAllDocuments();
        expect(find.text('IDENTIDAD'), findsOneWidget,
            reason: 'Debe abrir la pestaña Datos con los grupos del diseño');
        _log('4 documentos capturados → OCR extraído → pestaña Datos');

        // ── Datos ─────────────────────────────────────────────────────────
        await tester.fillIdentityData(curp: SharedTestState.curp);
        _log('Datos de identidad completados');

        await tester.scrollDown(amount: 500);
        await tester.settle();
        // El botón dejó de ser "Continuar" cuando las tres pantallas de
        // identidad se fundieron en una con segmented control: ahora cierra
        // confirmando lo que el OCR leyó.
        await tester.tapButton('Todo está correcto');
        await tester.settle();
        expect(find.text('Crear cuenta'), findsOneWidget,
            reason: 'Debe navegar a la pantalla de creación de contraseña');
        _log('Datos → password screen');

        // ── Password ──────────────────────────────────────────────────────
        await tester.enterField('Contraseña', SharedTestState.password);
        await tester.pump();
        await tester.enterField('Confirmar contraseña', SharedTestState.password);
        await tester.pump();
        await tester.tapButton('Crear cuenta');
        _log('Password creada, enviando registro...');

        // "Crear cuenta" ya no lleva a una pantalla de éxito con "Ir a inicio":
        // dispara el análisis del alta —crear cuenta, consultar buró y círculo,
        // calcular capacidad de pago— y para uso propio desemboca en las
        // oportunidades. Contra el backend real esas consultas tardan, así que
        // el margen es amplio; y el anillo del análisis gira en bucle, por lo
        // que hay que sondear con `pump` y nunca con `pumpAndSettle`.
        final success = await tester.pumpUntilFound(
          find.text('Tus oportunidades'),
          maxTicks: 90,
          tick: const Duration(milliseconds: 500),
        );
        expect(success, isTrue,
            reason: 'el análisis del alta debe terminar en las oportunidades');

        SharedTestState.accountCreated = true;
        _log('✅ CREAR CUENTA EXITOSO — cuenta creada con ${SharedTestState.phone}');
      },
    );
  });

  // ══════════════════════════════════════════════════════════════════════════
  // FLUJO 2: LOGIN — postcondición: usa las credenciales del flujo 1
  // ══════════════════════════════════════════════════════════════════════════
  group('Flujo 2 — Login (postcondición: requiere cuenta del flujo 1)', () {
    testWidgets(
      'Login: splash → pantalla de login → ingresar con cuenta creada → home',
      (tester) async {
        if (mode == BackendMode.local && !SharedTestState.accountCreated) {
          _log('⚠️  El flujo de crear cuenta no completó — '
              'verificando login con credenciales de TestData en local...');
        }

        runApp();

        // ── Splash ────────────────────────────────────────────────────────
        await tester.waitSplash();
        _log('Splash superado');

        // ── Welcome de marca → login ─────────────────────────────────────
        await tester.tapButton('Ya tengo cuenta · Entrar');
        await tester.settle();
        expect(find.text('Entrar'), findsOneWidget,
            reason: 'La pantalla de login debe ser visible');
        _log('Login screen OK — '
            'modo: ${mode.label} | '
            'teléfono: ${SharedTestState.phone}');

        // El login del rediseño etiqueta sus campos en versalitas.
        await tester.enterField('CELULAR', SharedTestState.phone);
        await tester.enterField('CONTRASEÑA', SharedTestState.password);
        await tester.pump();

        await tester.tapButton('Entrar');
        _log('Credenciales enviadas, esperando respuesta...');

        // Esperar navegación al home (HTTP call en local, mock ~700ms)
        final homeFound = await tester.pumpUntilFound(
          _homeScreenFinder(),
          maxTicks: 30,
          tick: const Duration(milliseconds: 500),
        );

        if (!homeFound) {
          // Captura de estado para diagnosticar
          final currentTexts = find
              .byType(Text)
              .evaluate()
              .map((e) => (e.widget as Text).data)
              .where((t) => t != null && t.isNotEmpty)
              .take(10)
              .toList();
          // ignore: avoid_print
          print('Textos visibles en pantalla: $currentTexts');
        }

        expect(homeFound, isTrue,
            reason: 'Después de login debe mostrarse el home '
                '(CTA de crédito o tarjeta de crédito activa)');

        _log('✅ LOGIN EXITOSO → home mostrado');
        // Verificar que el home tiene algún indicador de la app
        final isHome = _homeScreenFinder().evaluate().isNotEmpty;
        expect(isHome, isTrue);
      },
    );

    testWidgets(
      'Login fallido: contraseña incorrecta permanece en login',
      (tester) async {
        runApp();
        await tester.waitSplash();

        await tester.tapButton('Ya tengo cuenta · Entrar');
        await tester.settle();
        expect(find.text('Entrar'), findsOneWidget);
        await tester.enterField('CELULAR', SharedTestState.phone);
        await tester.enterField('CONTRASEÑA', 'X'); // muy corta → falla
        await tester.pump();

        await tester.tapButton('Entrar');
        // Esperar respuesta negativa
        for (int i = 0; i < 10; i++) {
          await tester.pump(const Duration(milliseconds: 300));
          if (find.text('Entrar').evaluate().isNotEmpty) break;
        }

        expect(find.text('Entrar'), findsAtLeastNWidgets(1),
            reason: 'Con credenciales inválidas debe permanecer en login');
        _log('✅ LOGIN FALLIDO correcto — permanece en pantalla de login');
      },
    );
  });
}

// ── Helpers de pantalla ──────────────────────────────────────────────────────

/// Finder que reconoce el home en cualquier estado de crédito (ADR-001):
/// - Sin crédito → CTA "Solicitar crédito"
/// - Con crédito → tarjeta "Mi Crédito Revolvente"
Finder _homeScreenFinder() => find.byWidgetPredicate((w) {
      if (w is! Text || w.data == null) return false;
      final t = w.data!;
      return t.contains('Solicitar crédito') ||
          t.contains('Solicita tu crédito') ||
          t.contains('Mi Crédito Revolvente') ||
          t.contains('Laura') ||
          t.contains('Hola,');
    });

void _log(String msg) {
  // ignore: avoid_print
  print('[E2E] $msg');
}
