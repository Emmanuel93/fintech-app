/// Home tabs E2E — verifica el bottom-tab nav real (Inicio/Movimientos/
/// Oportunidades) agregado sobre `IModule.ownedTabs`/`buildTabScreen`.
///
/// Usa el usuario de prueba con journey completo del tracker
/// (`docs/INTEGRATION_TRACKER.md`: B2C, REVOLVING_LINE activa, wallet
/// fondeado) — login directo, no requiere correr todo el alta.
///
/// Correr:
///   flutter test integration_test/home_tabs_navigation_test.dart \
///     -d <device-id> --dart-define=BFF_URL=http://mobile.localhost:8090
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'helpers/test_helpers.dart';
import 'package:fa_shell/main_local.dart' as local_app;

const _phone = '5510026001';
const _password = 'Test1234!';

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  binding.framePolicy = LiveTestWidgetsFlutterBindingFramePolicy.fullyLive;

  testWidgets('Home: 3 tabs navegables, Perfil sigue siendo header-only',
      (tester) async {
    local_app.main();
    await tester.waitSplash();

    // Splash → Welcome de marca → "Ya tengo cuenta" → login
    await tester.tapButton('Ya tengo cuenta · Entrar');
    await tester.settle();

    expect(find.text('Entrar'), findsOneWidget);
    await tester.enterField('CELULAR', _phone);
    await tester.enterField('CONTRASEÑA', _password);
    await tester.pump();
    await tester.tapButton('Entrar');
    await tester.pump(const Duration(seconds: 4));

    // Home autenticado — el header muestra "Hola, {nombre}".
    final onHome = await tester.pumpUntilFound(find.textContaining('Hola,'),
        maxTicks: 20, tick: const Duration(milliseconds: 500));
    expect(onHome, isTrue, reason: 'Login debe llevar al home autenticado');
    _log('✅ Home cargado');

    // Los 3 destinos del bottom nav existen — por label, no por índice.
    expect(find.text('Inicio'), findsOneWidget);
    expect(find.text('Movimientos'), findsOneWidget);
    expect(find.text('Oportunidades'), findsOneWidget);
    // Perfil NO es un destino del bottom nav — solo se llega por el header.
    expect(find.text('Perfil'), findsNothing);
    _log('CHECKPOINT — 3 destinos confirmados, Perfil no es tab');

    // ── Tab Movimientos ───────────────────────────────────────────────────
    await tester.tap(find.text('Movimientos'));
    await tester.pump(const Duration(seconds: 2));
    expect(find.text('Disposiciones'), findsOneWidget,
        reason: 'Tab Movimientos debe mostrar los filtros por categoría');
    _log('CHECKPOINT — Tab Movimientos con filtros visibles');

    // ── De vuelta a Inicio: el estado del tab se preserva (IndexedStack) ───
    await tester.tap(find.text('Inicio'));
    await tester.pump(const Duration(seconds: 1));
    expect(find.textContaining('Hola,'), findsOneWidget);
    _log('CHECKPOINT — Regresó a Inicio sin perder el header');

    // ── Perfil: se abre desde el header, no desde el bottom nav ────────────
    await tester.tap(find.textContaining('Hola,'));
    await tester.pump(const Duration(seconds: 2));
    final onProfile = find.text('Mi Perfil').evaluate().isNotEmpty;
    expect(onProfile, isTrue, reason: 'Tap en el header debe abrir Mi Perfil');
    _log('✅✅✅ HOME TABS E2E COMPLETO');
  });
}

void _log(String msg) {
  // ignore: avoid_print
  print('[HOME-TABS-E2E] $msg');
}
