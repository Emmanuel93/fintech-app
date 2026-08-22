/// El perfil, en mock: que abra con el expediente del diseño y no con el
/// héroe azul del lenguaje anterior.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:fa_design_system/fa_design_system.dart';

import 'helpers/test_helpers.dart';
import 'package:fa_shell/main.dart' as mock_app;

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  binding.framePolicy = LiveTestWidgetsFlutterBindingFramePolicy.fullyLive;

  testWidgets('el perfil abre como expediente claro con sus grupos',
      (tester) async {
    mock_app.main();
    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();

    await tester.tapButton('Ya tengo cuenta · Entrar');
    await tester.pumpAndSettle();
    await tester.enterField('CELULAR', '5510026001');
    await tester.enterField('CONTRASEÑA', 'SecurePass1!');
    await tester.pumpAndSettle();
    await tester.tapButton('Entrar');
    await tester.pumpUntilFound(find.textContaining('Hola,'),
        maxTicks: 30, tick: const Duration(milliseconds: 400));

    // El avatar de la barra de marca es la puerta al perfil.
    await tester.tap(find
        .descendant(
          of: find.byType(DsBrandBar),
          matching: find.byType(GestureDetector),
        )
        .first);
    await tester.pumpAndSettle(const Duration(seconds: 2));

    expect(find.text('Mi perfil'), findsOneWidget);

    // Los grupos del diseño (L957–L970), con su sello de origen.
    for (final grupo in ['IDENTIDAD', 'CLAVES FISCALES', 'DOMICILIO']) {
      expect(find.text(grupo), findsOneWidget, reason: 'falta el grupo $grupo');
    }
    expect(find.text('INE · OCR'), findsOneWidget,
        reason: 'cada grupo dice de dónde salió el dato');
    // Los contratos cierran el expediente, así que quedan fuera del viewport.
    final contratos = find.text('CONTRATOS VIGENTES');
    await tester.scrollUntilVisible(contratos, 300,
        scrollable: find.byType(Scrollable).last);
    expect(contratos, findsOneWidget);

    // Y sigue siendo una pantalla clara: el azul quedó para el dinero.
    final scaffold = tester.widget<Scaffold>(find.byType(Scaffold).last);
    expect(scaffold.backgroundColor, AppColors.surfaceVariant);
  });
}
