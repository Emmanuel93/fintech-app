import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// Isotipo "K" de Kredius, pintado 1:1 con `brand/logo/kredius-mark.svg`.
///
/// Geometría del SVG (viewBox 100×100, `stroke-width 7.8`, `linecap butt`):
/// - astil vertical  `x=33.1  y 23→77`
/// - pierna inferior `M32 48 → 71.8 77`
/// - brazo superior  `M32 52 → 71.8 23`  ← el brazo verde (crecimiento)
///
/// El brazo siempre es `AppColors.accentGreen` (#00B894). El astil y la pierna
/// cambian de color según el fondo. Cuatro tratamientos oficiales de marca
/// (`assets/brand/README.md`, tabla "Cuándo usar cada versión"):
/// - [KrediusMark.inverted] — **tile blanco + K azul**. Es la variante que va
///   **sobre el azul de marca**: bienvenida y login. Es la del archivo
///   `kredius-isotipo-invertido.svg`.
/// - [KrediusMark.onDark]  — trazos blancos, sin tile (sobre fotografía oscura
///   o azul cuando no se quiere el tile: splash, headers).
/// - [KrediusMark.onLight] — trazos azul primario, sin tile (sobre blanco o
///   papel #EBF0F7).
/// - [KrediusMark.badge]   — tile azul + trazos blancos (ícono de app).
class KrediusMark extends StatelessWidget {
  const KrediusMark({
    super.key,
    required this.size,
    this.badge = false,
    this.badgeColor = AppColors.primary,
    this.strokeColor = AppColors.onPrimary,
    this.armColor = AppColors.accentGreen,
  });

  /// Invertido: tile **blanco** + K azul con brazo verde. Es el tratamiento
  /// oficial sobre el azul de marca — welcome y login.
  const KrediusMark.inverted({Key? key, required double size})
      : this(
          key: key,
          size: size,
          badge: true,
          badgeColor: AppColors.surface,
          strokeColor: AppColors.primary,
        );

  /// Bare, trazos blancos — sobre azul o foto oscura cuando no se quiere tile.
  const KrediusMark.onDark({Key? key, required double size})
      : this(key: key, size: size, strokeColor: AppColors.onPrimary);

  /// Bare, trazos azul primario — para fondos claros (login, home).
  const KrediusMark.onLight({Key? key, required double size})
      : this(key: key, size: size, strokeColor: AppColors.primary);

  /// Insignia: cuadro redondeado azul + trazos blancos (ícono de app).
  const KrediusMark.badge({Key? key, required double size})
      : this(
          key: key,
          size: size,
          badge: true,
          badgeColor: AppColors.primary,
          strokeColor: AppColors.onPrimary,
        );

  /// Lado del cuadrado en px.
  final double size;

  /// Dibuja el cuadro redondeado de fondo (estilo ícono de app).
  final bool badge;

  /// Relleno del cuadro cuando [badge] es true.
  final Color badgeColor;

  /// Color del astil + la pierna.
  final Color strokeColor;

  /// Color del brazo superior (verde de marca por defecto).
  final Color armColor;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _KrediusMarkPainter(
          badge: badge,
          badgeColor: badgeColor,
          strokeColor: strokeColor,
          armColor: armColor,
        ),
      ),
    );
  }
}

class _KrediusMarkPainter extends CustomPainter {
  _KrediusMarkPainter({
    required this.badge,
    required this.badgeColor,
    required this.strokeColor,
    required this.armColor,
  });

  final bool badge;
  final Color badgeColor;
  final Color strokeColor;
  final Color armColor;

  @override
  void paint(Canvas canvas, Size size) {
    // Todo el vector está en un lienzo 100×100; escalamos al tamaño real.
    final s = size.width / 100.0;
    Offset p(double x, double y) => Offset(x * s, y * s);

    if (badge) {
      final rrect = RRect.fromRectAndRadius(
        Offset.zero & size,
        Radius.circular(22 * s),
      );
      canvas.drawRRect(rrect, Paint()..color = badgeColor);
    }

    final stroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 7.8 * s
      ..strokeCap = StrokeCap.butt
      ..isAntiAlias = true;

    // astil vertical + pierna inferior (mismo color)
    canvas.drawLine(p(33.1, 23), p(33.1, 77), stroke..color = strokeColor);
    canvas.drawLine(p(32, 48), p(71.8, 77), stroke..color = strokeColor);
    // brazo superior (verde)
    canvas.drawLine(p(32, 52), p(71.8, 23), stroke..color = armColor);
  }

  @override
  bool shouldRepaint(_KrediusMarkPainter old) =>
      old.badge != badge ||
      old.badgeColor != badgeColor ||
      old.strokeColor != strokeColor ||
      old.armColor != armColor;
}
