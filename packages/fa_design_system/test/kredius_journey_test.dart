import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fa_design_system/fa_design_system.dart';

/// Envuelve un widget con un tamaño de pantalla concreto, para poder probar
/// cómo se comporta [DsScale] en distintos dispositivos.
Widget _app(Widget child, {Size size = const Size(402, 874)}) {
  return MediaQuery(
    data: MediaQueryData(size: size),
    child: MaterialApp(
      theme: AppTheme.light,
      home: Scaffold(body: child),
    ),
  );
}

void main() {
  group('KrediusMark.inverted — el logo del welcome y el login', () {
    testWidgets('pinta tile blanco con la K azul y el brazo verde',
        (tester) async {
      await tester.pumpWidget(_app(const KrediusMark.inverted(size: 46)));

      final mark = tester.widget<KrediusMark>(find.byType(KrediusMark));
      expect(mark.badge, isTrue,
          reason: 'la variante invertida lleva tile');
      expect(mark.badgeColor, AppColors.surface,
          reason: 'el tile es blanco, no azul (eso es el ícono de app)');
      expect(mark.strokeColor, AppColors.primary,
          reason: 'el astil y la pierna van en azul de marca');
      expect(mark.armColor, AppColors.accentGreen,
          reason: 'el brazo superior nunca cambia de color');
    });

    testWidgets('KrediusBrand.inverted usa la marca invertida y texto blanco',
        (tester) async {
      await tester.pumpWidget(_app(const KrediusBrand.inverted()));

      final mark = tester.widget<KrediusMark>(find.byType(KrediusMark));
      expect(mark.badgeColor, AppColors.surface);
      expect(mark.strokeColor, AppColors.primary);

      final wordmark = tester.widget<KrediusWordmark>(find.byType(KrediusWordmark));
      expect(wordmark.color, AppColors.onPrimary);
      // 22px sobre un isotipo de 46 en el prototipo = 0.478.
      expect(wordmark.fontSize, closeTo(46 * 0.48, 0.01));
    });

    testWidgets('onDark sigue sin tile — es otro tratamiento', (tester) async {
      await tester.pumpWidget(_app(const KrediusMark.onDark(size: 46)));
      final mark = tester.widget<KrediusMark>(find.byType(KrediusMark));
      expect(mark.badge, isFalse);
      expect(mark.strokeColor, AppColors.onPrimary);
    });
  });

  group('DsScale — adaptabilidad', () {
    test('en el lienzo de diseño no escala nada', () {
      final ds = DsScale.fromSize(const Size(402, 874));
      expect(ds.w(52), closeTo(52, 0.01));
      expect(ds.h(52), closeTo(52, 0.01));
      expect(ds.sp(16), closeTo(16, 0.01));
      expect(ds.gutter, closeTo(22, 0.01));
    });

    test('en un iPhone SE reduce, pero acotado', () {
      final ds = DsScale.fromSize(const Size(320, 568));
      // 320/402 = 0.796 → se acota a 0.86.
      expect(ds.wk, closeTo(0.86, 0.001));
      expect(ds.w(52), closeTo(52 * 0.86, 0.01));
      // La tipografía usa el rango más conservador.
      expect(ds.spk, closeTo(0.92, 0.001));
      expect(ds.isCompact, isTrue);
      expect(ds.isShort, isTrue);
    });

    test('en una tablet no deja que el diseño se estire', () {
      final ds = DsScale.fromSize(const Size(1024, 1366));
      expect(ds.wk, closeTo(1.15, 0.001), reason: 'tope superior del factor');
      expect(ds.isExpanded, isTrue);
      expect(ds.contentMaxWidth, lessThan(1024));
    });

    test('el gap superior descuenta la status bar que ya comió SafeArea', () {
      final ds = DsScale.fromSize(const Size(402, 874));
      // El diseño pide 96 desde el borde físico; 47 los cubre SafeArea.
      expect(ds.topGap, closeTo(49, 0.01));
      // Los héroes azules siguen en 92: la barra de marca va sobre el azul.
      expect(ds.topGapHero, closeTo(45, 0.01));
      // Las bandas a sangre no usan SafeArea, así que suman el inset real.
      final conNotch = DsScale.fromSize(
          const Size(402, 874), const EdgeInsets.only(top: 47));
      expect(conNotch.topGapBand, closeTo(112, 0.01));
    });

    test('bottomGap respeta el home indicator cuando existe', () {
      final withInset = DsScale.fromSize(
          const Size(402, 874), const EdgeInsets.only(bottom: 34));
      expect(withInset.bottomGap(), 34);
      final noInset = DsScale.fromSize(const Size(402, 874));
      expect(noInset.bottomGap(28), closeTo(28, 0.01));
    });
  });

  group('DsSegmentedTabs — el control del alta', () {
    testWidgets('respeta el orden Documentos → Datos y bloquea la segunda',
        (tester) async {
      var selected = -1;
      await tester.pumpWidget(_app(
        DsSegmentedTabs(
          labels: const ['Documentos', 'Datos'],
          index: 0,
          enabled: const [true, false],
          onChanged: (i) => selected = i,
        ),
      ));

      expect(find.text('Documentos'), findsOneWidget);
      expect(find.text('Datos'), findsOneWidget);
      // La pestaña bloqueada muestra candado y no notifica al tocarla.
      expect(find.byIcon(Icons.lock_outline_rounded), findsOneWidget);

      await tester.tap(find.text('Datos'));
      await tester.pump();
      expect(selected, -1, reason: 'una pestaña bloqueada no debe cambiar el tab');

      await tester.tap(find.text('Documentos'));
      await tester.pump();
      expect(selected, 0);
    });
  });

  group('DsDocumentTile', () {
    testWidgets('distingue capturado de pendiente', (tester) async {
      await tester.pumpWidget(_app(
        Column(
          children: [
            DsDocumentTile(
              name: 'INE · frente',
              hint: 'Foto nítida, sin reflejos',
              captured: true,
              onTap: () {},
            ),
            DsDocumentTile(
              name: 'Comprobante de domicilio',
              hint: 'No mayor a 3 meses',
              captured: false,
              onTap: () {},
            ),
          ],
        ),
      ));

      expect(find.text('LISTO'), findsOneWidget);
      expect(find.text('CAPTURAR'), findsOneWidget);
    });
  });

  group('DsConsentCheck', () {
    testWidgets('toda la caja es tocable, no sólo el tick', (tester) async {
      var value = false;
      await tester.pumpWidget(_app(
        StatefulBuilder(
          builder: (_, setState) => DsConsentCheck(
            value: value,
            onChanged: (v) => setState(() => value = v),
            label: 'Autorizo a Kredius a consultar mi historial crediticio.',
          ),
        ),
      ));

      // Se toca el texto, no el checkbox.
      await tester.tap(find.textContaining('Autorizo'));
      await tester.pumpAndSettle();
      expect(value, isTrue);
    });
  });

  group('Tipografía', () {
    test('el TextTheme usa Inter embebida, no la familia por defecto', () {
      final theme = AppTheme.light;
      expect(theme.textTheme.bodyMedium?.fontFamily,
          AppTextStyles.fontFamily);
      expect(AppTextStyles.fontFamily,
          'packages/fa_design_system/Inter',
          reason: 'la familia de un paquete necesita el prefijo packages/');
    });

    test('el cuerpo va sin tracking — Material lo trae en 0.25', () {
      expect(AppTheme.light.textTheme.bodyMedium?.letterSpacing, 0);
      expect(AppTheme.light.textTheme.bodyLarge?.letterSpacing, 0);
      expect(AppTheme.light.textTheme.labelMedium?.letterSpacing, 0);
    });

    test('headlineSmall es el H2 del prototipo: 27 / w700 / -1.1', () {
      final h2 = AppTheme.light.textTheme.headlineSmall!;
      expect(h2.fontSize, 27);
      expect(h2.fontWeight, FontWeight.w700);
      expect(h2.letterSpacing, -1.1);
    });
  });
}
