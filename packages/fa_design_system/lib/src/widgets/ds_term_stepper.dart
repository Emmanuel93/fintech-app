import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import '../theme/app_colors.dart';
import '../theme/app_radii.dart';
import '../theme/app_text_styles.dart';

/// Selector de plazo — nunca se escribe, solo se selecciona con los botones
/// +/-.
///
/// Dos modos: continuo dentro de `[min, max]` (el crédito propio, que admite
/// cualquier número de mensualidades) o **discreto** sobre [steps], cuando el
/// producto sólo ofrece ciertos plazos. La colocación es del segundo tipo: 12,
/// 24, 36 o 48 quincenas (Journey App L1652), y dejar pasar un 13 daría un pago
/// que después no se puede contratar.
class DsTermStepper extends StatelessWidget {
  const DsTermStepper({
    super.key,
    required this.term,
    required this.min,
    required this.max,
    required this.onChanged,
    this.steps,
    this.label = 'EN CUÁNTAS MENSUALIDADES',
    this.unitCaption = 'PAGOS MENSUALES',
  });

  final int term;
  final int min;
  final int max;
  final ValueChanged<int> onChanged;

  /// Plazos permitidos, en orden ascendente. Si es `null`, el paso es de 1.
  final List<int>? steps;

  final String label;
  final String unitCaption;

  /// Índice del plazo actual dentro de [steps]; -1 si no aplica.
  int get _index => steps?.indexOf(term) ?? -1;

  int? get _previous {
    final s = steps;
    if (s == null) return term > min ? term - 1 : null;
    // Si el valor actual no está en la lista (llegó de una preoferta), el
    // primer toque baja al plazo permitido inmediatamente menor.
    if (_index < 0) return s.where((t) => t < term).lastOrNull;
    return _index > 0 ? s[_index - 1] : null;
  }

  int? get _next {
    final s = steps;
    if (s == null) return term < max ? term + 1 : null;
    if (_index < 0) return s.where((t) => t > term).firstOrNull;
    return _index < s.length - 1 ? s[_index + 1] : null;
  }

  @override
  Widget build(BuildContext context) {
    final previous = _previous;
    final next = _next;

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadii.card),
        border: Border.all(color: AppColors.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(label, style: AppTextStyles.captionLabel()),
          const Gap(14),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _StepperButton(
                icon: Icons.remove_rounded,
                semanticLabel: 'Disminuir plazo',
                onPressed: previous == null ? null : () => onChanged(previous),
              ),
              Expanded(
                child: Column(
                  children: [
                    Text('$term', style: AppTextStyles.heroNumber(34, color: AppColors.onSurface)),
                    const Gap(8),
                    Text(unitCaption, style: AppTextStyles.captionLabel()),
                  ],
                ),
              ),
              _StepperButton(
                icon: Icons.add_rounded,
                semanticLabel: 'Aumentar plazo',
                onPressed: next == null ? null : () => onChanged(next),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StepperButton extends StatelessWidget {
  const _StepperButton({
    required this.icon,
    required this.semanticLabel,
    required this.onPressed,
  });

  final IconData icon;
  final String semanticLabel;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null;
    return Material(
      color: enabled ? AppColors.primaryContainer : AppColors.tickEmpty,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onPressed,
        child: SizedBox(
          width: 50,
          height: 50,
          child: Semantics(
            label: semanticLabel,
            child: Icon(icon, size: 24, color: enabled ? AppColors.primary : AppColors.disabled),
          ),
        ),
      ),
    );
  }
}
