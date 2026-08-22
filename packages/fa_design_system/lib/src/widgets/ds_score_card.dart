import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_radii.dart';
import '../theme/app_text_styles.dart';
import '../theme/ds_scale.dart';

/// Banda de riesgo del reporte de buró.
enum DsScoreBand { low, medium, high }

/// Tono de un renglón del desglose de riesgo.
enum DsFactTone { ok, warn, bad }

/// Un renglón del desglose ("Peor atraso en 24 meses" → "29 días").
class DsScoreFact {
  const DsScoreFact({
    required this.label,
    required this.value,
    this.tone = DsFactTone.ok,
  });

  final String label, value;
  final DsFactTone tone;
}

/// Tarjeta del semáforo de buró — Journey App L1228–L1253.
///
/// Enseña el score con su banda, una lectura en palabras y el desglose que la
/// sustenta. La banda se pinta como tres tramos con los otros dos atenuados,
/// no como una aguja: el objetivo es situar, no dar una precisión que el score
/// no tiene.
///
/// Deliberadamente **no** trae veredicto ni CTA: Kredius entrega el reporte y
/// la decisión es de quien coloca (L1260). El botón vive en la pantalla.
class DsBureauScoreCard extends StatelessWidget {
  const DsBureauScoreCard({
    super.key,
    required this.score,
    required this.band,
    required this.bandLabel,
    required this.title,
    required this.description,
    required this.facts,
  });

  final int score;
  final DsScoreBand band;

  /// "RIESGO MEDIO".
  final String bandLabel;

  /// Lectura en una línea — "Paga, pero se ha atrasado".
  final String title;

  final String description;
  final List<DsScoreFact> facts;

  static Color _bandInk(DsScoreBand b) => switch (b) {
        DsScoreBand.low => AppColors.error,
        DsScoreBand.medium => AppColors.amberInk,
        DsScoreBand.high => AppColors.secondary,
      };

  static Color _bandFill(DsScoreBand b) => switch (b) {
        DsScoreBand.low => AppColors.errorContainer,
        DsScoreBand.medium => AppColors.tertiaryContainer,
        DsScoreBand.high => AppColors.secondaryContainer,
      };

  static Color _factInk(DsFactTone t) => switch (t) {
        DsFactTone.ok => AppColors.secondary,
        DsFactTone.warn => AppColors.amberInk,
        DsFactTone.bad => AppColors.error,
      };

  @override
  Widget build(BuildContext context) {
    final ds = DsScale.of(context);
    final ink = _bandInk(band);

    return Container(
      padding: EdgeInsets.all(ds.w(20)),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(ds.r(AppRadii.card)),
        border: Border.all(color: AppColors.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Semantics(
                label: 'Score $score, ${bandLabel.toLowerCase()}',
                child: Container(
                  width: ds.w(96),
                  height: ds.w(96),
                  decoration: BoxDecoration(
                    color: _bandFill(band),
                    shape: BoxShape.circle,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('$score',
                          style: AppTextStyles.heroNumber(ds.sp(30),
                              color: ink)),
                      SizedBox(height: ds.h(7)),
                      Text('SCORE',
                          style: AppTextStyles.chipLabel(
                              fontSize: ds.sp(8.5), color: ink)),
                    ],
                  ),
                ),
              ),
              SizedBox(width: ds.w(18)),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: EdgeInsets.symmetric(
                          horizontal: ds.w(10), vertical: ds.h(5)),
                      decoration: BoxDecoration(
                        color: _bandFill(band),
                        borderRadius: BorderRadius.circular(AppRadii.chip),
                      ),
                      child: Text(bandLabel,
                          style: AppTextStyles.chipLabel(
                              fontSize: ds.sp(9.5), color: ink)),
                    ),
                    SizedBox(height: ds.h(11)),
                    Text(title,
                        style: AppTextStyles.sectionTitle(fontSize: ds.sp(17))
                            .copyWith(height: 1.25)),
                    SizedBox(height: ds.h(7)),
                    Text(description,
                        style: AppTextStyles.body(fontSize: ds.sp(12.5))),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: ds.h(18)),
          Row(
            children: [
              for (final b in DsScoreBand.values) ...[
                if (b != DsScoreBand.low) SizedBox(width: ds.w(2)),
                Expanded(
                  flex: b == DsScoreBand.medium ? 34 : 33,
                  child: Container(
                    height: ds.h(10),
                    decoration: BoxDecoration(
                      color: _bandInk(b)
                          .withValues(alpha: b == band ? 1 : 0.22),
                      borderRadius: BorderRadius.circular(AppRadii.chip),
                    ),
                  ),
                ),
              ],
            ],
          ),
          SizedBox(height: ds.h(18)),
          ClipRRect(
            borderRadius: BorderRadius.circular(ds.r(12)),
            child: Column(
              children: [
                for (final (i, fact) in facts.indexed) ...[
                  if (i > 0)
                    Container(height: 1, color: AppColors.divider),
                  Container(
                    color: AppColors.surface,
                    padding: EdgeInsets.symmetric(
                        horizontal: ds.w(14), vertical: ds.h(13)),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(fact.label,
                              style: AppTextStyles.body(fontSize: ds.sp(12.5))
                                  .copyWith(height: 1.35)),
                        ),
                        SizedBox(width: ds.w(14)),
                        Flexible(
                          child: Text(fact.value,
                              textAlign: TextAlign.right,
                              style: AppTextStyles.body(
                                fontSize: ds.sp(12.5),
                                weight: FontWeight.w700,
                                color: _factInk(fact.tone),
                              ).copyWith(height: 1.35)),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
