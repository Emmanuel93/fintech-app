/// Los 32 estados tienen que ser **alcanzables**, no sólo estar en la lista.
///
/// Este test nació como diagnóstico de un bug real: con un
/// `DropdownButtonFormField` acotado por `menuMaxHeight`, el menú construía
/// sólo los primeros items y llegar a Sinaloa (#25) o Sonora (#26) exigía
/// arrastrar a ciegas dentro de un menú flotante.
///
/// Ahora recorre la hoja de arriba abajo y **exige ver las 32 entidades**, una
/// por una, además de comprobar los dos atajos: el índice alfabético y el
/// buscador. Si alguna deja de ser alcanzable, esto falla con su nombre.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'helpers/image_picker_mock.dart';
import 'helpers/test_helpers.dart';
import 'helpers/onboarding_steps.dart';
import 'package:fa_shell/main.dart' as mock_app;

/// Las 32 entidades federativas, en el orden en que las lista la app.
const _estados = <String>[
  'Aguascalientes', 'Baja California', 'Baja California Sur',
  'Campeche', 'Chiapas', 'Chihuahua', 'Ciudad de México', 'Coahuila',
  'Colima', 'Durango', 'Estado de México', 'Guanajuato', 'Guerrero',
  'Hidalgo', 'Jalisco', 'Michoacán', 'Morelos', 'Nayarit',
  'Nuevo León', 'Oaxaca', 'Puebla', 'Querétaro', 'Quintana Roo',
  'San Luis Potosí', 'Sinaloa', 'Sonora', 'Tabasco', 'Tamaulipas',
  'Tlaxcala', 'Veracruz', 'Yucatán', 'Zacatecas',
];

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  binding.framePolicy = LiveTestWidgetsFlutterBindingFramePolicy.fullyLive;

  setUpAll(() async {
    await FakeImagePickerPlatform.setup();
  });

  testWidgets('las 32 entidades se ven scrolleando la hoja', (tester) async {
    // Flavor mock: que los 32 estados sean alcanzables es asunto del selector,
    // no del BFF, y así el test corre en cualquier máquina.
    mock_app.main();
    await tester.waitSplash();

    await tester.goToIdentityStep();
    await tester.captureAllDocuments();

    expect(find.text('IDENTIDAD'), findsOneWidget);
    _log('CHECKPOINT — En pantalla de datos personales');

    // El de **domicilio**: llega vacío, así que abre desde el principio y hay
    // que recorrer los 32 de verdad. (El de nacimiento lo prellena el OCR.)
    final campo = find.byKey(const ValueKey('ds-field:Estado'));
    expect(campo, findsOneWidget, reason: 'debe existir el selector de estado');
    await tester.ensureVisible(campo);
    await tester.pumpAndSettle();
    await tester.tap(campo, warnIfMissed: false);
    await tester.pumpAndSettle();

    // La hoja declara cuántas opciones tiene: si dice otra cosa, la lista se
    // quedó corta antes de llegar a la UI.
    expect(find.text('32 opciones'), findsOneWidget,
        reason: 'la hoja debe declarar las 32 entidades');

    // ── El recorrido completo ─────────────────────────────────────────────
    //
    // Se arrastra de arriba abajo anotando lo que se va montando. La lista es
    // perezosa: sólo construye lo visible, así que "verlas todas" únicamente
    // se puede afirmar recorriéndola.
    final lista = find.byType(Scrollable).last;
    final vistos = <String>{};

    // Ojo: el campo "Estado de nacimiento" que queda **detrás** de la hoja ya
    // trae "Sinaloa" del OCR, así que buscar por texto suelto daría un falso
    // positivo. Todo lo que se afirme sobre la lista se acota a la hoja.
    Finder enLaHoja(String texto) =>
        find.descendant(of: find.byType(Scrollbar), matching: find.text(texto));

    void anotarVisibles() {
      for (final estado in _estados) {
        if (enLaHoja(estado).evaluate().isNotEmpty) vistos.add(estado);
      }
    }

    anotarVisibles();
    _log('Visibles al abrir: ${vistos.length} de 32');

    for (var paso = 0; paso < 40 && vistos.length < _estados.length; paso++) {
      await tester.drag(lista, const Offset(0, -200));
      await tester.pumpAndSettle();
      anotarVisibles();
    }

    final faltantes = _estados.where((e) => !vistos.contains(e)).toList();
    expect(faltantes, isEmpty,
        reason: 'no se alcanzaron scrolleando: ${faltantes.join(", ")}');
    _log('CHECKPOINT — Las 32 entidades se vieron scrolleando');

    // ── Bajar a Sinaloa y elegirla ahí mismo ──────────────────────────────
    //
    // Es el caso que se reportó: sin buscar ni atajos, arrastrando hasta la
    // #25 y tocándola.
    await tester.drag(lista, const Offset(0, 4000)); // de vuelta al inicio
    await tester.pumpAndSettle();
    expect(enLaHoja('Aguascalientes'), findsOneWidget);
    expect(enLaHoja('Sinaloa'), findsNothing,
        reason: 'premisa: desde arriba, Sinaloa no está a la vista');

    var arrastres = 0;
    while (enLaHoja('Sinaloa').evaluate().isEmpty && arrastres < 40) {
      await tester.drag(lista, const Offset(0, -200));
      await tester.pumpAndSettle();
      arrastres++;
    }
    expect(enLaHoja('Sinaloa'), findsOneWidget,
        reason: 'Sinaloa debe aparecer bajando la lista');
    _log('CHECKPOINT — Sinaloa a la vista tras $arrastres arrastres');

    await tester.tap(enLaHoja('Sinaloa'));
    await tester.pumpAndSettle();
    // Se afirma sobre **este** campo: el de nacimiento también dice Sinaloa.
    expect(find.descendant(of: campo, matching: find.text('Sinaloa')),
        findsOneWidget,
        reason: 'el campo de domicilio debe quedar con Sinaloa');
    _log('CHECKPOINT — Sinaloa seleccionada bajando con scroll');

    // ── Atajo: el índice alfabético ───────────────────────────────────────
    //
    // Llegar a la #25 no debería costar $arrastres arrastres cada vez.
    await tester.tap(campo, warnIfMissed: false);
    await tester.pumpAndSettle();
    await tester.drag(lista, const Offset(0, 4000));
    await tester.pumpAndSettle();
    expect(enLaHoja('Sinaloa'), findsNothing);

    final letraS = find.text('S');
    expect(letraS, findsOneWidget, reason: 'debe existir el índice alfabético');
    await tester.tap(letraS);
    await tester.pumpAndSettle();
    expect(enLaHoja('Sinaloa'), findsOneWidget,
        reason: 'tocar la S debe traer Sinaloa a la vista de un toque');
    _log('CHECKPOINT — Sinaloa alcanzada con el índice alfabético');
    await tester.tap(enLaHoja('Sinaloa'));
    await tester.pumpAndSettle();

    // ── Atajo 2: el buscador ──────────────────────────────────────────────
    //
    // Sin acentos y en minúsculas: nadie escribe "Michoacán" con tilde en un
    // teclado de teléfono.
    for (final (estado, consulta) in const [
      ('Sonora', 'son'), // #26
      ('Michoacán', 'michoacan'), // #16
      ('Nuevo León', 'nuevo leon'), // #19
      ('Zacatecas', 'zacate'), // #32
    ]) {
      await tester.tap(campo, warnIfMissed: false);
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField).last, consulta);
      await tester.pumpAndSettle();
      final enLista = find.descendant(
          of: find.byType(Scrollbar), matching: find.text(estado));
      expect(enLista, findsOneWidget,
          reason: 'buscar "$consulta" debe traer $estado');
      await tester.tap(enLista);
      await tester.pumpAndSettle();
    }
    _log('CHECKPOINT — Buscador tolerante a acentos');

    // ── Reabrir cae en lo ya elegido ──────────────────────────────────────
    await tester.tap(campo, warnIfMissed: false);
    await tester.pumpAndSettle();
    expect(
        find.descendant(
            of: find.byType(Scrollbar), matching: find.text('Zacatecas')),
        findsOneWidget,
        reason: 'reabrir debe mostrar lo que ya estaba respondido');
    _log('CHECKPOINT — Reabre posicionada en lo elegido');

    _log('✅ DIAGNÓSTICO COMPLETO');
  });
}

void _log(String msg) {
  // ignore: avoid_print
  print('[STATES-CHECK] $msg');
}
