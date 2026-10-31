/// Pasos del caso 1 que se repiten entre actos: entrar con la cuenta del alta, y pedir el préstamo
/// personal desde Oportunidades hasta tocar «Revisar solicitud».
///
/// Se repiten porque la solicitud se intenta dos veces: la primera la detiene la compuerta de
/// identidad —sin proveedor biométrico, toda identidad la confirma una persona— y la segunda, ya
/// con el dictamen, pasa. Duplicarlos dejaría dos maneras de llegar al mismo botón.
library;

// widgets.dart cubre foundation y además Scrollable/AxisDirection, que hacen falta para
// recorrer a mano el carrusel horizontal de productos.
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/test_helpers.dart';
import 'gestos.dart';
import 'soporte.dart';

/// Login real con la cuenta que se creó en el alta; termina en el home.
Future<void> entrar(WidgetTester tester, String phone, String password) async {
  await tester.tapButton('Ya tengo cuenta · Entrar');
  await tester.settle();
  await tester.enterField('CELULAR', phone);
  await tester.enterField('CONTRASEÑA', password);
  await tester.pump();
  await tester.tapButton('Entrar');
  final enHome = await tester.pumpUntilFound(find.textContaining('Hola,'),
      maxTicks: 40, tick: const Duration(milliseconds: 500));
  expect(enHome, isTrue, reason: 'el login real debe llevar al home');
}

/// De la pestaña Oportunidades al configurador, y «Revisar solicitud».
Future<void> solicitarPrestamoPersonal(WidgetTester tester) async {
  await tester.tap(find.text('Oportunidades'));
  await tester.pumpAndSettle(const Duration(seconds: 2));
  final enCatalogo = await tester.pumpUntilFound(find.text('Tus oportunidades'),
      maxTicks: 30, tick: const Duration(milliseconds: 500));
  expect(enCatalogo, isTrue, reason: 'la pestaña Oportunidades abre el catálogo');
  expect(find.text('PUEDES SOLICITARLAS'), findsOneWidget,
      reason: 'el producto está sujeto a revisión, no aprobado de antemano');
  paso('CHECKPOINT — catálogo con la sección PUEDES SOLICITARLAS');
  await tester.respira(const Duration(seconds: 3));

  // Las tarjetas viven en un carrusel **horizontal** (`_Section` →
  // `ListView(scrollDirection: Axis.horizontal)`, product_selection_screen.dart:310-313), y
  // con los seis productos B2C en «PUEDES SOLICITARLAS» el préstamo personal es la cuarta:
  // nace fuera de pantalla por la derecha. `findScrolling` arrastra en vertical por defecto
  // sobre `Scrollable.first` —la lista de secciones—, así que nunca lo traía.
  final carrusel = find.byWidgetPredicate((w) =>
      w is Scrollable &&
      (w.axisDirection == AxisDirection.right ||
          w.axisDirection == AxisDirection.left));
  final producto = find.textContaining('Préstamo Personal');
  final hay = await tester.findScrolling(
    producto,
    scrollable: carrusel.first,
    delta: const Offset(-260, 0),
  );
  tester.volcarPantalla();
  expect(hay, isTrue, reason: 'el catálogo real ofrece el préstamo personal');
  await tester.ensureVisible(producto.first);
  await tester.pumpAndSettle();
  await tester.tap(producto.first, warnIfMissed: false);
  await tester.pumpAndSettle(const Duration(seconds: 2));

  await tester.scrollAndTap(find.textContaining('Continuar con'));
  await tester.pumpAndSettle(const Duration(seconds: 3));

  expect(find.text('MONTO DEL PRÉSTAMO'), findsOneWidget);
  paso('CHECKPOINT — configurador de monto y plazo');
  await tester.respira(const Duration(seconds: 3));

  await tester.scrollAndTap(find.text('Revisar solicitud'));
  await tester.pumpAndSettle(const Duration(seconds: 2));
}
