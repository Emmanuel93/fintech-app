import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../theme/ds_scale.dart';
import '../motion/kredius_motion.dart';

/// Segmented control del prototipo (Journey L172–L176, estilos L1061–L1064):
/// carril `#E3E9F2` con radio 12 y padding 4; la pestaña activa es blanca, radio
/// 9, con sombra `0 1px 3px rgba(26,28,30,.10)`.
///
/// Se usa en el alta (Documentos / Datos) y en el resumen (Ya tengo cuenta /
/// No tengo cuenta, L482–L486, que en el diseño va sobre `#EBF0F7`).
///
/// **Adaptabilidad.** Las etiquetas se ajustan con `FittedBox` antes que
/// truncarse, así "Continuar a tus datos" o un texto largo en pantalla angosta
/// sigue siendo legible.
class DsSegmentedTabs extends StatelessWidget {
  const DsSegmentedTabs({
    super.key,
    required this.labels,
    required this.index,
    required this.onChanged,
    this.trackColor = AppColors.trackSurface,
    this.height = 38,
    this.enabled,
  }) : assert(labels.length >= 2, 'Un segmented control necesita 2+ opciones');

  final List<String> labels;
  final int index;
  final ValueChanged<int> onChanged;

  /// `#E3E9F2` en el alta; `AppColors.surfaceVariant` en el resumen.
  final Color trackColor;

  final double height;

  /// Permite bloquear pestañas (ej.: "Datos" hasta que haya documentos).
  /// `null` = todas habilitadas.
  final List<bool>? enabled;

  @override
  Widget build(BuildContext context) {
    final ds = DsScale.of(context);
    return Container(
      padding: EdgeInsets.all(ds.w(4)),
      decoration: BoxDecoration(
        color: trackColor,
        borderRadius: BorderRadius.circular(ds.r(12)),
      ),
      child: Row(
        children: [
          for (var i = 0; i < labels.length; i++) ...[
            if (i > 0) SizedBox(width: ds.w(6)),
            Expanded(
              child: _Tab(
                label: labels[i],
                active: i == index,
                enabled: enabled?[i] ?? true,
                height: ds.h(height),
                onTap: () => onChanged(i),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _Tab extends StatelessWidget {
  const _Tab({
    required this.label,
    required this.active,
    required this.enabled,
    required this.height,
    required this.onTap,
  });

  final String label;
  final bool active, enabled;
  final double height;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ds = DsScale.of(context);
    final Color fg = !enabled
        ? AppColors.disabled
        : active
            ? AppColors.primary
            : AppColors.mutedText;

    return Semantics(
      button: true,
      selected: active,
      enabled: enabled,
      child: GestureDetector(
        onTap: enabled ? onTap : null,
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: KrediusMotion.tab,
          curve: KrediusMotion.ease,
          height: height,
          alignment: Alignment.center,
          padding: EdgeInsets.symmetric(horizontal: ds.w(8)),
          decoration: BoxDecoration(
            color: active ? AppColors.surface : Colors.transparent,
            borderRadius: BorderRadius.circular(ds.r(9)),
            boxShadow: active
                ? [
                    BoxShadow(
                      color: AppColors.onSurface.withValues(alpha: 0.10),
                      blurRadius: 3,
                      offset: const Offset(0, 1),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (!enabled) ...[
                Icon(Icons.lock_outline_rounded, size: ds.sp(13), color: fg),
                SizedBox(width: ds.w(5)),
              ],
              Flexible(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    label,
                    maxLines: 1,
                    style: TextStyle(
                      fontFamily: AppTextStyles.fontFamily,
                      fontSize: ds.sp(12.5),
                      fontWeight: FontWeight.w600,
                      color: fg,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
