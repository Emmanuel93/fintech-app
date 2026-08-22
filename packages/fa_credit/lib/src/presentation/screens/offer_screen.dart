import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:fa_design_system/fa_design_system.dart';

import '../../domain/services/amortization_calculator.dart';
import '../providers/credit_application_provider.dart';

/// Pantallas 4 y 6 del prototipo, fusionadas — "Aprobado" (Journey L282–L315,
/// criterios L1170–L1176) y "Así lo solicitas" (L384–L396, pasos L1200–L1204).
///
/// En el prototipo son dos pantallas porque el catálogo se ve **después** de
/// aprobar. En la app el producto se elige antes (así lo exige el contrato del
/// BFF: la solicitud nace con un producto), así que al llegar aquí ya hay una
/// oferta concreta y el "cómo lo solicitas" cabe en la misma vista, debajo de
/// los criterios, sin un salto de pantalla que no aporta nada.
class OfferScreen extends StatelessWidget {
  const OfferScreen({super.key});

  /// Journey L1200–L1204.
  static const _howSteps = <(String, String)>[
    (
      'Confirma monto y plazo',
      'El pago se recalcula al momento: mueves el monto y ajustas las mensualidades.'
    ),
    (
      'Firma con tu código',
      'Te llega un SMS de 6 dígitos. Ese código es tu firma electrónica.'
    ),
    (
      'Recibe tu dinero',
      'Depositamos a tu cuenta en menos de 24 horas hábiles.'
    ),
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

    if (provider.isActing && !app.isOfferPresented) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final fmt =
        NumberFormat.currency(locale: 'es_MX', symbol: '\$', decimalDigits: 0);
    final revolving = app.offeredLine != null;
    final estimate = AmortizationCalculator.estimateForApplication(
      app,
      paymentFrequency: provider.selectedProduct?.defaultPaymentFrequency,
    );

    return Scaffold(
      backgroundColor: AppColors.surfaceVariant,
      body: DsResponsiveBody(
        child: CustomScrollView(
          slivers: [
            // Header azul a sangre — Journey L285–L299.
            SliverToBoxAdapter(
              child: _ApprovedHeader(
                amountLabel: fmt.format(app.offerAmountOrLine ?? 0),
                caption: revolving
                    ? 'Tienes una línea autorizada de'
                    : 'Tienes autorizado hasta',
                monthlyPayment: estimate != null
                    ? fmt.format(estimate.periodicPayment)
                    : null,
                term: app.offeredTerm,
              ),
            ),
            SliverPadding(
              padding: EdgeInsets.fromLTRB(
                  ds.gutter, ds.h(24), ds.gutter, ds.bottomGap(32)),
              sliver: SliverList.list(
                children: [
                  Text('Esto fue lo que revisamos',
                      style: AppTextStyles.sectionTitle(fontSize: ds.sp(19))),
                  SizedBox(height: ds.h(4)),
                  Text('En buró y círculo de crédito.',
                      style: AppTextStyles.body(fontSize: ds.sp(13.5))),
                  SizedBox(height: ds.h(16)),
                  for (final c in _criteria(app.offeredTerm)) ...[
                    _CriterionRow(label: c.$1, value: c.$2),
                    SizedBox(height: ds.h(9)),
                  ],

                  SizedBox(height: ds.h(16)),
                  Text('Así lo solicitas',
                      style: AppTextStyles.sectionTitle(fontSize: ds.sp(19))),
                  SizedBox(height: ds.h(4)),
                  Text('Tres pasos, todo desde tu celular.',
                      style: AppTextStyles.body(fontSize: ds.sp(13.5))),
                  SizedBox(height: ds.h(16)),
                  for (var i = 0; i < _howSteps.length; i++)
                    _HowStep(
                      number: i + 1,
                      title: _howSteps[i].$1,
                      description: _howSteps[i].$2,
                      isLast: i == _howSteps.length - 1,
                    ),

                  if (provider.error != null) ...[
                    SizedBox(height: ds.h(8)),
                    Text(provider.error!,
                        textAlign: TextAlign.center,
                        style: AppTextStyles.body(
                            fontSize: ds.sp(12.5), color: AppColors.error)),
                  ],
                  SizedBox(height: ds.h(22)),
                  DsButton(
                    label: 'Aceptar y continuar',
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
                  SizedBox(height: ds.h(10)),
                  DsButton(
                    label: 'Ahora no',
                    variant: DsButtonVariant.ghost,
                    onPressed:
                        provider.isActing ? null : () => context.go('/home'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Los criterios que el prototipo lista (Journey L1171–L1176). Hoy el BFF no
  /// devuelve el desglose del scoring, así que se muestran las dimensiones
  /// evaluadas sin inventar valores: en cuanto el endpoint los exponga, esto
  /// se alimenta de la respuesta.
  List<(String, String)> _criteria(int? term) => [
        ('Historial de pago', 'Revisado'),
        ('Antigüedad crediticia', 'Revisada'),
        ('Deuda vs. ingreso', 'Dentro del límite'),
        if (term != null) ('Plazo autorizado', '$term meses'),
      ];
}

/// Encabezado azul con el monto autorizado — Journey L285–L299.
class _ApprovedHeader extends StatelessWidget {
  const _ApprovedHeader({
    required this.amountLabel,
    required this.caption,
    this.monthlyPayment,
    this.term,
  });

  final String amountLabel, caption;
  final String? monthlyPayment;
  final int? term;

  @override
  Widget build(BuildContext context) {
    final ds = context.ds;
    return Container(
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
          // Badge con el punto que late — Journey L286–L289.
          DsHeroChip(
            label: 'SÍ CUMPLES LOS CRITERIOS',
            bordered: true,
            leading: KrPulse(
              child: Container(
                width: ds.w(7),
                height: ds.w(7),
                decoration: const BoxDecoration(
                  color: AppColors.accentGreen,
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ),
          SizedBox(height: ds.h(16)),
          Text(caption,
              style: AppTextStyles.body(
                fontSize: ds.sp(13),
                weight: FontWeight.w500,
                color: AppColors.onPrimary.withValues(alpha: 0.6),
              ).copyWith(height: 1.0)),
          SizedBox(height: ds.h(11)),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              amountLabel,
              maxLines: 1,
              style: AppTextStyles.heroNumber(ds.sp(46),
                  color: AppColors.onPrimary),
            ),
          ),
          if (monthlyPayment != null || term != null) ...[
            SizedBox(height: ds.h(18)),
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (monthlyPayment != null)
                    _HeaderFact(label: 'PAGO / MES', value: monthlyPayment!),
                  if (monthlyPayment != null && term != null) ...[
                    SizedBox(width: ds.w(20)),
                    Container(
                        width: 1,
                        color: AppColors.onPrimary.withValues(alpha: 0.18)),
                    SizedBox(width: ds.w(20)),
                  ],
                  if (term != null)
                    _HeaderFact(label: 'PLAZO', value: '$term meses'),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _HeaderFact extends StatelessWidget {
  const _HeaderFact({required this.label, required this.value});
  final String label, value;

  @override
  Widget build(BuildContext context) {
    final ds = context.ds;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label,
            style: AppTextStyles.captionLabel(
              fontSize: ds.sp(9.5),
              color: AppColors.onPrimary.withValues(alpha: 0.5),
            )),
        SizedBox(height: ds.h(8)),
        Text(value,
            style: AppTextStyles.cardTitle(
                    fontSize: ds.sp(15), color: AppColors.onPrimary)
                .copyWith(fontWeight: FontWeight.w600, height: 1.0)),
      ],
    );
  }
}

/// Fila de criterio con ✓ teal — Journey L305–L309.
class _CriterionRow extends StatelessWidget {
  const _CriterionRow({required this.label, required this.value});
  final String label, value;

  @override
  Widget build(BuildContext context) {
    final ds = context.ds;
    return Container(
      padding:
          EdgeInsets.symmetric(horizontal: ds.w(15), vertical: ds.h(12)),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(ds.r(12)),
        border: Border.all(color: AppColors.outlineVariant),
      ),
      child: Row(
        children: [
          Container(
            width: ds.w(22),
            height: ds.w(22),
            alignment: Alignment.center,
            decoration: const BoxDecoration(
                color: AppColors.secondary, shape: BoxShape.circle),
            child: Icon(Icons.check_rounded,
                size: ds.sp(13), color: AppColors.onPrimary),
          ),
          SizedBox(width: ds.w(12)),
          Expanded(
            child: Text(label,
                style: AppTextStyles.body(
                  fontSize: ds.sp(13.5),
                  weight: FontWeight.w600,
                  color: AppColors.onSurface,
                ).copyWith(height: 1.3)),
          ),
          SizedBox(width: ds.w(8)),
          Text(value,
              style: AppTextStyles.body(
                fontSize: ds.sp(12.5),
                weight: FontWeight.w500,
                color: AppColors.disabled,
              ).copyWith(height: 1.0)),
        ],
      ),
    );
  }
}

/// Paso con timeline — Journey L387–L395.
class _HowStep extends StatelessWidget {
  const _HowStep({
    required this.number,
    required this.title,
    required this.description,
    required this.isLast,
  });

  final int number;
  final String title, description;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final ds = context.ds;
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(
                width: ds.w(30),
                height: ds.w(30),
                alignment: Alignment.center,
                decoration: const BoxDecoration(
                  color: AppColors.primaryContainer,
                  shape: BoxShape.circle,
                ),
                child: Text('$number',
                    style: AppTextStyles.cardTitle(
                            fontSize: ds.sp(13), color: AppColors.primary)
                        .copyWith(height: 1.0)),
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 2,
                    margin: EdgeInsets.symmetric(vertical: ds.h(4)),
                    color: AppColors.outlineVariant,
                  ),
                ),
            ],
          ),
          SizedBox(width: ds.w(14)),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(
                  top: ds.h(4), bottom: isLast ? 0 : ds.h(18)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: AppTextStyles.cardTitle(fontSize: ds.sp(14.5))),
                  SizedBox(height: ds.h(5)),
                  Text(description,
                      style: AppTextStyles.body(
                        fontSize: ds.sp(12.5),
                        color: AppColors.disabled,
                      ).copyWith(height: 1.45)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
