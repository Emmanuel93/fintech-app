import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:intl/intl.dart';
import '../theme/app_colors.dart';
import '../theme/app_radii.dart';
import '../theme/app_text_styles.dart';

/// Slider de monto acotado a `[min, max]`, con el valor vigente destacado
/// arriba (siempre visible mientras se arrastra, sin necesidad de teclado).
class DsAmountSlider extends StatelessWidget {
  const DsAmountSlider({
    super.key,
    required this.amount,
    required this.min,
    required this.max,
    required this.step,
    required this.onChanged,
    this.label = 'MONTO DEL PRÉSTAMO',
  });

  final double amount;
  final double min;
  final double max;
  final int? step;
  final ValueChanged<double> onChanged;
  final String label;

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat.currency(locale: 'es_MX', symbol: '\$', decimalDigits: 0);
    final divisions = (step != null && step! > 0 && max > min)
        ? ((max - min) / step!).round()
        : null;

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 4),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadii.card),
        border: Border.all(color: AppColors.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(label, style: AppTextStyles.captionLabel()),
          const Gap(10),
          Center(
            child: Text(fmt.format(amount), style: AppTextStyles.heroNumber(42, color: AppColors.onSurface)),
          ),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              trackHeight: 8,
              activeTrackColor: AppColors.primary,
              inactiveTrackColor: AppColors.primaryContainer,
              thumbColor: AppColors.surface,
              overlayColor: AppColors.primary.withValues(alpha: 0.12),
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 15, elevation: 3),
              overlayShape: const RoundSliderOverlayShape(overlayRadius: 24),
            ),
            child: Slider(
              value: amount.clamp(min, max),
              min: min,
              max: max,
              divisions: (divisions == null || divisions <= 0) ? null : divisions,
              onChanged: max > min ? onChanged : null,
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(fmt.format(min), style: AppTextStyles.captionLabel(color: AppColors.onSurfaceVariant)),
                Text(fmt.format(max), style: AppTextStyles.captionLabel(color: AppColors.onSurfaceVariant)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
