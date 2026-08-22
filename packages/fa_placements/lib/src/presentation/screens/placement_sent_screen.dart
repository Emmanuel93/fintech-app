import 'package:fa_design_system/fa_design_system.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../providers/placement_provider.dart';

/// Paso 3 — la liga salió (Journey App L1342–L1384).
///
/// Lo que esta pantalla tiene que dejar claro son dos cosas que el distribuidor
/// no puede adivinar: que **su línea sigue intacta** hasta que él apruebe, y
/// que lo que sigue depende del beneficiario, no de él.
class PlacementSentScreen extends StatelessWidget {
  const PlacementSentScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final ds = context.ds;
    final provider = context.watch<PlacementProvider>();
    final placement = provider.current;
    final fmt =
        NumberFormat.currency(locale: 'es_MX', symbol: '\$', decimalDigits: 0);

    final resumen = placement == null
        ? ''
        : '${placement.beneficiaryName} · ${fmt.format(placement.amount)} · '
            '${placement.termFortnights} quincenas. Le mandamos la liga a su '
            'celular: en cuanto termine su verificación, la colocación aparece '
            'en tu lista.';

    return Scaffold(
      backgroundColor: AppColors.surfaceVariant,
      body: DsResponsiveBody(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _Header(title: 'Le mandamos la liga', subtitle: resumen),
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(
                    ds.gutter, ds.h(22), ds.gutter, ds.h(20)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Container(
                      padding: EdgeInsets.all(ds.w(18)),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius:
                            BorderRadius.circular(ds.r(AppRadii.cardSmall + 2)),
                        border: Border.all(color: AppColors.outlineVariant),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text('QUÉ SIGUE',
                              style: AppTextStyles.captionLabel(
                                  fontSize: ds.sp(10))),
                          SizedBox(height: ds.h(16)),
                          DsTimeline(steps: [
                            DsTimelineStep(
                              title: 'Liga enviada a su celular',
                              description: 'Al ${placement?.beneficiaryPhoneMask ?? 'su número'}. '
                                  'Vive 7 días; si no la completa, la colocación '
                                  'no se crea y tu línea nunca se toca.',
                              tone: DsStepTone.done,
                            ),
                            const DsTimelineStep(
                              title: 'Ella se verifica desde su teléfono',
                              description: 'Su código, su INE y su prueba de '
                                  'vida. Es todo o nada: si le falta algo, no '
                                  'avanza.',
                              tone: DsStepTone.pending,
                            ),
                            const DsTimelineStep(
                              title: 'Consultamos su buró',
                              description: 'Con la autorización que ella firma, '
                                  'no la tuya. Te pasamos el resultado para que '
                                  'decidas.',
                            ),
                            const DsTimelineStep(
                              title: 'Depósito a su cuenta',
                              description: 'Cuando apruebes, le llega el mismo '
                                  'día por SPEI.',
                            ),
                          ]),
                        ],
                      ),
                    ),
                    SizedBox(height: ds.h(14)),
                    DsNoticeBanner(
                      tone: DsNoticeTone.info,
                      text: 'Tu línea sigue completa en '
                          '${fmt.format(provider.available)}: solo se descuenta '
                          'cuando ella termine su verificación y tú apruebes. '
                          'Nada queda apartado mientras tanto.',
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(
                  ds.gutter, 0, ds.gutter, ds.bottomGap(30)),
              child: Column(
                children: [
                  DsButton(
                    label: 'Ver mis colocaciones',
                    onPressed: () => context.go('/home'),
                  ),
                  SizedBox(height: ds.h(11)),
                  DsButton(
                    label: 'Colocar a alguien más',
                    variant: DsButtonVariant.ghost,
                    onPressed: () => context.go('/placements/new'),
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

class _Header extends StatelessWidget {
  const _Header({required this.title, required this.subtitle});

  final String title, subtitle;

  @override
  Widget build(BuildContext context) {
    final ds = context.ds;
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(ds.r(28))),
      ),
      child: Stack(
        children: [
          Positioned(
            right: ds.w(-70),
            top: ds.h(-70),
            child: IgnorePointer(
              child: Container(
                width: ds.w(220),
                height: ds.w(220),
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
          SafeArea(
            bottom: false,
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                  ds.w(24), ds.topGapBand, ds.w(24), ds.h(30)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  KrRise(
                    child: Container(
                      width: ds.w(52),
                      height: ds.w(52),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: AppColors.onPrimary.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(ds.r(15)),
                      ),
                      child: Icon(Icons.check_rounded,
                          size: ds.sp(26), color: AppColors.onPrimaryAccent),
                    ),
                  ),
                  SizedBox(height: ds.h(14)),
                  Text(title,
                      style: AppTextStyles.heroTitle(ds.sp(27),
                              color: AppColors.onPrimary)
                          .copyWith(height: 1.15)),
                  if (subtitle.isNotEmpty) ...[
                    SizedBox(height: ds.h(14)),
                    Text(subtitle,
                        style: AppTextStyles.body(
                          fontSize: ds.sp(13.5),
                          color: AppColors.onPrimary.withValues(alpha: 0.7),
                        ).copyWith(height: 1.55)),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
