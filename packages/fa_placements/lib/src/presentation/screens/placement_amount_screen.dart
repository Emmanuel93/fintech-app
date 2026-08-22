import 'package:fa_design_system/fa_design_system.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../domain/services/placement_quote.dart';
import '../providers/placement_provider.dart';
import '../widgets/placement_top_bar.dart';

/// Paso 2 de la colocación — cuánto le presta y en cuántas quincenas le paga
/// (Journey App L1275–L1340).
///
/// La pantalla enseña las dos caras a la vez: lo que ella paga cada quincena y
/// lo que él se gana. Separarlas invitaría a elegir el monto mirando sólo la
/// comisión.
class PlacementAmountScreen extends StatefulWidget {
  const PlacementAmountScreen({super.key, required this.draft});

  /// Lo capturado en el paso anterior: nombre, celular y relación.
  final Map<String, String> draft;

  @override
  State<PlacementAmountScreen> createState() => _PlacementAmountScreenState();
}

class _PlacementAmountScreenState extends State<PlacementAmountScreen> {
  static const double _defaultAmount = 45000;

  double? _amount;
  int _term = 24;

  String get _firstName =>
      (widget.draft['fullName'] ?? '').split(' ').firstOrNull ?? '';

  Future<void> _send() async {
    final provider = context.read<PlacementProvider>();
    final ok = await provider.submit(
      fullName: widget.draft['fullName'] ?? '',
      phone: widget.draft['phone'] ?? '',
      relationship: widget.draft['relationship'] ?? '',
      amount: _amount ?? _defaultAmount,
      termFortnights: _term,
    );
    if (!mounted) return;
    if (ok) {
      context.go('/placements/sent');
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(provider.error ?? 'No pudimos enviar la liga')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final ds = context.ds;
    final provider = context.watch<PlacementProvider>();
    final fmt =
        NumberFormat.currency(locale: 'es_MX', symbol: '\$', decimalDigits: 0);

    // El tope es la línea disponible, no el máximo comercial: ofrecer un monto
    // que no se puede fondear es prometer con dinero que no está.
    final max = provider.available <= PlacementPricing.minAmount
        ? PlacementPricing.minAmount
        : provider.available;
    final amount = (_amount ?? _defaultAmount).clamp(PlacementPricing.minAmount, max);
    final quote = PlacementQuote(amount: amount, termFortnights: _term);

    return Scaffold(
      backgroundColor: AppColors.surfaceVariant,
      body: SafeArea(
        child: DsResponsiveBody(
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: EdgeInsets.fromLTRB(
                      ds.gutterWide, ds.topGap, ds.gutterWide, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      PlacementTopBar(
                        title: 'Enviar préstamo a $_firstName',
                        trailing: 'Línea ${fmt.format(provider.available)}',
                        onBack: () => context.go('/placements/new'),
                      ),
                      SizedBox(height: ds.h(20)),
                      const DsSegmentBar(total: 3, current: 1),
                      SizedBox(height: ds.h(18)),
                      DsAmountSlider(
                        label: 'CUÁNTO LE PRESTAS',
                        amount: amount.toDouble(),
                        min: PlacementPricing.minAmount,
                        max: max.toDouble(),
                        step: PlacementPricing.amountStep.toInt(),
                        onChanged: (v) => setState(() => _amount = v),
                      ),
                      SizedBox(height: ds.h(12)),
                      DsTermStepper(
                        label: 'EN CUÁNTAS QUINCENAS TE PAGA',
                        unitCaption: 'QUINCENAS',
                        term: _term,
                        min: PlacementPricing.terms.first,
                        max: PlacementPricing.terms.last,
                        steps: PlacementPricing.terms,
                        onChanged: (t) => setState(() => _term = t),
                      ),
                      SizedBox(height: ds.h(12)),
                      _Summary(
                        quote: quote,
                        lineAfter: provider.available - amount,
                      ),
                      SizedBox(height: ds.h(12)),
                      const DsNoticeBanner(
                        text: 'La comisión es del 20% sobre lo que cobras a '
                            'tiempo. Cada día de atraso la baja: 17%, 14%, 10%, '
                            '6% y al quinto día, cero.',
                      ),
                      SizedBox(height: ds.h(20)),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: EdgeInsets.fromLTRB(
                    ds.gutterWide, 0, ds.gutterWide, ds.bottomGap(28)),
                child: DsButton(
                  label: 'Enviarle la liga por WhatsApp',
                  isLoading: provider.isSubmitting,
                  onPressed: provider.isSubmitting ? null : _send,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Bloque azul con las dos caras de la operación — Journey App L1310–L1331.
class _Summary extends StatelessWidget {
  const _Summary({required this.quote, required this.lineAfter});

  final PlacementQuote quote;
  final double lineAfter;

  @override
  Widget build(BuildContext context) {
    final ds = context.ds;
    final fmt =
        NumberFormat.currency(locale: 'es_MX', symbol: '\$', decimalDigits: 0);

    final rows = <(String, String)>[
      ('Total que te paga', fmt.format(quote.totalToCollect)),
      (
        'Tu bonificación si cobras todo a tiempo',
        fmt.format(quote.commissionIfAllOnTime)
      ),
      ('Tu línea después de este préstamo', fmt.format(lineAfter.clamp(0, double.infinity))),
    ];

    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(ds.r(AppRadii.card)),
      ),
      child: Stack(
        children: [
          Positioned(
            right: ds.w(-60),
            top: ds.h(-60),
            child: IgnorePointer(
              child: Container(
                width: ds.w(180),
                height: ds.w(180),
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
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: _Figure(
                        label: 'Ella paga cada quincena',
                        value: fmt.format(quote.fortnightlyPayment),
                        size: 28,
                      ),
                    ),
                    SizedBox(width: ds.w(14)),
                    _Figure(
                      label: 'Tu bonificación',
                      value: fmt.format(quote.commissionPerPayment),
                      size: 22,
                      accent: true,
                      alignEnd: true,
                    ),
                  ],
                ),
                SizedBox(height: ds.h(14)),
                Container(
                    height: 1,
                    color: AppColors.onPrimary.withValues(alpha: 0.18)),
                SizedBox(height: ds.h(14)),
                for (final (i, row) in rows.indexed) ...[
                  if (i > 0) SizedBox(height: ds.h(9)),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(row.$1,
                            style: AppTextStyles.body(
                              fontSize: ds.sp(12.5),
                              color:
                                  AppColors.onPrimary.withValues(alpha: 0.66),
                            ).copyWith(height: 1.4)),
                      ),
                      SizedBox(width: ds.w(12)),
                      Text(row.$2,
                          style: AppTextStyles.body(
                            fontSize: ds.sp(13),
                            weight: FontWeight.w700,
                            color: AppColors.onPrimary,
                          ).copyWith(height: 1.4)),
                    ],
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

class _Figure extends StatelessWidget {
  const _Figure({
    required this.label,
    required this.value,
    required this.size,
    this.accent = false,
    this.alignEnd = false,
  });

  final String label, value;
  final double size;
  final bool accent, alignEnd;

  @override
  Widget build(BuildContext context) {
    final ds = context.ds;
    return Column(
      crossAxisAlignment:
          alignEnd ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        Text(label,
            style: AppTextStyles.body(
              fontSize: ds.sp(11.5),
              weight: FontWeight.w500,
              color: AppColors.onPrimary.withValues(alpha: 0.62),
            ).copyWith(height: 1.0)),
        SizedBox(height: ds.h(9)),
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: alignEnd ? Alignment.centerRight : Alignment.centerLeft,
          child: Text(value,
              maxLines: 1,
              style: AppTextStyles.heroNumber(
                ds.sp(size),
                color:
                    accent ? AppColors.onPrimaryAccent : AppColors.onPrimary,
              )),
        ),
      ],
    );
  }
}
