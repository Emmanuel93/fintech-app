import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_radii.dart';
import '../theme/app_text_styles.dart';
import '../theme/ds_scale.dart';

/// Estado vacío del home — "Todavía no tienes un crédito" (Journey L703–L711).
///
/// Icono en tile de 66, título y copy centrados. Se usa cuando el prospecto ya
/// pasó la revisión pero aún no ha elegido producto: el tono es de invitación,
/// no de error.
class DsEmptyStateCard extends StatelessWidget {
  const DsEmptyStateCard({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.onTap,
    this.semanticLabel,
  });

  final IconData icon;
  final String title, message;

  /// Qué hacer al tocarla. El diseño la pinta sin botón, pero su copia ya dice
  /// que "lo que sigue es escoger": para quien tiene línea de colocación —cuyo
  /// nav no lleva Oportunidades (Journey L1719–L1726)— ésta es la única puerta
  /// al catálogo, y sin ella un distribuidor no podría tomar un crédito propio.
  final VoidCallback? onTap;

  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final ds = DsScale.of(context);
    final tarjeta = Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
          horizontal: ds.w(20), vertical: ds.h(26)),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(ds.r(AppRadii.card)),
        border: Border.all(color: AppColors.outlineVariant),
      ),
      child: Column(
        children: [
          Container(
            width: ds.w(66),
            height: ds.w(66),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.surfaceVariant,
              borderRadius: BorderRadius.circular(ds.r(20)),
            ),
            child: Icon(icon, size: ds.sp(30), color: AppColors.primary),
          ),
          SizedBox(height: ds.h(14)),
          Text(title,
              textAlign: TextAlign.center,
              style: AppTextStyles.sectionTitle(fontSize: ds.sp(18))
                  .copyWith(height: 1.25)),
          SizedBox(height: ds.h(9)),
          Text(message,
              textAlign: TextAlign.center,
              style: AppTextStyles.body(fontSize: ds.sp(13.5))),
        ],
      ),
    );

    if (onTap == null) return tarjeta;
    return Semantics(
      button: true,
      label: semanticLabel ?? title,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: tarjeta,
      ),
    );
  }
}

/// Tarjeta azul de oportunidades — Journey L779–L794.
///
/// Blob verde de fondo, icono de estrella en tile translúcido, título + copy y
/// un CTA blanco con chevron. Es el único bloque del home que empuja a la
/// acción comercial, y por eso es el único en azul.
class DsPromoCard extends StatelessWidget {
  const DsPromoCard({
    super.key,
    required this.title,
    required this.message,
    required this.ctaLabel,
    required this.onTap,
    this.icon = Icons.star_outline_rounded,
  });

  final String title, message, ctaLabel;
  final VoidCallback onTap;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final ds = DsScale.of(context);
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(ds.r(AppRadii.card)),
      ),
      child: Stack(
        children: [
          // Blob verde arriba-derecha, igual que el héroe.
          Positioned(
            right: ds.w(-70),
            top: ds.h(-70),
            child: IgnorePointer(
              child: Container(
                width: ds.w(200),
                height: ds.w(200),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      AppColors.accentGreen.withValues(alpha: 0.35),
                      AppColors.accentGreen.withValues(alpha: 0),
                    ],
                    stops: const [0, 0.7],
                  ),
                ),
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.all(ds.w(20)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: ds.w(40),
                      height: ds.w(40),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: AppColors.onPrimary.withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(ds.r(12)),
                      ),
                      child: Icon(icon,
                          size: ds.sp(20), color: AppColors.onPrimaryAccent),
                    ),
                    SizedBox(width: ds.w(13)),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(title,
                              style: AppTextStyles.sectionTitle(
                                fontSize: ds.sp(17),
                                color: AppColors.onPrimary,
                              ).copyWith(height: 1.25)),
                          SizedBox(height: ds.h(8)),
                          Text(message,
                              style: AppTextStyles.body(
                                fontSize: ds.sp(13),
                                color:
                                    AppColors.onPrimary.withValues(alpha: 0.72),
                              )),
                        ],
                      ),
                    ),
                  ],
                ),
                SizedBox(height: ds.h(16)),
                Material(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(ds.r(12)),
                  child: InkWell(
                    onTap: onTap,
                    borderRadius: BorderRadius.circular(ds.r(12)),
                    child: Container(
                      height: ds.h(46),
                      alignment: Alignment.center,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Flexible(
                            child: Text(ctaLabel,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: AppTextStyles.cardTitle(
                                        fontSize: ds.sp(14),
                                        color: AppColors.primary)
                                    .copyWith(height: 1.0)),
                          ),
                          SizedBox(width: ds.w(8)),
                          Icon(Icons.chevron_right_rounded,
                              size: ds.sp(16), color: AppColors.primary),
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

/// Tarjeta de crédito activo para el carrusel del home cuando hay **varios**
/// (Journey L752–L768). Ancho fijo de 252.
class DsActiveCreditCard extends StatelessWidget {
  const DsActiveCreditCard({
    super.key,
    required this.name,
    required this.meta,
    required this.status,
    required this.balance,
    required this.nextLabel,
    required this.nextValue,
    required this.progressLabel,
    required this.progress,
    required this.ctaLabel,
    required this.onCta,
    this.width = 250,
  });

  final String name, meta, status, balance;
  final String nextLabel, nextValue, progressLabel, ctaLabel;

  /// 0..1 — porción pagada / dispuesta.
  final double progress;
  final VoidCallback onCta;

  /// Ancho en px de diseño, o `null` para ocupar todo el renglón.
  ///
  /// El diseño usa **la misma tarjeta** para uno o varios créditos y sólo
  /// cambia esto: 250 en carrusel, 100% cuando hay uno solo (L2095).
  final double? width;

  @override
  Widget build(BuildContext context) {
    final ds = DsScale.of(context);
    // Blanco a distintas opacidades: es como el diseño jerarquiza sobre el
    // azul de marca (etiqueta .6, meta .58, pie .55, pista de la barra .18).
    Color velo(double a) => AppColors.onPrimary.withValues(alpha: a);

    return Container(
      width: width == null ? null : ds.w(width!),
      padding: EdgeInsets.all(ds.w(16)),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(ds.r(18)),
      ),
      child: Stack(
        children: [
          // Blob verde de la esquina — el mismo recurso del héroe azul.
          Positioned(
            right: ds.w(-60),
            top: ds.h(-60),
            child: Container(
              width: ds.w(170),
              height: ds.w(170),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppColors.accentGreen.withValues(alpha: 0.30),
                    AppColors.accentGreen.withValues(alpha: 0),
                  ],
                  stops: const [0.0, 0.7],
                ),
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('Saldo pendiente',
                            style: AppTextStyles.body(
                              fontSize: ds.sp(10.5),
                              weight: FontWeight.w500,
                              color: velo(0.6),
                            ).copyWith(height: 1.0)),
                        SizedBox(height: ds.h(8)),
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: Text(balance,
                              maxLines: 1,
                              style: AppTextStyles.heroNumber(ds.sp(22),
                                      color: AppColors.onPrimary)
                                  .copyWith(letterSpacing: -1)),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(width: ds.w(10)),
                  // El chip va traslúcido sobre el azul, no con los tonos
                  // claros de `DsStatusChip`: sobre este fondo se perderían.
                  Container(
                    padding: EdgeInsets.symmetric(
                        horizontal: ds.w(9), vertical: ds.h(5)),
                    decoration: BoxDecoration(
                      color: velo(0.16),
                      borderRadius: BorderRadius.circular(99),
                    ),
                    child: Text(status,
                        style: AppTextStyles.body(
                          fontSize: ds.sp(9),
                          weight: FontWeight.w600,
                          color: AppColors.onPrimary,
                        ).copyWith(height: 1.4, letterSpacing: 0.06 * 9)),
                  ),
                ],
              ),
              SizedBox(height: ds.h(11)),
              Text(name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.cardTitle(
                          fontSize: ds.sp(14), color: AppColors.onPrimary)
                      .copyWith(height: 1.2)),
              SizedBox(height: ds.h(6)),
              Text(meta,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.body(
                    fontSize: ds.sp(11),
                    color: velo(0.58),
                  ).copyWith(height: 1.35)),
              SizedBox(height: ds.h(11)),
              ClipRRect(
                borderRadius: BorderRadius.circular(99),
                child: LinearProgressIndicator(
                  value: progress.clamp(0.0, 1.0),
                  minHeight: ds.h(6),
                  backgroundColor: velo(0.18),
                  valueColor: const AlwaysStoppedAnimation<Color>(
                      AppColors.accentGreen),
                ),
              ),
              SizedBox(height: ds.h(11)),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: Text(progressLabel,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.body(
                          fontSize: ds.sp(9.5),
                          weight: FontWeight.w600,
                          color: velo(0.55),
                        ).copyWith(height: 1.4, letterSpacing: 0.08 * 9.5)),
                  ),
                  SizedBox(width: ds.w(10)),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(nextLabel,
                          style: AppTextStyles.body(
                            fontSize: ds.sp(10),
                            color: velo(0.55),
                          ).copyWith(height: 1.4)),
                      SizedBox(height: ds.h(6)),
                      Text(nextValue,
                          style: AppTextStyles.cardTitle(
                                  fontSize: ds.sp(13),
                                  color: AppColors.onPrimaryAccent)
                              .copyWith(height: 1.0)),
                    ],
                  ),
                ],
              ),
              SizedBox(height: ds.h(11)),
              // El CTA se invierte: blanco con letra azul, como en la línea de
              // distribuidor. Es la misma acción y tiene que verse igual.
              Material(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(ds.r(10)),
                child: InkWell(
                  onTap: onCta,
                  borderRadius: BorderRadius.circular(ds.r(10)),
                  child: Container(
                    height: ds.h(37),
                    alignment: Alignment.center,
                    padding: EdgeInsets.symmetric(horizontal: ds.w(10)),
                    child: Text(ctaLabel,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.cardTitle(
                                fontSize: ds.sp(12.5), color: AppColors.primary)
                            .copyWith(height: 1.0)),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
