import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// Catálogo de movimiento del journey Kredius.
///
/// Los tres keyframes del prototipo (`Kredius Journey.dc.html` L18–L20) viven
/// aquí una sola vez, en vez de reimplementarse con un `AnimationController`
/// suelto en cada pantalla:
///
/// ```css
/// @keyframes kr-spin  { to { transform: rotate(360deg) } }
/// @keyframes kr-pulse { 0%,100%{ opacity:.4; transform:scale(.9) } 50%{ opacity:1; transform:scale(1) } }
/// @keyframes kr-rise  { from { opacity:0; transform:translateY(12px) } to { opacity:1; transform:none } }
/// ```
///
/// Todos los widgets de este archivo respetan
/// `MediaQuery.disableAnimations` (el ajuste "Reducir movimiento" del sistema):
/// cuando está activo se pintan en su estado final, sin bucles. Es requisito de
/// accesibilidad y además evita que un loop infinito consuma batería en
/// dispositivos donde el usuario pidió lo contrario.
abstract final class KrediusMotion {
  /// `kr-spin` — 1.1s lineal, infinito (anillo del análisis).
  static const Duration spin = Duration(milliseconds: 1100);

  /// `kr-pulse` a 1.6s — badge "SÍ CUMPLES LOS CRITERIOS" (Journey L287).
  static const Duration pulse = Duration(milliseconds: 1600);

  /// `kr-pulse` a 1.2s — paso activo del análisis (Journey L1165).
  static const Duration pulseFast = Duration(milliseconds: 1200);

  /// `kr-rise` — 500ms ease (entrada del bloque de desembolso).
  static const Duration rise = Duration(milliseconds: 500);

  /// `transition: width .2s` — dots del carrusel y del stepper de plazo.
  static const Duration dot = Duration(milliseconds: 200);

  /// Transición de pestaña / cambio de paso.
  static const Duration tab = Duration(milliseconds: 220);

  static const Curve ease = Curves.easeInOut;
  static const Curve enter = Curves.easeOut;

  /// Desplazamiento vertical inicial de `kr-rise`, en px de diseño.
  static const double riseOffset = 12;

  /// `true` si el sistema pidió reducir movimiento.
  static bool reduced(BuildContext context) =>
      MediaQuery.maybeDisableAnimationsOf(context) ?? false;
}

/// `kr-rise`: entra con fade + subida de 12px. Se dispara al montar.
///
/// [delay] permite escalonar varios bloques (el prototipo no lo hace, pero la
/// pantalla de desembolso gana mucho con 60–90ms entre el check y la tarjeta).
class KrRise extends StatefulWidget {
  const KrRise({
    super.key,
    required this.child,
    this.delay = Duration.zero,
    this.offset = KrediusMotion.riseOffset,
  });

  final Widget child;
  final Duration delay;
  final double offset;

  @override
  State<KrRise> createState() => _KrRiseState();
}

class _KrRiseState extends State<KrRise> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: KrediusMotion.rise,
  );

  @override
  void initState() {
    super.initState();
    if (widget.delay == Duration.zero) {
      _c.forward();
    } else {
      Future<void>.delayed(widget.delay, () {
        if (mounted) _c.forward();
      });
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (KrediusMotion.reduced(context)) return widget.child;
    final curved = CurvedAnimation(parent: _c, curve: KrediusMotion.enter);
    return AnimatedBuilder(
      animation: curved,
      builder: (_, child) => Opacity(
        opacity: curved.value,
        child: Transform.translate(
          offset: Offset(0, widget.offset * (1 - curved.value)),
          child: child,
        ),
      ),
      child: widget.child,
    );
  }
}

/// `kr-pulse`: late en bucle entre `opacity .4 / scale .9` y `opacity 1 / scale 1`.
class KrPulse extends StatefulWidget {
  const KrPulse({
    super.key,
    required this.child,
    this.period = KrediusMotion.pulse,
    this.enabled = true,
  });

  final Widget child;
  final Duration period;

  /// Cuando es `false` el hijo se pinta estable al 100% — así una lista de pasos
  /// puede tener uno solo latiendo sin montar y desmontar widgets.
  final bool enabled;

  @override
  State<KrPulse> createState() => _KrPulseState();
}

class _KrPulseState extends State<KrPulse> with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: widget.period);

  @override
  void initState() {
    super.initState();
    if (widget.enabled) _c.repeat(reverse: true);
  }

  @override
  void didUpdateWidget(KrPulse old) {
    super.didUpdateWidget(old);
    if (widget.enabled && !_c.isAnimating) {
      _c.repeat(reverse: true);
    } else if (!widget.enabled && _c.isAnimating) {
      _c.stop();
      _c.value = 1;
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.enabled || KrediusMotion.reduced(context)) return widget.child;
    final curved = CurvedAnimation(parent: _c, curve: KrediusMotion.ease);
    return AnimatedBuilder(
      animation: curved,
      builder: (_, child) {
        // .4 → 1 de opacidad, .9 → 1 de escala.
        final t = curved.value;
        return Opacity(
          opacity: 0.4 + 0.6 * t,
          child: Transform.scale(scale: 0.9 + 0.1 * t, child: child),
        );
      },
      child: widget.child,
    );
  }
}

/// `kr-spin`: el anillo de la pantalla de análisis.
///
/// Prototipo (Journey L264): 112×112, borde de 3px `rgba(255,255,255,.16)` con
/// `border-top-color:#00B894`, girando 1.1s lineal infinito.
class KrSpinRing extends StatefulWidget {
  const KrSpinRing({
    super.key,
    this.size = 112,
    this.strokeWidth = 3,
    this.trackColor,
    this.arcColor = AppColors.accentGreen,
  });

  final double size;
  final double strokeWidth;

  /// Por defecto, blanco al 16% — el anillo vive sobre el héroe azul.
  final Color? trackColor;
  final Color arcColor;

  @override
  State<KrSpinRing> createState() => _KrSpinRingState();
}

class _KrSpinRingState extends State<KrSpinRing>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: KrediusMotion.spin)..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final track =
        widget.trackColor ?? AppColors.onPrimary.withValues(alpha: 0.16);
    final ring = CustomPaint(
      size: Size.square(widget.size),
      painter: _RingPainter(
        strokeWidth: widget.strokeWidth,
        trackColor: track,
        arcColor: widget.arcColor,
      ),
    );

    if (KrediusMotion.reduced(context)) {
      return SizedBox.square(dimension: widget.size, child: ring);
    }

    return SizedBox.square(
      dimension: widget.size,
      child: RotationTransition(turns: _c, child: ring),
    );
  }
}

class _RingPainter extends CustomPainter {
  _RingPainter({
    required this.strokeWidth,
    required this.trackColor,
    required this.arcColor,
  });

  final double strokeWidth;
  final Color trackColor, arcColor;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final inset = rect.deflate(strokeWidth / 2);
    final base = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..isAntiAlias = true;

    canvas.drawArc(inset, 0, 6.2832, false, base..color = trackColor);
    // `border-top-color` en CSS pinta el cuarto superior del anillo: de -135° a
    // -45°, es decir un arco de 90° centrado arriba.
    canvas.drawArc(inset, -2.3562, 1.5708, false, base..color = arcColor);
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      old.strokeWidth != strokeWidth ||
      old.trackColor != trackColor ||
      old.arcColor != arcColor;
}

/// Dot de paginación con ancho animado — carrusel de preofertas (6→18px,
/// Journey L1192) y stepper de plazo (7→22px, L1214).
class KrDot extends StatelessWidget {
  const KrDot({
    super.key,
    required this.active,
    this.size = 6,
    this.activeWidth = 18,
    this.activeColor = AppColors.primary,
    this.color = AppColors.outlineVariant,
  });

  final bool active;
  final double size, activeWidth;
  final Color activeColor, color;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: KrediusMotion.dot,
      curve: KrediusMotion.ease,
      width: active ? activeWidth : size,
      height: size,
      decoration: BoxDecoration(
        color: active ? activeColor : color,
        borderRadius: BorderRadius.circular(size),
      ),
    );
  }
}
