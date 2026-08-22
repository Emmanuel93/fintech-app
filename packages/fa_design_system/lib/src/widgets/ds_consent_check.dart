import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_radii.dart';
import '../theme/app_text_styles.dart';
import '../theme/ds_scale.dart';
import '../motion/kredius_motion.dart';

/// Caja de consentimiento tocable del prototipo — consentimiento de buró
/// (Journey L252–L255, estilos L1156–L1157) y aceptación de contrato
/// (L514–L517, L1237–L1238).
///
/// Marcada: fondo `primaryContainer`, borde `primary`, tick azul con ✓ blanco.
/// Sin marcar: fondo blanco, borde `outlineVariant`, tick gris vacío.
///
/// Toda la caja es el área táctil (≥48px de alto real), no sólo el checkbox.
class DsConsentCheck extends StatelessWidget {
  const DsConsentCheck({
    super.key,
    required this.value,
    required this.onChanged,
    this.label,
    this.child,
    this.semanticsLabel,
    this.margin,
  }) : assert(label != null || child != null,
            'DsConsentCheck necesita `label` o `child`');

  final bool value;
  final ValueChanged<bool> onChanged;

  /// Texto plano del consentimiento. Excluyente con [child].
  final String? label;

  /// Contenido enriquecido (ej. el aviso legal, que lleva un enlace tocable).
  /// Excluyente con [label].
  final Widget? child;

  /// Etiqueta para lectores de pantalla cuando se usa [child].
  final String? semanticsLabel;

  final EdgeInsets? margin;

  @override
  Widget build(BuildContext context) {
    final ds = DsScale.of(context);
    return Semantics(
      checked: value,
      label: semanticsLabel ?? label,
      child: GestureDetector(
        onTap: () => onChanged(!value),
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: KrediusMotion.tab,
          curve: KrediusMotion.ease,
          margin: margin,
          constraints: BoxConstraints(minHeight: ds.h(52)),
          padding: EdgeInsets.symmetric(
              horizontal: ds.w(16), vertical: ds.h(15)),
          decoration: BoxDecoration(
            color: value ? AppColors.primaryContainer : AppColors.surface,
            borderRadius: BorderRadius.circular(ds.r(AppRadii.cardSmall)),
            border: Border.all(
                color: value ? AppColors.primary : AppColors.outlineVariant),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AnimatedContainer(
                duration: KrediusMotion.tab,
                width: ds.w(22),
                height: ds.w(22),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: value
                      ? AppColors.primary
                      : AppColors.tickEmpty,
                  borderRadius: BorderRadius.circular(ds.r(7)),
                ),
                child: Icon(
                  Icons.check_rounded,
                  size: ds.sp(14),
                  color: value ? AppColors.onPrimary : Colors.transparent,
                ),
              ),
              SizedBox(width: ds.w(12)),
              Expanded(
                child: child ??
                    Text(
                      label!,
                      style: AppTextStyles.body(
                        fontSize: ds.sp(12.5),
                        weight: FontWeight.w500,
                        color: value
                            ? AppColors.onPrimaryContainer
                            : AppColors.onSurface,
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

/// Banner informativo con icono — "Tus datos viajan cifrados…"
/// (Journey L221–L226): fondo `primaryContainer`, radio 12, candado en círculo.
class DsInfoBanner extends StatelessWidget {
  const DsInfoBanner({
    super.key,
    required this.text,
    this.icon = Icons.lock_outline_rounded,
  });

  final String text;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final ds = DsScale.of(context);
    return Container(
      padding: EdgeInsets.symmetric(
          horizontal: ds.w(16), vertical: ds.h(14)),
      decoration: BoxDecoration(
        color: AppColors.primaryContainer,
        borderRadius: BorderRadius.circular(ds.r(12)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: ds.w(20),
            height: ds.w(20),
            alignment: Alignment.center,
            decoration: const BoxDecoration(
                color: AppColors.primary, shape: BoxShape.circle),
            child: Icon(icon, size: ds.sp(12), color: AppColors.onPrimary),
          ),
          SizedBox(width: ds.w(11)),
          Expanded(
            child: Text(
              text,
              style: AppTextStyles.body(
                fontSize: ds.sp(12.5),
                weight: FontWeight.w500,
                color: AppColors.onPrimaryContainer,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
