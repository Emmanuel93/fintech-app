/// Smoke test del journey Kredius sobre el flavor mock.
///
/// No sustituye a los E2E de `integration_test/` (esos corren en dispositivo y
/// atraviesan el BFF): esto verifica que las pantallas del rediseño **montan
/// de verdad** y que las piezas del diseño están donde deben, en un test que
/// corre en CI sin emulador.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:fa_core/fa_core.dart';
import 'package:fa_design_system/fa_design_system.dart';

import 'package:fa_shell/main.dart';

Future<void> _bootApp(WidgetTester tester, {Size? size}) async {
  // Por defecto, el lienzo del prototipo. La superficie de test de Flutter es
  // 800×600 (apaisada), que no representa a ningún teléfono y deja el CTA
  // fuera del viewport.
  tester.view.physicalSize = size ?? const Size(402, 874);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  AppConfig.setup(flavor: AppFlavor.mock);
  await initializeDateFormatting('es_MX', null);
  await tester.pumpWidget(const KrediusApp());
  // El splash espera antes de navegar al welcome.
  await tester.pump(const Duration(seconds: 3));
  await tester.pumpAndSettle();
}

/// welcome → privacidad → propósito → celular → OTP → identidad.
///
/// Nada se pide antes de tener permiso para pedirlo: la autorización abre el
/// alta y el celular se verifica en cuanto se captura.
Future<void> _acceptPrivacy(WidgetTester tester) async {
  // Los dos consentimientos obligatorios viven al final de una pantalla larga
  // (documentos legales + tarjeta de SIC arriba), así que hay que traerlos al
  // viewport antes de tocarlos.
  for (final anchor in const [
    'Leí y acepto el aviso de privacidad',
    'Autorizo expresamente a Kredius',
  ]) {
    final finder = find.textContaining(anchor);
    await tester.ensureVisible(finder);
    await tester.pumpAndSettle();
    await tester.tap(finder);
    await tester.pumpAndSettle();
  }
  await tester.tap(find.text('Autorizar y continuar'));
  await tester.pumpAndSettle();
}

Future<void> _goToIdentity(WidgetTester tester) async {
  await tester.tap(find.text('Empezar solicitud'));
  await tester.pumpAndSettle();

  // Paso 1 — privacidad y autorización de consulta a SIC.
  await _acceptPrivacy(tester);

  // Paso 2 — para qué quiere el crédito.
  await tester.tap(find.text('Para mí'));
  await tester.pumpAndSettle();
  await tester.tap(find.text('Continuar'));
  await tester.pumpAndSettle();

  // Paso 3 — celular + correo. Al continuar sale el código.
  final fields = find.byType(EditableText);
  await tester.enterText(fields.at(0), '5510026001');
  await tester.pumpAndSettle();
  await tester.enterText(fields.at(1), 'test@correo.com');
  await tester.pumpAndSettle();
  await tester.tap(find.text('Continuar'));
  await tester.pumpAndSettle(const Duration(seconds: 2));

  // Paso 4 — el código, en el teclado del dispositivo sobre las cajas.
  final pin = find.descendant(
      of: find.byType(DsPinInput), matching: find.byType(EditableText));
  await tester.enterText(pin.first, '123456');
  await tester.pumpAndSettle(const Duration(seconds: 3));
}

void main() {
  testWidgets('arranca en el welcome con el lockup invertido y los 3 stats',
      (tester) async {
    await _bootApp(tester);

    expect(find.text('El dinero que necesitas, hoy.'), findsOneWidget);
    expect(find.text('Empezar solicitud'), findsOneWidget);

    // El logo del welcome es el invertido: tile blanco, K azul, brazo verde.
    final mark = tester.widget<KrediusMark>(find.byType(KrediusMark).first);
    expect(mark.badge, isTrue);
    expect(mark.badgeColor, AppColors.surface);
    expect(mark.strokeColor, AppColors.primary);
    expect(mark.armColor, AppColors.accentGreen);

    // Los stats del prototipo, no los que traía la app.
    expect(find.text('3 min'), findsOneWidget);
    expect(find.text('15 min'), findsOneWidget);
    expect(find.text('SOLICITUD'), findsOneWidget);
    expect(find.text('APERTURA'), findsOneWidget);
  });

  testWidgets('welcome → login: héroe azul con el mismo lockup invertido',
      (tester) async {
    await _bootApp(tester);

    // "Ya tengo cuenta · Entrar" es un Text.rich (la palabra "Entrar" va en
    // negritas), así que hay que buscar dentro del RichText.
    await tester.tap(find.textContaining('Ya tengo cuenta', findRichText: true));
    await tester.pumpAndSettle();

    expect(find.text('Qué gusto verte otra vez.'), findsOneWidget);
    expect(find.text('CELULAR'), findsOneWidget);
    expect(find.text('O ENTRA CON'), findsOneWidget);

    final mark = tester.widget<KrediusMark>(find.byType(KrediusMark).first);
    expect(mark.badgeColor, AppColors.surface,
        reason: 'el login también usa el tratamiento invertido');
  });

  testWidgets('el alta abre con la privacidad y las dos SIC nombradas',
      (tester) async {
    await _bootApp(tester);

    await tester.tap(find.text('Empezar solicitud'));
    await tester.pumpAndSettle();

    // Antes de pedir un solo dato: quién va a consultar qué, y con permiso.
    expect(find.text('Tu privacidad y tu autorización'), findsOneWidget);
    // Se dice quién va a consultar el historial, con nombre.
    expect(find.text('Buró de crédito'), findsOneWidget);
    expect(find.text('Círculo de crédito'), findsOneWidget);
    // Dos obligatorios, uno opcional.
    expect(find.text('OBLIGATORIO'), findsNWidgets(2));
    expect(find.text('OPCIONAL'), findsOneWidget);
  });

  testWidgets('tras autorizar, el alta pregunta para qué es el crédito',
      (tester) async {
    await _bootApp(tester);

    await tester.tap(find.text('Empezar solicitud'));
    await tester.pumpAndSettle();
    await _acceptPrivacy(tester);

    // El propósito gobierna qué productos se evalúan, así que va antes de
    // cualquier captura de datos.
    expect(find.text('¿Cómo vas a usar tu crédito?'), findsOneWidget);
    expect(find.text('Para mí'), findsOneWidget);
    expect(find.text('Para colocar a terceros'), findsOneWidget);

    // Sin elegir, el CTA está apagado.
    final cta = find.widgetWithText(DsButton, 'Continuar');
    expect(tester.widget<DsButton>(cta).onPressed, isNull);

    await tester.tap(find.text('Para mí'));
    await tester.pumpAndSettle();
    expect(tester.widget<DsButton>(cta).onPressed, isNotNull);

    await tester.tap(find.text('Continuar'));
    await tester.pumpAndSettle();
    expect(find.text('¿A qué celular te mandamos el código?'), findsOneWidget);
    expect(find.text('CORREO ELECTRÓNICO'), findsOneWidget,
        reason: 'el correo se captura junto al celular');
  });

  testWidgets('identidad: Documentos va primero y Datos queda bloqueada',
      (tester) async {
    await _bootApp(tester);
    await _goToIdentity(tester);

    expect(find.text('Sube tus documentos'), findsOneWidget);

    // El orden invertido respecto del prototipo: Documentos antes que Datos.
    final tabs = tester.widget<DsSegmentedTabs>(find.byType(DsSegmentedTabs));
    expect(tabs.labels, ['1 · Documentos', '2 · Verifica tus datos']);
    expect(tabs.index, 0, reason: 'arranca en Documentos');
    expect(tabs.enabled, [true, false],
        reason: 'Datos no se abre hasta tener los documentos');

    // Los cuatro documentos del diseño, en su orden.
    for (final doc in const [
      'INE · frente',
      'INE · reverso',
      'Selfie de vida',
      'Comprobante de domicilio',
    ]) {
      expect(find.text(doc), findsOneWidget, reason: 'falta "$doc"');
    }
    expect(find.text('CAPTURAR'), findsNWidgets(4));

    // La secuencia causal: el INE va en su propio grupo con la tarjeta de OCR
    // pegada debajo, y selfie + comprobante en el segundo.
    expect(find.text('1 · TU IDENTIFICACIÓN'), findsOneWidget);
    expect(find.text('2 · PRUEBA DE VIDA Y DOMICILIO'), findsOneWidget);
    expect(find.text('LECTURA AUTOMÁTICA (OCR)'), findsOneWidget);

    final ocrY = tester.getTopLeft(find.text('LECTURA AUTOMÁTICA (OCR)')).dy;
    expect(ocrY, greaterThan(tester.getTopLeft(find.text('INE · reverso')).dy),
        reason: 'la tarjeta de OCR va DESPUÉS del par de INE');
    expect(ocrY, lessThan(tester.getTopLeft(find.text('Selfie de vida')).dy),
        reason: 'y ANTES de la selfie — el OCR es consecuencia del INE');

    // El CTA de la pestaña de documentos está deshabilitado sin capturas.
    final cta = tester.widget<DsButton>(
        find.widgetWithText(DsButton, 'Leer mis documentos'));
    expect(cta.onPressed, isNull);

    // Y tocar la pestaña bloqueada no cambia de pestaña.
    await tester.tap(find.text('2 · Verifica tus datos'));
    await tester.pumpAndSettle();
    expect(find.text('INE · frente'), findsOneWidget);
  });

  testWidgets('el journey no desborda en un iPhone SE', (tester) async {
    // 320×568 es el caso más apretado que soportamos; el DsHeroScaffold debe
    // dejar que el contenido haga scroll en vez de reventar el layout.
    await _bootApp(tester, size: const Size(320, 568));

    expect(find.text('Empezar solicitud'), findsOneWidget);
    expect(tester.takeException(), isNull,
        reason: 'ningún overflow al renderizar el welcome en pantalla corta');
  });

  testWidgets('el journey se acota en tablet en vez de estirarse',
      (tester) async {
    await _bootApp(tester, size: const Size(1024, 1366));

    expect(find.text('Empezar solicitud'), findsOneWidget);
    expect(tester.takeException(), isNull);

    // DsResponsiveBody centra y acota el contenido al ancho del lienzo.
    expect(find.byType(DsResponsiveBody), findsAtLeastNWidgets(1));
    final body = tester.widget<ConstrainedBox>(
      find
          .descendant(
            of: find.byType(DsResponsiveBody).first,
            matching: find.byType(ConstrainedBox),
          )
          .first,
    );
    expect(body.constraints.maxWidth, lessThan(1024));
  });
}
