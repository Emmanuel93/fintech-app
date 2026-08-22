import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../theme/ds_scale.dart';

/// Estado de un paso de [DsTimeline].
enum DsStepTone {
  /// Ya ocurrió o está garantizado — punto teal.
  done,

  /// Depende de alguien más y puede no ocurrir — punto ámbar.
  pending,

  /// Todavía no toca — punto gris y título apagado.
  future,
}

/// Un paso de la línea de tiempo.
class DsTimelineStep {
  const DsTimelineStep({
    required this.title,
    required this.description,
    this.tone = DsStepTone.future,
  });

  final String title, description;
  final DsStepTone tone;
}

/// Línea de tiempo vertical — "QUÉ SIGUE" de la colocación enviada
/// (Journey App L1357–L1370) y del cierre del KYC.
///
/// El tono no es decorativo: separa lo que Kredius garantiza de lo que depende
/// del beneficiario. Pintar los cuatro pasos iguales prometería cosas que no
/// están en manos de nadie de este lado.
class DsTimeline extends StatelessWidget {
  const DsTimeline({super.key, required this.steps});

  final List<DsTimelineStep> steps;

  static Color _dotColor(DsStepTone tone) => switch (tone) {
        DsStepTone.done => AppColors.secondary,
        DsStepTone.pending => AppColors.tertiary,
        DsStepTone.future => AppColors.dotInactive,
      };

  @override
  Widget build(BuildContext context) {
    final ds = DsScale.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final (i, step) in steps.indexed)
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Column(
                  children: [
                    SizedBox(height: ds.h(3)),
                    Container(
                      width: ds.w(11),
                      height: ds.w(11),
                      decoration: BoxDecoration(
                        color: _dotColor(step.tone),
                        shape: BoxShape.circle,
                      ),
                    ),
                    if (i < steps.length - 1)
                      Expanded(
                        child: Container(
                          width: ds.w(2),
                          margin: EdgeInsets.symmetric(vertical: ds.h(4)),
                          color: AppColors.divider,
                        ),
                      ),
                  ],
                ),
                SizedBox(width: ds.w(13)),
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(
                        bottom: i < steps.length - 1 ? ds.h(16) : 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(step.title,
                            style: AppTextStyles.body(
                              fontSize: ds.sp(13.5),
                              weight: FontWeight.w600,
                              color: step.tone == DsStepTone.future
                                  ? AppColors.disabled
                                  : AppColors.onSurface,
                            ).copyWith(height: 1.25)),
                        SizedBox(height: ds.h(5)),
                        Text(step.description,
                            style: AppTextStyles.body(
                              fontSize: ds.sp(11.5),
                              color: AppColors.disabled,
                            ).copyWith(height: 1.45)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

/// Barra de progreso por segmentos — los 3 tramos del flujo de colocación
/// (Journey App L1038–L1042, `beneSteps`).
///
/// A diferencia de `DsStepIndicator` (que numera pasos del alta), aquí sólo
/// importa cuánto falta: los pasos no tienen nombre en pantalla.
class DsSegmentBar extends StatelessWidget {
  const DsSegmentBar({
    super.key,
    required this.total,
    required this.current,
  });

  /// Número de segmentos.
  final int total;

  /// Índice del segmento actual, base 0. Todos los anteriores se pintan llenos.
  final int current;

  @override
  Widget build(BuildContext context) {
    final ds = DsScale.of(context);
    return Semantics(
      label: 'Paso ${current + 1} de $total',
      child: Row(
        children: [
          for (var i = 0; i < total; i++) ...[
            if (i > 0) SizedBox(width: ds.w(6)),
            Expanded(
              child: Container(
                height: ds.h(5),
                decoration: BoxDecoration(
                  color: i <= current
                      ? AppColors.primary
                      : AppColors.filledBorder,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
