import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_radii.dart';
import '../theme/app_text_styles.dart';
import '../theme/ds_scale.dart';

/// Un dato de la rejilla inferior de [DsLineSummaryCard].
///
/// [good] pinta el valor en verde menta: se reserva para la bonificación, que
/// es lo único de la rejilla que entra a favor del distribuidor.
class DsLineFact {
  const DsLineFact({required this.label, required this.value, this.good = false});

  final String label, value;
  final bool good;
}

/// Tarjeta "MI LÍNEA DE DISTRIBUIDOR" del home — Journey App L703–L734.
///
/// Es la tarjeta operativa de quien coloca: arriba cuánto lleva colocado contra
/// lo autorizado, en medio la rejilla de la quincena (qué va a cobrar, qué le
/// toca pagar a Kredius, cuándo vence y cuánto lleva ganado) y abajo la única
/// acción que importa, enviar un préstamo.
///
/// El orden no es decorativo: el diseño pone *disponible* justo debajo de la
/// barra porque es el número que decide si se puede colocar hoy.
class DsLineSummaryCard extends StatelessWidget {
  const DsLineSummaryCard({
    super.key,
    required this.placed,
    required this.authorizedNote,
    required this.available,
    required this.progress,
    required this.status,
    required this.facts,
    required this.ctaLabel,
    required this.onCta,
  });

  /// Monto colocado, ya formateado ("$45,000").
  final String placed;

  /// Pie del monto: "de $250,000 autorizados".
  final String authorizedNote;

  /// "DISPONIBLE $205,000".
  final String available;

  /// 0..1 — porción de la línea ya colocada.
  final double progress;

  /// Estado de la línea ("AL CORRIENTE", "EN MORA").
  final String status;

  final List<DsLineFact> facts;
  final String ctaLabel;
  final VoidCallback onCta;

  @override
  Widget build(BuildContext context) {
    final ds = DsScale.of(context);

    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(ds.r(18)),
      ),
      child: Stack(
        children: [
          Positioned(
            right: ds.w(-70),
            top: ds.h(-70),
            child: IgnorePointer(
              child: Container(
                width: ds.w(190),
                height: ds.w(190),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      AppColors.accentGreen.withValues(alpha: 0.32),
                      AppColors.accentGreen.withValues(alpha: 0),
                    ],
                    stops: const [0, 0.7],
                  ),
                ),
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.all(ds.w(16)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Colocado',
                              style: AppTextStyles.body(
                                fontSize: ds.sp(10.5),
                                weight: FontWeight.w500,
                                color: AppColors.onPrimary
                                    .withValues(alpha: 0.62),
                              ).copyWith(height: 1.0)),
                          SizedBox(height: ds.h(8)),
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerLeft,
                            child: Text(placed,
                                maxLines: 1,
                                style: AppTextStyles.heroNumber(ds.sp(24),
                                        color: AppColors.onPrimary)
                                    .copyWith(letterSpacing: -1.1)),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(width: ds.w(12)),
                    Container(
                      padding: EdgeInsets.symmetric(
                          horizontal: ds.w(9), vertical: ds.h(5)),
                      decoration: BoxDecoration(
                        color: AppColors.onPrimary.withValues(alpha: 0.16),
                        borderRadius: BorderRadius.circular(AppRadii.chip),
                      ),
                      child: Text(status,
                          style: AppTextStyles.chipLabel(
                            fontSize: ds.sp(9),
                            color: AppColors.onPrimary,
                          ).copyWith(height: 1.4)),
                    ),
                  ],
                ),
                SizedBox(height: ds.h(12)),
                ClipRRect(
                  borderRadius: BorderRadius.circular(AppRadii.chip),
                  child: LinearProgressIndicator(
                    value: progress.clamp(0.0, 1.0),
                    minHeight: ds.h(6),
                    backgroundColor: AppColors.onPrimary.withValues(alpha: 0.18),
                    valueColor: const AlwaysStoppedAnimation<Color>(
                        AppColors.accentGreen),
                  ),
                ),
                SizedBox(height: ds.h(7)),
                // Disponible y autorizado en el mismo renglón, bajo la barra:
                // es la lectura que el diseño quiere —cuánto queda de cuánto—.
                // Antes estaban separados, con el autorizado allá arriba pegado
                // al monto colocado, que es el número contrario.
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: Text(available,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.body(
                            fontSize: ds.sp(9.5),
                            weight: FontWeight.w600,
                            color:
                                AppColors.onPrimary.withValues(alpha: 0.55),
                          ).copyWith(height: 1.3, letterSpacing: 0.07 * 9.5)),
                    ),
                    SizedBox(width: ds.w(10)),
                    Text(authorizedNote,
                        maxLines: 1,
                        style: AppTextStyles.body(
                          fontSize: ds.sp(9.5),
                          color: AppColors.onPrimary.withValues(alpha: 0.45),
                        ).copyWith(height: 1.3)),
                  ],
                ),
                if (facts.isNotEmpty) ...[
                  SizedBox(height: ds.h(12)),
                  _FactGrid(facts: facts),
                ],
                SizedBox(height: ds.h(12)),
                Material(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(ds.r(11)),
                  child: InkWell(
                    onTap: onCta,
                    borderRadius: BorderRadius.circular(ds.r(11)),
                    child: Container(
                      height: ds.h(40),
                      alignment: Alignment.center,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.arrow_forward_rounded,
                              size: ds.sp(15), color: AppColors.primary),
                          SizedBox(width: ds.w(8)),
                          Flexible(
                            child: Text(ctaLabel,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: AppTextStyles.cardTitle(
                                        fontSize: ds.sp(13),
                                        color: AppColors.primary)
                                    .copyWith(height: 1.0)),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Rejilla 2×2 sobre el azul: celdas al 6 % de blanco separadas por 1 px, que
/// es lo que dibuja las divisiones sin pintar una línea (Journey App L720–L727).
class _FactGrid extends StatelessWidget {
  const _FactGrid({required this.facts});

  final List<DsLineFact> facts;

  @override
  Widget build(BuildContext context) {
    final ds = DsScale.of(context);
    final rows = <Widget>[];

    for (var i = 0; i < facts.length; i += 2) {
      if (i > 0) rows.add(SizedBox(height: ds.h(1)));
      rows.add(IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(child: _Cell(fact: facts[i])),
            if (i + 1 < facts.length) ...[
              SizedBox(width: ds.w(1)),
              Expanded(child: _Cell(fact: facts[i + 1])),
            ] else
              const Spacer(),
          ],
        ),
      ));
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(ds.r(11)),
      child: Column(children: rows),
    );
  }
}

class _Cell extends StatelessWidget {
  const _Cell({required this.fact});

  final DsLineFact fact;

  @override
  Widget build(BuildContext context) {
    final ds = DsScale.of(context);
    return Container(
      color: AppColors.onPrimary.withValues(alpha: 0.06),
      padding: EdgeInsets.symmetric(horizontal: ds.w(11), vertical: ds.h(9)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(fact.label,
              style: AppTextStyles.body(
                fontSize: ds.sp(9.5),
                color: AppColors.onPrimary.withValues(alpha: 0.55),
              ).copyWith(height: 1.3)),
          SizedBox(height: ds.h(6)),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(fact.value,
                maxLines: 1,
                style: AppTextStyles.heroNumber(
                  ds.sp(13.5),
                  color: fact.good
                      ? AppColors.onPrimaryAccent
                      : AppColors.onPrimary,
                  weight: FontWeight.w700,
                )),
          ),
        ],
      ),
    );
  }
}
