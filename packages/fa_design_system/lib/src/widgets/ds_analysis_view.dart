import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../theme/ds_scale.dart';
import '../motion/kredius_motion.dart';
import 'ds_hero_scaffold.dart';

/// Pantalla de análisis — héroe azul con el anillo `kr-spin` de 112px y la
/// lista de pasos (Journey L369–L390, estilos L1162–L1167).
///
/// La usan dos momentos del journey con los mismos elementos y distinto texto:
/// el alta (crear cuenta + precalificar) y la solicitud de un crédito. Vive en
/// el design system para que no haya dos copias que se desincronicen.
///
/// **Un paso "hecho" significa hecho de verdad.** El caller controla
/// [currentStep]; la vista no adelanta nada por su cuenta.
class DsAnalysisView extends StatelessWidget {
  const DsAnalysisView({
    super.key,
    required this.title,
    required this.subtitle,
    required this.steps,
    required this.currentStep,
    this.footnote = 'CONEXIÓN SEGURA · CIFRADO EXTREMO A EXTREMO',
  });

  final String title, subtitle;
  final List<String> steps;

  /// Índice del paso en curso. `steps.length` = todos completos.
  final int currentStep;

  final String footnote;

  @override
  Widget build(BuildContext context) {
    final ds = DsScale.of(context);

    return DsHeroScaffold(
      blobs: DsHeroBlobs.none,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(height: ds.h(34)),
          Center(
            child: Column(
              children: [
                KrSpinRing(size: ds.w(112)),
                SizedBox(height: ds.h(24)),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: AppTextStyles.screenTitle(
                    fontSize: ds.sp(25),
                    color: AppColors.onPrimary,
                  ),
                ),
                SizedBox(height: ds.h(9)),
                Text(
                  subtitle,
                  textAlign: TextAlign.center,
                  style: AppTextStyles.body(
                    fontSize: ds.sp(14),
                    color: AppColors.onPrimary.withValues(alpha: 0.62),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: ds.h(48)),
          for (var i = 0; i < steps.length; i++) ...[
            if (i > 0) SizedBox(height: ds.h(8)),
            DsAnalysisStep(
              label: steps[i],
              done: currentStep > i,
              active: currentStep == i,
            ),
          ],
          const Spacer(),
          SizedBox(height: ds.h(20)),
          Text(
            footnote,
            textAlign: TextAlign.center,
            style: AppTextStyles.captionLabel(
              fontSize: ds.sp(10),
              color: AppColors.onPrimary.withValues(alpha: 0.4),
            ).copyWith(height: 1.5),
          ),
        ],
      ),
    );
  }
}

/// Fila de paso del análisis — Journey L272–L275.
class DsAnalysisStep extends StatelessWidget {
  const DsAnalysisStep({
    super.key,
    required this.label,
    required this.done,
    required this.active,
  });

  final String label;
  final bool done, active;

  @override
  Widget build(BuildContext context) {
    final ds = DsScale.of(context);

    return Semantics(
      liveRegion: active,
      label:
          '$label. ${done ? 'Completado' : active ? 'En curso' : 'Pendiente'}',
      child: AnimatedContainer(
        duration: KrediusMotion.tab,
        padding: EdgeInsets.symmetric(horizontal: ds.w(16), vertical: ds.h(15)),
        decoration: BoxDecoration(
          color: active
              ? AppColors.onPrimary.withValues(alpha: 0.10)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(ds.r(14)),
          border: Border.all(
            color: active
                ? AppColors.onPrimary.withValues(alpha: 0.16)
                : Colors.transparent,
          ),
        ),
        child: Row(
          children: [
            KrPulse(
              enabled: active,
              period: KrediusMotion.pulseFast,
              child: Container(
                width: ds.w(24),
                height: ds.w(24),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: done
                      ? AppColors.accentGreen
                      : AppColors.onPrimary.withValues(alpha: 0.16),
                ),
                child: done
                    ? Icon(Icons.check_rounded,
                        size: ds.sp(14), color: AppColors.onPrimary)
                    : null,
              ),
            ),
            SizedBox(width: ds.w(13)),
            Expanded(
              child: Text(
                label,
                style: AppTextStyles.body(
                  fontSize: ds.sp(14),
                  weight: FontWeight.w600,
                  color: done || active
                      ? AppColors.onPrimary
                      : AppColors.onPrimary.withValues(alpha: 0.42),
                ).copyWith(height: 1.3),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
