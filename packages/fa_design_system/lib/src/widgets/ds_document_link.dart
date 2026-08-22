import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_radii.dart';
import '../theme/app_text_styles.dart';
import '../theme/ds_scale.dart';

/// Fila que abre un documento del expediente.
///
/// La usan la tabla de amortización y el contrato: cosas que el cliente
/// **acepta** y que por lo tanto tiene que poder leer antes. Un texto que dice
/// "acepto la tabla de amortización" sin una forma de abrirla es pedir una
/// firma en blanco.
class DsDocumentLink extends StatelessWidget {
  const DsDocumentLink({
    super.key,
    required this.label,
    required this.onTap,
    this.caption,
    this.icon = Icons.table_rows_rounded,
  });

  final String label;
  final String? caption;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ds = DsScale.of(context);

    return Semantics(
      button: true,
      label: 'Abrir $label',
      child: Material(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(ds.r(AppRadii.cardSmall)),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(ds.r(AppRadii.cardSmall)),
          child: Container(
            padding: EdgeInsets.all(ds.w(14)),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(ds.r(AppRadii.cardSmall)),
              border: Border.all(color: AppColors.outlineVariant),
            ),
            child: Row(
              children: [
                Container(
                  width: ds.w(36),
                  height: ds.w(36),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: AppColors.primaryContainer,
                    borderRadius: BorderRadius.circular(ds.r(11)),
                  ),
                  child:
                      Icon(icon, size: ds.sp(17), color: AppColors.primary),
                ),
                SizedBox(width: ds.w(12)),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(label,
                          style: AppTextStyles.body(
                            fontSize: ds.sp(13.5),
                            weight: FontWeight.w600,
                            color: AppColors.primary,
                          ).copyWith(height: 1.2)),
                      if (caption != null) ...[
                        SizedBox(height: ds.h(4)),
                        Text(caption!,
                            style: AppTextStyles.body(
                              fontSize: ds.sp(11.5),
                              color: AppColors.disabled,
                            ).copyWith(height: 1.35)),
                      ],
                    ],
                  ),
                ),
                SizedBox(width: ds.w(8)),
                Icon(Icons.chevron_right_rounded,
                    size: ds.sp(18), color: AppColors.disabled),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
