import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../theme/ds_scale.dart';

/// Pantalla "héroe azul" del journey: fondo `primary` a sangre, dos blobs
/// radiales de fondo y contenido sobre ellos.
///
/// Es la base de bienvenida (Journey L131–L133), login (L65–L67), análisis
/// (L262) y desembolso (L547–L548). En vez de copiar los `Positioned` con blobs
/// en cuatro pantallas, se centralizan aquí.
///
/// **Adaptabilidad.** El contenido va dentro de un `SafeArea` + scroll con
/// `ConstrainedBox(minHeight)`: en un teléfono normal el `Spacer` reparte igual
/// que el diseño, y en un dispositivo corto (o con el teclado abierto, o con el
/// texto del sistema agrandado) el contenido hace scroll en vez de desbordarse.
class DsHeroScaffold extends StatelessWidget {
  const DsHeroScaffold({
    super.key,
    required this.child,
    this.blobs = DsHeroBlobs.corners,
    this.scrollable = true,
    this.horizontalPadding,
    this.bottomSafeArea = true,
  });

  final Widget child;
  final DsHeroBlobs blobs;

  /// `false` para pantallas que se autoajustan (análisis) y no quieren scroll.
  final bool scrollable;

  /// Por defecto, el gutter de héroe del diseño (26).
  final double? horizontalPadding;

  final bool bottomSafeArea;

  @override
  Widget build(BuildContext context) {
    final ds = DsScale.of(context);
    final padH = horizontalPadding ?? ds.gutterHero;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      // Iconos de la status bar en claro: el fondo es azul oscuro.
      value: SystemUiOverlayStyle.light.copyWith(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: AppColors.primary,
        body: Stack(
          children: [
            ..._blobWidgets(ds),
            SafeArea(
              bottom: bottomSafeArea,
              child: DsResponsiveBody(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final content = Padding(
                      padding: EdgeInsets.fromLTRB(
                        padH,
                        ds.topGapHero,
                        padH,
                        ds.h(34),
                      ),
                      child: child,
                    );
                    if (!scrollable) return content;
                    return SingleChildScrollView(
                      child: ConstrainedBox(
                        constraints:
                            BoxConstraints(minHeight: constraints.maxHeight),
                        child: IntrinsicHeight(child: content),
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _blobWidgets(DsScale ds) {
    switch (blobs) {
      case DsHeroBlobs.none:
        return const [];
      case DsHeroBlobs.corners:
        return [
          // Verde arriba-derecha (crecimiento) — Journey L132.
          Positioned(
            top: ds.h(-130),
            right: ds.w(-130),
            child: _Blob(
                size: ds.w(360),
                color: AppColors.accentGreen.withValues(alpha: 0.30)),
          ),
          // Azul claro abajo-izquierda — Journey L133.
          Positioned(
            bottom: ds.h(-120),
            left: ds.w(-120),
            child: _Blob(
                size: ds.w(320),
                color: AppColors.primaryContainer.withValues(alpha: 0.26)),
          ),
        ];
      case DsHeroBlobs.centerTop:
        // Journey L548 — el halo del desembolso.
        return [
          Positioned(
            top: ds.h(110),
            left: 0,
            right: 0,
            child: Center(
              child: _Blob(
                  size: ds.w(340),
                  color: AppColors.accentGreen.withValues(alpha: 0.32)),
            ),
          ),
        ];
    }
  }
}

enum DsHeroBlobs { none, corners, centerTop }

class _Blob extends StatelessWidget {
  const _Blob({required this.size, required this.color});
  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [color, color.withValues(alpha: 0)],
            stops: const [0, 0.7],
          ),
        ),
      ),
    );
  }
}

/// CTA blanco sobre el héroe azul — 52px, radio 12, texto `primary`
/// (Journey L155, L104, L564). El `DsButton` primario es azul y no contrasta
/// sobre este fondo.
class DsWhiteCta extends StatelessWidget {
  const DsWhiteCta({
    super.key,
    required this.label,
    required this.onTap,
    this.enabled = true,
  });

  final String label;
  final VoidCallback? onTap;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final ds = DsScale.of(context);
    final on = enabled && onTap != null;
    return Semantics(
      button: true,
      enabled: on,
      label: label,
      child: Material(
        color: on
            ? AppColors.surface
            : AppColors.surface.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(ds.r(12)),
        child: InkWell(
          onTap: on ? onTap : null,
          borderRadius: BorderRadius.circular(ds.r(12)),
          child: Container(
            height: ds.h(52),
            alignment: Alignment.center,
            padding: EdgeInsets.symmetric(horizontal: ds.w(16)),
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.button(
                fontSize: ds.sp(16),
                color: on
                    ? AppColors.primary
                    : AppColors.primary.withValues(alpha: 0.5),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Botón secundario translúcido sobre el héroe (Face ID, cerrar, proveedores
/// sociales) — `rgba(255,255,255,.10)` con borde `.16` (Journey L105, L118).
class DsGlassButton extends StatelessWidget {
  const DsGlassButton({
    super.key,
    required this.child,
    this.onTap,
    this.width,
    this.height,
    this.radius = 12,
    this.semanticLabel,
  });

  final Widget child;
  final VoidCallback? onTap;
  final double? width, height;
  final double radius;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final ds = DsScale.of(context);
    return Semantics(
      button: true,
      label: semanticLabel,
      child: Material(
        color: AppColors.onPrimary.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(ds.r(radius)),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(ds.r(radius)),
          child: Container(
            width: width,
            height: height ?? ds.h(48),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(ds.r(radius)),
              border: Border.all(
                  color: AppColors.onPrimary.withValues(alpha: 0.16)),
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}
