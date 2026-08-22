/// Smoke test de los widgets de marca Kredius — que monten y pinten sin
/// excepción en las tres variantes oficiales del isotipo, y que el wordmark
/// y el lockup rendericen el texto "Kredius".
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fa_design_system/fa_design_system.dart';

Widget _wrap(Widget child) => MaterialApp(
      theme: AppTheme.light,
      home: Scaffold(body: Center(child: child)),
    );

void main() {
  testWidgets('KrediusMark monta en badge / onDark / onLight', (tester) async {
    for (final mark in const [
      KrediusMark(size: 64),
      KrediusMark.badge(size: 64),
      KrediusMark.onDark(size: 64),
      KrediusMark.onLight(size: 64),
    ]) {
      await tester.pumpWidget(_wrap(mark));
      expect(find.byType(KrediusMark), findsOneWidget);
      expect(tester.takeException(), isNull);
    }
  });

  testWidgets('KrediusWordmark renderiza "Kredius"', (tester) async {
    await tester.pumpWidget(_wrap(const KrediusWordmark()));
    expect(find.text('Kredius'), findsOneWidget);
  });

  testWidgets('KrediusBrand renderiza marca + wordmark (+ tagline)', (tester) async {
    await tester.pumpWidget(_wrap(
      const KrediusBrand(onDark: true, tagline: 'CRÉDITO CLARO'),
    ));
    expect(find.byType(KrediusMark), findsOneWidget);
    expect(find.text('Kredius'), findsOneWidget);
    expect(find.text('CRÉDITO CLARO'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
