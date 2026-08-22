import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

/// Barra superior del alta, fiel al prototipo Kredius: botón atrás circular +
/// track de progreso delgado (6px, radio 99, relleno primary) + label "N/total".
/// Sustituye al indicador de puntos dentro del onboarding.
class DsOnboardingTopBar extends StatelessWidget {
  const DsOnboardingTopBar({
    super.key,
    required this.step,
    this.total = 4,
    this.onBack,
  });

  /// Paso actual, 1-based (1..total).
  final int step;
  final int total;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    final double pct = (step / total).clamp(0.0, 1.0);
    return Row(
      children: [
        if (onBack != null) ...[
          GestureDetector(
            onTap: onBack,
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.surface,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.outlineVariant),
              ),
              child: const Icon(Icons.arrow_back_ios_new_rounded,
                  size: 16, color: AppColors.onSurface),
            ),
          ),
          const Gap(12),
        ],
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: LinearProgressIndicator(
              value: pct,
              minHeight: 6,
              backgroundColor: AppColors.outlineVariant,
              valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
            ),
          ),
        ),
        const Gap(12),
        Text('$step/$total', style: AppTextStyles.captionLabel(color: AppColors.disabled)),
      ],
    );
  }
}
