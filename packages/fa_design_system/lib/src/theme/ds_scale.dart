import 'package:flutter/material.dart';

/// Escalado responsivo del journey Kredius.
///
/// El prototipo (`Kredius Journey.dc.html`) está dibujado sobre un lienzo fijo
/// de **402×874** (iPhone 14/15 lógico). Todas las medidas del diseño —
/// márgenes, altos, tipografía— están en ese sistema. Esta clase traduce esos
/// px de diseño a px lógicos del dispositivo real, de forma acotada.
///
/// Por qué acotada y no proporcional pura: escalar 1:1 con el ancho hace que en
/// una tablet un botón de 52 mida 90 y en un iPhone SE mida 41. Los factores se
/// clampean para que el diseño se **adapte** sin deformarse:
///
/// | Eje | Rango | Razón |
/// |---|---|---|
/// | [w] horizontal | 0.86 – 1.15 | del SE (320) al Pro Max, sin reventar en tablet |
/// | [h] vertical   | 0.90 – 1.12 | los alto fijos (52, 48, 42) casi no deben moverse |
/// | [sp] texto     | 0.92 – 1.08 | tipografía: el rango más conservador de los tres |
///
/// [sp] además **respeta el ajuste de accesibilidad del sistema**: el usuario que
/// subió el tamaño de letra en Ajustes lo sigue viendo más grande, porque
/// Flutter aplica `textScaler` encima del valor que devolvemos.
///
/// ## Márgenes
///
/// El diseño usa tres márgenes laterales según el tipo de pantalla, y están
/// expuestos como [gutter], [gutterHero] y [gutterWide] ya escalados.
///
/// ## Padding superior
///
/// El prototipo mide desde el borde físico de la pantalla (62 en las pantallas
/// claras, 92 en los héroes azules) porque dibuja la status bar encima. En
/// Flutter eso lo resuelve `SafeArea`, así que lo que hay que aplicar **después**
/// del SafeArea es la diferencia: [topGap] y [topGapHero].
///
/// ```dart
/// final ds = context.ds;
/// Padding(
///   padding: EdgeInsets.symmetric(horizontal: ds.gutter),
///   child: SizedBox(height: ds.h(52)),
/// )
/// ```
@immutable
class DsScale {
  const DsScale._({
    required this.size,
    required this.padding,
    required this.wk,
    required this.hk,
    required this.spk,
  });

  /// Ancho del lienzo del prototipo.
  static const double designWidth = 402;

  /// Alto del lienzo del prototipo.
  static const double designHeight = 874;

  /// Status bar asumida por el prototipo dentro de sus paddings superiores.
  static const double _designStatusBar = 47;

  factory DsScale.of(BuildContext context) {
    final mq = MediaQuery.of(context);
    return DsScale.fromSize(mq.size, mq.padding);
  }

  /// Constructor puro — útil en tests y goldens sin `BuildContext`.
  factory DsScale.fromSize(Size size, [EdgeInsets padding = EdgeInsets.zero]) {
    return DsScale._(
      size: size,
      padding: padding,
      wk: (size.width / designWidth).clamp(0.86, 1.15),
      hk: (size.height / designHeight).clamp(0.90, 1.12),
      spk: (size.width / designWidth).clamp(0.92, 1.08),
    );
  }

  final Size size;
  final EdgeInsets padding;

  /// Factores de escala ya acotados (expuestos para casos límite).
  final double wk, hk, spk;

  // ── Conversión de px de diseño ─────────────────────────────────────────────

  /// Medida horizontal del diseño → px lógicos (anchos, paddings laterales).
  double w(double designPx) => designPx * wk;

  /// Medida vertical del diseño → px lógicos (altos, gaps verticales).
  double h(double designPx) => designPx * hk;

  /// Tamaño de fuente del diseño → px lógicos.
  double sp(double designPx) => designPx * spk;

  /// Radio del diseño → px lógicos. Usa el factor horizontal para que un radio
  /// nunca se vuelva ovalado respecto de la caja que redondea.
  double r(double designPx) => designPx * wk;

  // ── Márgenes del diseño ────────────────────────────────────────────────────

  /// Margen lateral estándar de las pantallas claras del alta — 22 en el
  /// diseño (Journey L163, L233, L374, L467).
  double get gutter => w(22);

  /// Margen lateral de los héroes azules — 26 (Journey L65, L131, L262, L547).
  double get gutterHero => w(26);

  /// Margen lateral de las pantallas con contenido a sangre (carrusel de
  /// preofertas, configurador, home) — 20 (Journey L319, L403, L570).
  double get gutterWide => w(20);

  /// Gap superior a aplicar **dentro** de un `SafeArea` en pantallas claras.
  /// El diseño pide 96 desde el borde físico; `SafeArea` ya consumió la status
  /// bar, así que sólo queda el resto (mínimo 8 para que nunca se pegue).
  ///
  /// Eran 62 antes de la barra de marca global: la barra se instaló entre la
  /// status bar y el contenido (44 → 82) y el diseño bajó todas las pantallas
  /// claras a 96 para dejarle su sitio.
  double get topGap => h((96 - _designStatusBar).clamp(8, 96));

  /// Equivalente para los héroes azules, que en el diseño siguen arrancando en
  /// 92: ahí la barra va **sobre** el azul, no lo empuja.
  double get topGapHero => h((92 - _designStatusBar).clamp(8, 92));

  /// Gap superior de las pantallas que abren con una **banda azul a sangre** y
  /// por eso no pueden usar `SafeArea` —el azul tiene que llegar al borde—:
  /// aprobación, contraoferta, rechazo y liga enviada. El diseño las abre en
  /// 112 desde el borde físico (44 de status bar + 38 de barra + 30 de aire),
  /// así que aquí sí hay que sumar el inset real del dispositivo.
  double get topGapBand => padding.top + h(112 - _designStatusBar);

  /// Padding inferior seguro: el mayor entre el del sistema y el del diseño.
  double bottomGap([double designPx = 34]) =>
      padding.bottom > 0 ? padding.bottom : h(designPx);

  // ── Consultas de forma ─────────────────────────────────────────────────────

  /// Pantallas angostas (iPhone SE, Android compactos): conviene bajar de 3 a 2
  /// columnas y recortar copys largos.
  bool get isCompact => size.width < 360;

  /// Pantallas cortas: el contenido del héroe necesita hacer scroll en vez de
  /// repartirse con `Spacer`.
  bool get isShort => size.height < 700;

  /// Tablet / desktop: el journey se centra en una columna del ancho de diseño
  /// en vez de estirarse.
  bool get isExpanded => size.width >= 600;

  /// Ancho máximo de la columna de contenido. En tablet acota al lienzo del
  /// prototipo para que el journey no se deforme a lo ancho.
  double get contentMaxWidth => isExpanded ? designWidth * 1.1 : double.infinity;
}

/// Azúcar sintáctica: `context.ds.w(22)`.
extension DsScaleContext on BuildContext {
  DsScale get ds => DsScale.of(this);
}

/// Centra y acota el contenido en pantallas anchas (tablet, desktop, web),
/// dejándolo intacto en teléfono. Envuelve el `body` de cada pantalla del
/// journey para que el diseño de 402 no se estire a 1200.
class DsResponsiveBody extends StatelessWidget {
  const DsResponsiveBody({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final ds = DsScale.of(context);
    if (!ds.isExpanded) return child;
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: ds.contentMaxWidth),
        child: child,
      ),
    );
  }
}
