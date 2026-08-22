import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_radii.dart';
import '../theme/app_text_styles.dart';
import '../theme/ds_scale.dart';

/// Tono semántico de un chip de estado. Cada uno fija el par
/// fondo/texto tal como lo usa el prototipo, para que no haya que recordarlo
/// en cada pantalla.
enum DsChipTone {
  /// Teal — LISTO, VERIFICADA, EXTRAÍDO, AL CORRIENTE, RECOMENDADO
  /// (`#B2DFDB` / `#00695C`, Journey L214, L493, L617).
  ok,

  /// Azul — CAPTURAR, AUTORIZADO, REVOLVENTE (`#D6E4FF` / `#0D47A1`, L1117).
  info,

  /// Ámbar — PASA A COMITÉ (`#FFECB3` / `#8A5300`, L1189).
  warning,

  /// Gris — NO DISPONIBLE, LIQUIDADO, SIN USAR (`#EDEFF3` / `#7A8296`, L995).
  neutral,

  /// Rojo — ATRASO N DÍAS (`#FFDAD6` / `#B00020`, Journey App L2124, L2152).
  /// El ámbar de [warning] es "ojo con esto"; esto ya se rompió.
  danger,
}

/// Chip de estado / procedencia — píldora de radio 99 con texto 600/9 en
/// mayúsculas y tracking `.08em` (Journey L1099, L1117, L1030).
class DsStatusChip extends StatelessWidget {
  const DsStatusChip({
    super.key,
    required this.label,
    this.tone = DsChipTone.ok,
    this.fontSize = 9,
  });

  final String label;
  final DsChipTone tone;
  final double fontSize;

  static const Color _warningFg = AppColors.onTertiaryContainer;
  static const Color _neutralFg = AppColors.mutedText;

  Color get _bg => switch (tone) {
        DsChipTone.ok => AppColors.secondaryContainer,
        DsChipTone.info => AppColors.primaryContainer,
        DsChipTone.warning => AppColors.tertiaryContainer,
        DsChipTone.neutral => AppColors.divider,
        DsChipTone.danger => AppColors.errorContainer,
      };

  Color get _fg => switch (tone) {
        DsChipTone.ok => AppColors.secondary,
        DsChipTone.info => AppColors.primary,
        DsChipTone.warning => _warningFg,
        DsChipTone.neutral => _neutralFg,
        DsChipTone.danger => AppColors.error,
      };

  @override
  Widget build(BuildContext context) {
    final ds = DsScale.of(context);
    return Container(
      padding: EdgeInsets.symmetric(horizontal: ds.w(9), vertical: ds.h(5)),
      decoration: BoxDecoration(
        color: _bg,
        borderRadius: BorderRadius.circular(AppRadii.chip),
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: AppTextStyles.chipLabel(fontSize: ds.sp(fontSize), color: _fg),
      ),
    );
  }
}

/// Chip translúcido sobre el héroe azul — "AUTORIZADO PARA TI" (Journey L380)
/// y "SÍ CUMPLES LOS CRITERIOS" (L286–L289).
class DsHeroChip extends StatelessWidget {
  const DsHeroChip({
    super.key,
    required this.label,
    this.leading,
    this.tint = AppColors.accentGreen,
    this.foreground = AppColors.onPrimaryAccent,
    this.bordered = false,
  });

  final String label;
  final Widget? leading;
  final Color tint;
  final Color foreground;
  final bool bordered;

  @override
  Widget build(BuildContext context) {
    final ds = DsScale.of(context);
    return Container(
      padding: EdgeInsets.symmetric(horizontal: ds.w(13), vertical: ds.h(7)),
      decoration: BoxDecoration(
        color: tint.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(AppRadii.chip),
        border: bordered
            ? Border.all(color: tint.withValues(alpha: 0.4))
            : null,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (leading != null) ...[leading!, SizedBox(width: ds.w(8))],
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.captionLabel(
                fontSize: ds.sp(10.5),
                color: foreground,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
