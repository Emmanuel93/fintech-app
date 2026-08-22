import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import 'kredius_mark.dart';
import 'kredius_wordmark.dart';

/// Lockup de marca: isotipo K + logotipo "Kredius" en fila, con tagline opcional.
///
/// Tres tratamientos, uno por tipo de fondo:
///
/// | Constructor | Isotipo | Texto | Dónde |
/// |---|---|---|---|
/// | `KrediusBrand.inverted()` | tile **blanco**, K azul | blanco | **welcome y login** (sobre el azul de marca) |
/// | `KrediusBrand(onDark: true)` | trazos blancos, sin tile | blanco | splash, headers azules |
/// | `KrediusBrand()` | trazos azules, sin tile | azul | fondos claros |
///
/// El reparto sale de `assets/brand/README.md`: *"Invertido (tile blanco, K
/// azul) — sobre el azul de marca — es el que usa la pantalla de bienvenida y
/// el login de la app"*, y del propio prototipo (Journey L135–L141, L71–L77),
/// donde el tile mide 46×46 con radio 13 (≈28% del lado).
class KrediusBrand extends StatelessWidget {
  const KrediusBrand({
    super.key,
    this.markSize = 40,
    this.onDark = false,
    this.inverted = false,
    this.tagline,
  });

  /// Lockup oficial sobre el azul de marca: tile blanco con la K azul.
  const KrediusBrand.inverted({Key? key, double markSize = 46, String? tagline})
      : this(
          key: key,
          markSize: markSize,
          onDark: true,
          inverted: true,
          tagline: tagline,
        );

  final double markSize;

  /// Texto en blanco (fondo oscuro/azul).
  final bool onDark;

  /// Isotipo con tile blanco y K azul. Implica fondo azul, así que se usa junto
  /// con [onDark] para el color del texto.
  final bool inverted;

  /// Bajada opcional en mayúsculas (ej. "CRÉDITO CLARO, APROBADO EN MINUTOS").
  final String? tagline;

  @override
  Widget build(BuildContext context) {
    final Color textColor = onDark ? AppColors.onPrimary : AppColors.primary;
    final Color taglineColor = onDark
        ? AppColors.onPrimary.withValues(alpha: 0.7)
        : AppColors.onSurfaceVariant;

    final Widget mark = inverted
        ? KrediusMark.inverted(size: markSize)
        : (onDark
            ? KrediusMark.onDark(size: markSize)
            : KrediusMark.onLight(size: markSize));

    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        mark,
        SizedBox(width: markSize * 0.28),
        Flexible(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              KrediusWordmark(fontSize: markSize * 0.48, color: textColor),
              if (tagline != null) ...[
                SizedBox(height: markSize * 0.14),
                Text(
                  tagline!,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: AppTextStyles.fontFamily,
                    fontSize: markSize * 0.23,
                    fontWeight: FontWeight.w600,
                    letterSpacing: markSize * 0.03,
                    height: 1.0,
                    color: taglineColor,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
