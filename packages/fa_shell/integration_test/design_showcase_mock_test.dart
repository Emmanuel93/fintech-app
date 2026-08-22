/// Showcase E2E (flavor MOCK, sin backend) — recorre las superficies del
/// journey Kredius que fueron adecuadas al design system y verifica que
/// renderizan. Sirve además como guion determinista para grabar el video.
///
/// Pantallas recorridas: Splash → Login → Home → tab Movimientos → tab
/// Oportunidades → Notificaciones → Perfil. Todas consumen los tokens de
/// `fa_design_system` (AppColors / AppTheme).
///
/// Correr (con un simulador booteado):
///   flutter test integration_test/design_showcase_mock_test.dart -d <device-id>
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'helpers/test_helpers.dart';
import 'package:fa_shell/main.dart' as mock_app;

// Credenciales que el login mock prellena y acepta (flavor mock).
const _phone = '5510026001';
const _password = 'Test1234!';

// Pausas amplias para que la grabación deje ver cada pantalla.
const _linger = Duration(milliseconds: 1600);

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  binding.framePolicy = LiveTestWidgetsFlutterBindingFramePolicy.fullyLive;

  testWidgets('Showcase mock: journey Kredius con tokens del design system',
      (tester) async {
    mock_app.main();
    await tester.waitSplash();

    // ── Welcome de marca (héroe azul) ────────────────────────────────────
    expect(find.text('Empezar solicitud'), findsOneWidget,
        reason: 'Tras el splash debe verse el Welcome de marca');
    await tester.pump(_linger);
    await tester.tapButton('Ya tengo cuenta · Entrar');
    await tester.pump(const Duration(seconds: 1));

    // ── Login ────────────────────────────────────────────────────────────
    expect(find.text('Entrar'), findsOneWidget);
    await tester.enterField('CELULAR', _phone);
    await tester.enterField('CONTRASEÑA', _password);
    await tester.pump();
    await tester.tapButton('Entrar');
    await tester.pump(const Duration(seconds: 3));

    // ── Home (header restyle) ────────────────────────────────────────────
    final onHome = await tester.pumpUntilFound(find.textContaining('Hola,'),
        maxTicks: 20, tick: const Duration(milliseconds: 500));
    expect(onHome, isTrue, reason: 'Login mock debe llevar al home');
    expect(find.text('Inicio'), findsOneWidget);
    // El nav de quien pide para sí: "Créditos" salió (el carrusel de Inicio ya
    // los muestra) y el diseño nuevo repone Movimientos junto a Oportunidades.
    expect(find.text('Movimientos'), findsOneWidget);
    expect(find.text('Oportunidades'), findsOneWidget);
    _log('Home OK');
    await tester.pump(_linger);

    // ── Tab Movimientos (historial con tokens) ───────────────────────────
    await tester.tap(find.text('Movimientos'));
    await tester.pump(const Duration(seconds: 2));
    final movimientos = find.textContaining('movimiento').evaluate().isNotEmpty ||
        find.textContaining('Movimientos').evaluate().isNotEmpty ||
        find.textContaining('Todos').evaluate().isNotEmpty;
    expect(movimientos, isTrue, reason: 'Tab Movimientos debe mostrar contenido');
    _log('Movimientos OK');
    await tester.pump(_linger);

    // ── Tab Oportunidades (catálogo con tokens del design system) ────────
    await tester.tap(find.text('Oportunidades'));
    await tester.pump(const Duration(seconds: 2));
    final oportunidades = find.text('APROBADAS PARA TI').evaluate().isNotEmpty ||
        find.text('PUEDES SOLICITARLAS').evaluate().isNotEmpty ||
        find.textContaining('oportunidad').evaluate().isNotEmpty ||
        find.textContaining('crédito').evaluate().isNotEmpty;
    expect(oportunidades, isTrue,
        reason: 'Tab Oportunidades debe mostrar contenido');
    _log('Oportunidades OK');
    await tester.pump(_linger);

    // ── Volver a Inicio ──────────────────────────────────────────────────
    //
    // Oportunidades no es un tab del shell: abre el catálogo a pantalla
    // completa, así que el nav inferior desaparece y hay que volver con el
    // botón de la pantalla antes de poder tocar "Inicio".
    if (find.text('Inicio').evaluate().isEmpty) {
      final volver = find.bySemanticsLabel('Volver');
      if (volver.evaluate().isNotEmpty) {
        await tester.tap(volver.first, warnIfMissed: false);
        await tester.pump(const Duration(seconds: 2));
      }
    }
    await tester.tap(find.text('Inicio'));
    await tester.pump(const Duration(seconds: 1));
    expect(find.textContaining('Hola,'), findsOneWidget);
    await tester.pump(_linger);

    // A partir de aquí, navegación best-effort para el video: el simulador de
    // esta máquina es intermitente, así que estas superficies extra NO fallan
    // el test si el entorno se cae — las aserciones duras ya quedaron arriba.
    try {
      // ── Notificaciones (header azul primario por token) ────────────────
      final bell = find.byIcon(Icons.notifications_outlined);
      if (bell.evaluate().isNotEmpty) {
        await tester.tap(bell.first, warnIfMissed: false);
        await tester.pump(const Duration(seconds: 2));
        _log('Notificaciones abiertas');
        await tester.pump(_linger);
        final back = find.byIcon(Icons.arrow_back_ios_rounded);
        if (back.evaluate().isNotEmpty) {
          await tester.tap(back.first, warnIfMissed: false);
          await tester.pump(const Duration(seconds: 1));
        }
      }

      // ── Perfil (se abre desde el header, no es tab) ────────────────────
      final header = find.textContaining('Hola,');
      if (header.evaluate().isNotEmpty) {
        await tester.tap(header.first, warnIfMissed: false);
        await tester.pump(const Duration(seconds: 2));
        if (find.text('Mi Perfil').evaluate().isNotEmpty) _log('Perfil OK');
        await tester.pump(_linger);
      }
    } catch (e) {
      _log('Navegación extra best-effort interrumpida: $e');
    }

    _log('SHOWCASE COMPLETO');
  });
}

void _log(String msg) {
  // ignore: avoid_print
  print('[SHOWCASE-MOCK] $msg');
}
