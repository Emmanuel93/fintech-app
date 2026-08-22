import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import '../theme/app_colors.dart';
import '../theme/app_radii.dart';
import '../theme/app_text_styles.dart';

/// Tarjeta de producto para un carrusel horizontal (ej. "Créditos disponibles
/// para ti" en el home, o "Preofertas" en el catálogo). Tamaño y layout 1:1
/// con el prototipo Kredius (262×250, radio 22, sin fila de CTA — la tarjeta
/// completa es tocable). Solo recibe primitivos — el caller resuelve nombre,
/// ícono, chip de segmento y badge de estado a partir de su propio dominio
/// (`CreditProduct`/`PrequalifiedProduct` en `fa_credit`).
class DsProductCarouselCard extends StatelessWidget {
  const DsProductCarouselCard({
    super.key,
    required this.icon,
    required this.segmentLabel,
    required this.name,
    required this.description,
    required this.amountValue,
    required this.footnote,
    required this.onTap,
    this.amountCaption = 'LÍNEA AUTORIZADA',
    this.enabled = true,
    this.statusLabel,
    this.statusColor,
  });

  final IconData icon;

  /// "B2C" | "B2B" | "B2B2C".
  final String segmentLabel;
  final String name;
  final String description;

  /// Etiqueta pequeña sobre el monto, ej. "LÍNEA AUTORIZADA" o "MONTO MÁXIMO".
  final String amountCaption;

  /// Ya formateado, ej. "\$25,000" — sin prefijo, la etiqueta de arriba da el contexto.
  final String amountValue;

  /// Ej. "Desde \$740 al mes", "Solo pagas lo que dispones".
  final String footnote;

  final VoidCallback onTap;

  /// `false` si el producto no está disponible para este usuario — la tarjeta
  /// se atenúa y deja de ser tocable (mismo tratamiento que "NO DISPONIBLE"
  /// en el prototipo).
  final bool enabled;

  /// Ej. "Preaprobado" / "Recomendado" / "Pasa a comité" — null si no aplica.
  final String? statusLabel;
  final Color? statusColor;

  static const _mutedText = AppColors.mutedText;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: enabled ? 1 : 0.55,
      child: SizedBox(
        width: 262,
        height: 264,
        child: Material(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadii.cardLarge),
          child: InkWell(
            onTap: enabled ? onTap : null,
            borderRadius: BorderRadius.circular(AppRadii.cardLarge),
            child: Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(AppRadii.cardLarge),
                border: Border.all(color: AppColors.outlineVariant),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.primaryContainer,
                          borderRadius: BorderRadius.circular(13),
                        ),
                        child: Icon(icon, color: AppColors.primary, size: 20),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceVariant,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(segmentLabel, style: AppTextStyles.captionLabel(color: AppColors.onSurfaceVariant)),
                      ),
                    ],
                  ),
                  const Gap(16),
                  Text(name,
                      style: AppTextStyles.cardTitle(fontSize: 17),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                  const Gap(7),
                  Text(description,
                      style: AppTextStyles.body(fontSize: 12.5, color: _mutedText),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis),
                  const Spacer(),
                  Text(amountCaption, style: AppTextStyles.captionLabel()),
                  const Gap(9),
                  Text(amountValue, style: AppTextStyles.heroNumber(26)),
                  const Gap(9),
                  Text(footnote,
                      style: AppTextStyles.body(fontSize: 12, weight: FontWeight.w500),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                  if (statusLabel != null) ...[
                    const Gap(10),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: (statusColor ?? AppColors.primary).withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(AppRadii.chip),
                      ),
                      child: Text(statusLabel!,
                          style: AppTextStyles.captionLabel(color: statusColor ?? AppColors.primary)),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
