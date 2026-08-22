import 'package:fa_design_system/fa_design_system.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../domain/entities/bureau_report.dart';
import '../providers/placement_provider.dart';
import '../widgets/placement_top_bar.dart';

/// El historial del beneficiario y la decisión del distribuidor
/// (Journey App L1211–L1273).
///
/// Kredius entrega el reporte completo y **no decide**: no hay un "aprobado por
/// Kredius" en ninguna parte de esta pantalla. Por eso el CTA está bloqueado
/// tras una casilla explícita de asunción de riesgo — es la constancia de que
/// el distribuidor vio el historial antes de colocar.
class PlacementBureauScreen extends StatefulWidget {
  const PlacementBureauScreen({super.key, required this.placementId});

  final String placementId;

  @override
  State<PlacementBureauScreen> createState() => _PlacementBureauScreenState();
}

class _PlacementBureauScreenState extends State<PlacementBureauScreen> {
  bool _riskAcknowledged = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PlacementProvider>().open(widget.placementId);
    });
  }

  Future<void> _decide({required bool approve}) async {
    final provider = context.read<PlacementProvider>();
    final ok = await provider.decide(approve: approve);
    if (!mounted) return;
    if (ok) {
      context.go('/home');
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(provider.error ?? 'No pudimos guardar tu decisión')),
      );
    }
  }

  static DsScoreBand _band(BureauBand b) => switch (b) {
        BureauBand.low => DsScoreBand.low,
        BureauBand.medium => DsScoreBand.medium,
        BureauBand.high => DsScoreBand.high,
      };

  static DsFactTone _tone(BureauFactTone t) => switch (t) {
        BureauFactTone.ok => DsFactTone.ok,
        BureauFactTone.warn => DsFactTone.warn,
        BureauFactTone.bad => DsFactTone.bad,
      };

  @override
  Widget build(BuildContext context) {
    final ds = context.ds;
    final provider = context.watch<PlacementProvider>();
    final placement = provider.current;
    final report = provider.report;
    final firstName =
        placement?.beneficiaryName.split(' ').firstOrNull ?? 'tu beneficiaria';

    return Scaffold(
      backgroundColor: AppColors.surfaceVariant,
      body: SafeArea(
        child: DsResponsiveBody(
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding:
                      EdgeInsets.fromLTRB(ds.gutter, ds.topGap, ds.gutter, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      PlacementTopBar(
                        title: 'Historial de $firstName',
                        trailing: report == null ? null : 'KYC OK',
                        trailingTone: DsChipTone.ok,
                        onBack: () => context.go('/home'),
                      ),
                      SizedBox(height: ds.h(20)),
                      const DsSegmentBar(total: 3, current: 2),
                      SizedBox(height: ds.h(20)),
                      Text('Esto encontramos de ella',
                          style: AppTextStyles.heroTitle(ds.sp(24))
                              .copyWith(height: 1.2)),
                      SizedBox(height: ds.h(10)),
                      Text(
                        'Consultamos su buró con la autorización que ella '
                        'firmó. Te lo pasamos completo para que decidas con '
                        'datos, no a ciegas.',
                        style: AppTextStyles.body(fontSize: ds.sp(13.5))
                            .copyWith(height: 1.55),
                      ),
                      SizedBox(height: ds.h(18)),
                      if (report == null)
                        _Waiting(loading: provider.isLoading, name: firstName)
                      else ...[
                        DsBureauScoreCard(
                          score: report.score,
                          band: _band(report.band),
                          bandLabel: report.bandLabel,
                          title: report.title,
                          description: report.description,
                          facts: [
                            for (final f in report.facts)
                              DsScoreFact(
                                label: f.label,
                                value: f.value,
                                tone: _tone(f.tone),
                              ),
                          ],
                        ),
                        SizedBox(height: ds.h(14)),
                        const _NoDecisionNotice(),
                        SizedBox(height: ds.h(14)),
                        DsConsentCheck(
                          value: _riskAcknowledged,
                          onChanged: (v) =>
                              setState(() => _riskAcknowledged = v),
                          label: 'Vi su historial y asumo el riesgo de esta '
                              'colocación.',
                        ),
                      ],
                      SizedBox(height: ds.h(20)),
                    ],
                  ),
                ),
              ),
              if (report != null)
                Padding(
                  padding: EdgeInsets.fromLTRB(
                      ds.gutter, 0, ds.gutter, ds.bottomGap(28)),
                  child: Column(
                    children: [
                      DsButton(
                        label: 'Aprobar y armar su crédito',
                        isLoading: provider.isSubmitting,
                        onPressed: _riskAcknowledged && !provider.isSubmitting
                            ? () => _decide(approve: true)
                            : null,
                      ),
                      SizedBox(height: ds.h(12)),
                      // No colocar es una salida legítima, no un error: va sin
                      // fondo, pero en rojo, porque cierra la colocación.
                      TextButton(
                        onPressed: provider.isSubmitting
                            ? null
                            : () => _decide(approve: false),
                        child: Text('No colocar por ahora',
                            style: AppTextStyles.body(
                              fontSize: ds.sp(13),
                              weight: FontWeight.w500,
                              color: AppColors.error,
                            ).copyWith(height: 1.0)),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Bloque azul con la regla que gobierna toda la pantalla — L1255–L1263.
class _NoDecisionNotice extends StatelessWidget {
  const _NoDecisionNotice();

  @override
  Widget build(BuildContext context) {
    final ds = context.ds;
    return Container(
      padding: EdgeInsets.all(ds.w(18)),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(ds.r(AppRadii.cardSmall + 2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: ds.w(38),
            height: ds.w(38),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.onPrimary.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(ds.r(11)),
            ),
            child: Icon(Icons.gpp_maybe_outlined,
                size: ds.sp(19), color: AppColors.onPrimaryAccent),
          ),
          SizedBox(width: ds.w(13)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Kredius no aprueba ni rechaza: tú decides',
                    style: AppTextStyles.cardTitle(
                      fontSize: ds.sp(15),
                      color: AppColors.onPrimary,
                    ).copyWith(height: 1.25)),
                SizedBox(height: ds.h(6)),
                Text(
                  'No te limitamos la colocación por su historial. Si ella deja '
                  'de pagar, el saldo de tu línea sigue siendo tuyo y tu '
                  'comisión de esos pagos se va a cero.',
                  style: AppTextStyles.body(
                    fontSize: ds.sp(12),
                    color: AppColors.onPrimary.withValues(alpha: 0.72),
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

/// La colocación existe pero el beneficiario todavía no termina. No se enseña
/// un reporte vacío: se dice en qué va y se ofrece esperar.
class _Waiting extends StatelessWidget {
  const _Waiting({required this.loading, required this.name});

  final bool loading;
  final String name;

  @override
  Widget build(BuildContext context) {
    return DsEmptyStateCard(
      icon: loading ? Icons.hourglass_top_rounded : Icons.phonelink_ring_outlined,
      title: loading ? 'Cargando su historial' : 'Todavía no termina',
      message: loading
          ? 'Un momento.'
          : '$name sigue en su verificación. En cuanto acabe consultamos su '
              'buró y te avisamos para que decidas.',
    );
  }
}
