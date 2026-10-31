import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fa_design_system/fa_design_system.dart';

/// La barra de marca global — Journey App L63–L82 / L1732–L1746.
Widget _app(Widget child) => MediaQuery(
      data: const MediaQueryData(size: Size(402, 874)),
      child: MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(body: child),
      ),
    );

void main() {
  group('DsBrandBar', () {
    testWidgets('siempre lleva el isotipo y el wordmark', (tester) async {
      await tester.pumpWidget(_app(const DsBrandBar(initials: 'LM')));
      expect(find.byType(KrediusMark), findsOneWidget);
      expect(find.text('Kredius'), findsOneWidget);
    });

    testWidgets('fuera de la app esconde avatar y campana pero guarda su lugar',
        (tester) async {
      await tester.pumpWidget(_app(const DsBrandBar(initials: 'LM')));

      // `visibility:hidden` del diseño: no se ve, pero el hueco sigue ahí para
      // que el logo no se descentre entre pantallas.
      final visibles = tester
          .widgetList<Visibility>(find.byType(Visibility))
          .toList();
      expect(visibles, hasLength(2));
      expect(visibles.every((v) => !v.visible), isTrue);
      expect(visibles.every((v) => v.maintainSize), isTrue);
    });

    testWidgets('en el home muestra las iniciales y la campana', (tester) async {
      var perfil = 0, notifs = 0;
      await tester.pumpWidget(_app(DsBrandBar(
        initials: 'LM',
        showActions: true,
        onProfile: () => perfil++,
        onNotifications: () => notifs++,
      )));

      expect(find.text('LM'), findsOneWidget);
      expect(find.byIcon(Icons.notifications_none_rounded), findsOneWidget);

      await tester.tap(find.text('LM'));
      await tester.tap(find.byIcon(Icons.notifications_none_rounded));
      await tester.pump();
      expect(perfil, 1);
      expect(notifs, 1);
    });

    testWidgets('el punto de no leídas se apaga cuando no hay', (tester) async {
      await tester.pumpWidget(_app(const DsBrandBar(
        initials: 'LM',
        showActions: true,
        hasUnread: false,
      )));
      final semantics = tester.widget<Semantics>(
        find.ancestor(
          of: find.byIcon(Icons.notifications_none_rounded),
          matching: find.byType(Semantics),
        ).first,
      );
      expect(semantics.properties.label, 'Notificaciones');
    });

    test('las iniciales salen del nombre completo', () {
      expect(DsBrandBar.initialsOf('Laura Méndez Soto'), 'LM');
      expect(DsBrandBar.initialsOf('Laura'), 'LA');
      expect(DsBrandBar.initialsOf('  '), '—');
    });
  });
}
