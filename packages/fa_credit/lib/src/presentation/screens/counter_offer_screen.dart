import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:fa_design_system/fa_design_system.dart';

import '../../domain/services/amortization_calculator.dart';
import '../providers/credit_application_provider.dart';

/// Pantalla 12 del prototipo — "Pero sí tenemos algo para ti"
/// (Journey L807–L836, tips en L1263–L1267).
///
/// Ruta alterna: el scoring autoriza **menos** de lo que se pidió. En vez de un
/// rechazo seco, se ofrece el monto real con el pago que implica, más las tres
/// palancas que suben el monto en una próxima solicitud.
///
/// Se llega aquí desde el análisis cuando la oferta presentada es menor al
/// monto solicitado.
class CounterOfferScreen extends StatelessWidget {
  const CounterOfferScreen({super.key});

  /// Journey L1263–L1267.
  static const _tips = [
    'Baja el uso de tus tarjetas por debajo del 30% de su límite.',
    'Mantén tres meses seguidos sin atrasos en ningún crédito.',
    'Evita solicitar crédito nuevo en los próximos 60 días.',
  ];

  @override
  Widget build(BuildContext context) {
    final ds = context.ds;
    final provider = context.watch<CreditApplicationProvider>();
    final app = provider.application;

    if (app == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted) context.go('/credit/apply');
      });
      return const SizedBox.shrink();
    }

    final fmt =
        NumberFormat.currency(locale: 'es_MX', symbol: '\$', decimalDigits: 0);
    final offered = app.offerAmountOrLine ?? 0;
    final estimate = AmortizationCalculator.estimateForApplication(
      app,
      paymentFrequency: provider.selectedProduct?.defaultPaymentFrequency,
    );

    return Scaffold(
      backgroundColor: AppColors.surfaceVariant,
      body: DsResponsiveBody(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Container(
                width: double.infinity,
                padding: EdgeInsets.fromLTRB(
                    ds.w(24), ds.topGapBand, ds.w(24), ds.h(30)),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius:
                      BorderRadius.vertical(bottom: Radius.circular(ds.r(28))),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Badge ámbar — Journey L811.
                    DsHeroChip(
                      label: 'NO ALCANZASTE EL MONTO QUE PEDISTE',
                      tint: AppColors.tertiary,
                      foreground: AppColors.onPrimaryWarning,
                    ),
                    SizedBox(height: ds.h(13)),
                    Text('Pero sí tenemos algo para ti',
                        style: AppTextStyles.heroTitle(ds.sp(28),
                            color: AppColors.onPrimary)),
                    SizedBox(height: ds.h(10)),
                    Text(
                      'Con tu perfil actual podemos autorizarte un monto menor. '
                      'Es real, es tuyo y lo puedes tomar hoy.',
                      style: AppTextStyles.body(
                        fontSize: ds.sp(13.5),
                        color: AppColors.onPrimary.withValues(alpha: 0.65),
                      ).copyWith(height: 1.55),
                    ),
                  ],
                ),
              ),
            ),
            SliverPadding(
              padding: EdgeInsets.fromLTRB(
                  ds.gutter, ds.h(22), ds.gutter, ds.bottomGap(30)),
              sliver: SliverList.list(
                children: [
                  // Tarjeta con borde 2px primary — Journey L816–L822.
                  Container(
                    padding: EdgeInsets.all(ds.w(20)),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius:
                          BorderRadius.circular(ds.r(AppRadii.card)),
                      border:
                          Border.all(color: AppColors.primary, width: 2),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text('CONTRAOFERTA',
                            style: AppTextStyles.captionLabel(
                                fontSize: ds.sp(10),
                                color: AppColors.primary)),
                        SizedBox(height: ds.h(14)),
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: Text(fmt.format(offered),
                              maxLines: 1,
                              style: AppTextStyles.heroNumber(ds.sp(42))),
                        ),
                        SizedBox(height: ds.h(14)),
                        const Divider(height: 1, color: AppColors.divider),
                        if (estimate != null) ...[
                          SizedBox(height: ds.h(14)),
                          _Row(
                            label: 'Pagas cada ${estimate.periodLabel}',
                            value: fmt.format(estimate.periodicPayment),
                            emphasis: true,
                          ),
                          SizedBox(height: ds.h(10)),
                          _Row(
                            label: app.offeredTerm != null
                                ? 'Total a pagar (${app.offeredTerm} meses)'
                                : 'Total a pagar',
                            value: fmt.format(estimate.totalRepayment),
                          ),
                        ],
                      ],
                    ),
                  ),
                  SizedBox(height: ds.h(24)),
                  Text('Qué levanta tu monto',
                      style: AppTextStyles.sectionTitle(fontSize: ds.sp(17))),
                  SizedBox(height: ds.h(12)),
                  for (final tip in _tips) ...[
                    _TipRow(text: tip),
                    SizedBox(height: ds.h(9)),
                  ],
                  SizedBox(height: ds.h(13)),
                  DsButton(
                    label: 'Aceptar ${fmt.format(offered)}',
                    isLoading: provider.isActing,
                    onPressed: provider.isActing
                        ? null
                        : () async {
                            final ok = await context
                                .read<CreditApplicationProvider>()
                                .acceptOffer();
                            if (ok && context.mounted) {
                              context.go('/credit/apply/contract');
                            }
                          },
                  ),
                  SizedBox(height: ds.h(14)),
                  Center(
                    child: GestureDetector(
                      onTap: () => context.go('/home'),
                      behavior: HitTestBehavior.opaque,
                      child: Padding(
                        padding: EdgeInsets.symmetric(vertical: ds.h(6)),
                        child: Text('Avísame en 3 meses',
                            style: AppTextStyles.body(
                              fontSize: ds.sp(12.5),
                              weight: FontWeight.w500,
                              color: AppColors.disabled,
                            ).copyWith(height: 1.0)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({required this.label, required this.value, this.emphasis = false});
  final String label, value;
  final bool emphasis;

  @override
  Widget build(BuildContext context) {
    final ds = context.ds;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: [
        Expanded(
          child: Text(label,
              style: AppTextStyles.body(fontSize: ds.sp(13)).copyWith(height: 1.0)),
        ),
        SizedBox(width: ds.w(10)),
        Text(value,
            style: AppTextStyles.cardTitle(fontSize: ds.sp(emphasis ? 17 : 15))
                .copyWith(height: 1.0)),
      ],
    );
  }
}

/// Tip con punto ámbar — Journey L826–L829.
class _TipRow extends StatelessWidget {
  const _TipRow({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    final ds = context.ds;
    return Container(
      padding:
          EdgeInsets.symmetric(horizontal: ds.w(15), vertical: ds.h(13)),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(ds.r(12)),
        border: Border.all(color: AppColors.outlineVariant),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: ds.w(7),
            height: ds.w(7),
            margin: EdgeInsets.only(top: ds.h(6)),
            decoration: const BoxDecoration(
                color: AppColors.tertiary, shape: BoxShape.circle),
          ),
          SizedBox(width: ds.w(12)),
          Expanded(
            child: Text(text,
                style: AppTextStyles.body(
                  fontSize: ds.sp(13),
                  weight: FontWeight.w500,
                  color: AppColors.onSurface,
                ).copyWith(height: 1.45)),
          ),
        ],
      ),
    );
  }
}
