import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_radii.dart';
import '../theme/app_text_styles.dart';
import '../theme/ds_scale.dart';
import '../motion/kredius_motion.dart';

/// Fila de chips de filtro con scroll horizontal — notificaciones
/// (Journey L1024–L1028, estilo L1434) y movimientos (L1000–L1002).
///
/// Activo: relleno `primary` con texto blanco. Inactivo: blanco con borde
/// `outlineVariant`. Nunca se truncan: la fila hace scroll.
class DsFilterChips extends StatelessWidget {
  const DsFilterChips({
    super.key,
    required this.labels,
    required this.index,
    required this.onChanged,
    this.padding,
  });

  final List<String> labels;
  final int index;
  final ValueChanged<int> onChanged;

  /// Padding horizontal del carril. Suele ser el gutter de la pantalla, para
  /// que el primer chip alinee con el título aunque la fila sangre a los lados.
  final EdgeInsets? padding;

  @override
  Widget build(BuildContext context) {
    final ds = DsScale.of(context);
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: padding ?? EdgeInsets.symmetric(horizontal: ds.gutterWide),
      child: Row(
        children: [
          for (var i = 0; i < labels.length; i++) ...[
            if (i > 0) SizedBox(width: ds.w(7)),
            _Chip(
              label: labels[i],
              active: i == index,
              onTap: () => onChanged(i),
            ),
          ],
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({
    required this.label,
    required this.active,
    required this.onTap,
  });

  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ds = DsScale.of(context);
    return Semantics(
      button: true,
      selected: active,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: KrediusMotion.tab,
          curve: KrediusMotion.ease,
          padding: EdgeInsets.symmetric(
              horizontal: ds.w(14), vertical: ds.h(8)),
          decoration: BoxDecoration(
            color: active ? AppColors.primary : AppColors.surface,
            borderRadius: BorderRadius.circular(AppRadii.chip),
            border: Border.all(
                color: active ? AppColors.primary : AppColors.outlineVariant),
          ),
          child: Text(
            label,
            maxLines: 1,
            style: AppTextStyles.body(
              fontSize: ds.sp(12),
              weight: FontWeight.w600,
              color: active ? AppColors.onPrimary : AppColors.onSurfaceVariant,
            ).copyWith(height: 1.0),
          ),
        ),
      ),
    );
  }
}
