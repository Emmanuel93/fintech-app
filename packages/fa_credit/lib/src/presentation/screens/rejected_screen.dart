import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:fa_design_system/fa_design_system.dart';

import '../providers/credit_application_provider.dart';

/// Rechazo — pantalla nueva del prototipo (Journey L960–L1013,
/// datos en L1421–L1430).
///
/// El diseño trata el "no" como información, no como una puerta cerrada:
/// header azul con el porqué en tono humano, las razones concretas, las tres
/// palancas que sí están en manos del usuario, y cuándo puede volver.
///
/// Las razones vienen del backend cuando las manda (`rejectionReason`); las
/// palancas son las mismas del prototipo porque no dependen del caso.
class RejectedScreen extends StatelessWidget {
  const RejectedScreen({super.key});

  /// Journey L1426–L1430.
  static const _tips = [
    'Ponte al corriente en el crédito atrasado. Es lo que más mueve la aguja.',
    'Baja tu deuda actual: cada pago que liquides libera capacidad.',
    'No pidas crédito en otro lado por unos meses. Deja que se enfríen las consultas.',
  ];

  /// Política: se puede volver a solicitar a los 90 días.
  static const int _retryDays = 90;

  @override
  Widget build(BuildContext context) {
    final ds = context.ds;
    final provider = context.watch<CreditApplicationProvider>();
    final app = provider.application;
    final reason = app?.rejectionReason;
    final retryDate = DateTime.now().add(const Duration(days: _retryDays));

    return Scaffold(
      backgroundColor: AppColors.surfaceVariant,
      body: DsResponsiveBody(
        child: CustomScrollView(
          slivers: [
            // Header azul — Journey L963–L969.
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
                    Container(
                      width: ds.w(52),
                      height: ds.w(52),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: AppColors.onPrimary.withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(ds.r(15)),
                      ),
                      child: Icon(Icons.info_outline_rounded,
                          size: ds.sp(26), color: AppColors.onPrimary),
                    ),
                    SizedBox(height: ds.h(14)),
                    Text('Hoy no pudimos aprobarte',
                        style: AppTextStyles.heroTitle(ds.sp(28),
                            color: AppColors.onPrimary)),
                    SizedBox(height: ds.h(14)),
                    Text(
                      'No es un no para siempre. Tu historial cambia mes con mes, '
                      'y en cuanto se mueva volvemos a revisarlo sin que tengas '
                      'que hacer nada.',
                      style: AppTextStyles.body(
                        fontSize: ds.sp(13.5),
                        color: AppColors.onPrimary.withValues(alpha: 0.68),
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
                  // POR QUÉ — Journey L972–L983.
                  Container(
                    padding: EdgeInsets.all(ds.w(18)),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(ds.r(18)),
                      border: Border.all(color: AppColors.outlineVariant),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text('POR QUÉ',
                            style: AppTextStyles.captionLabel(
                                fontSize: ds.sp(10))),
                        SizedBox(height: ds.h(14)),
                        // El BFF manda una razón en texto libre; cuando no la
                        // manda, se explica la política sin fingir un detalle
                        // que no tenemos.
                        _Reason(
                          title: reason ?? 'No alcanzaste el puntaje mínimo',
                          desc: reason != null
                              ? 'Es lo que más pesa en la decisión de hoy.'
                              : 'La evaluación combina tu historial de pago, tu '
                                  'deuda actual y las consultas recientes.',
                        ),
                      ],
                    ),
                  ),

                  // QUÉ TE ACERCA A UN SÍ — Journey L985–L996.
                  SizedBox(height: ds.h(14)),
                  Container(
                    padding: EdgeInsets.all(ds.w(18)),
                    decoration: BoxDecoration(
                      color: AppColors.primaryContainer,
                      borderRadius: BorderRadius.circular(ds.r(18)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text('Qué te acerca a un sí',
                            style: AppTextStyles.cardTitle(
                              fontSize: ds.sp(15),
                              color: AppColors.onPrimaryContainer,
                            ).copyWith(height: 1.25)),
                        SizedBox(height: ds.h(6)),
                        Text(
                          'Tres cosas que sí están en tus manos, en orden de peso.',
                          style: AppTextStyles.body(
                            fontSize: ds.sp(12.5),
                            color: AppColors.primary,
                          ).copyWith(height: 1.45),
                        ),
                        SizedBox(height: ds.h(13)),
                        for (var i = 0; i < _tips.length; i++) ...[
                          if (i > 0) SizedBox(height: ds.h(11)),
                          _Tip(number: i + 1, text: _tips[i]),
                        ],
                      ],
                    ),
                  ),

                  // CUÁNDO — Journey L998–L1006.
                  SizedBox(height: ds.h(14)),
                  Container(
                    padding: EdgeInsets.symmetric(
                        horizontal: ds.w(18), vertical: ds.h(16)),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(ds.r(18)),
                      border: Border.all(color: AppColors.outlineVariant),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: ds.w(38),
                          height: ds.w(38),
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: AppColors.tertiaryContainer,
                            borderRadius: BorderRadius.circular(ds.r(11)),
                          ),
                          child: Icon(Icons.schedule_rounded,
                              size: ds.sp(18),
                              color: AppColors.onTertiaryContainer),
                        ),
                        SizedBox(width: ds.w(13)),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                  'Te avisamos el '
                                  '${DateFormat("d 'de' MMMM", 'es_MX').format(retryDate)}',
                                  style: AppTextStyles.body(
                                    fontSize: ds.sp(13.5),
                                    weight: FontWeight.w600,
                                    color: AppColors.onSurface,
                                  ).copyWith(height: 1.25)),
                              SizedBox(height: ds.h(5)),
                              Text(
                                  'Puedes volver a solicitar en $_retryDays días.',
                                  style: AppTextStyles.body(
                                    fontSize: ds.sp(11.5),
                                    color: AppColors.disabled,
                                  ).copyWith(height: 1.4)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: ds.h(24)),
                  DsButton(
                    label: 'Entendido, ir a mi inicio',
                    onPressed: () => context.go('/home'),
                  ),
                  SizedBox(height: ds.h(11)),
                  Center(
                    child: GestureDetector(
                      onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text(
                                'Te contactamos por el chat de soporte muy pronto.')),
                      ),
                      behavior: HitTestBehavior.opaque,
                      child: Padding(
                        padding: EdgeInsets.symmetric(vertical: ds.h(6)),
                        child: Text('Hablar con alguien de Kredius',
                            style: AppTextStyles.body(
                              fontSize: ds.sp(13),
                              weight: FontWeight.w500,
                              color: AppColors.primary,
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

/// Razón con punto rojo — Journey L975–L981.
class _Reason extends StatelessWidget {
  const _Reason({required this.title, required this.desc});
  final String title, desc;

  @override
  Widget build(BuildContext context) {
    final ds = context.ds;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: ds.w(8),
          height: ds.w(8),
          margin: EdgeInsets.only(top: ds.h(6)),
          decoration: const BoxDecoration(
              color: AppColors.error, shape: BoxShape.circle),
        ),
        SizedBox(width: ds.w(12)),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: AppTextStyles.body(
                    fontSize: ds.sp(13.5),
                    weight: FontWeight.w600,
                    color: AppColors.onSurface,
                  ).copyWith(height: 1.3)),
              SizedBox(height: ds.h(5)),
              Text(desc,
                  style: AppTextStyles.body(fontSize: ds.sp(12))
                      .copyWith(height: 1.45)),
            ],
          ),
        ),
      ],
    );
  }
}

/// Palanca numerada — Journey L991–L994.
class _Tip extends StatelessWidget {
  const _Tip({required this.number, required this.text});
  final int number;
  final String text;

  @override
  Widget build(BuildContext context) {
    final ds = context.ds;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: ds.w(20),
          height: ds.w(20),
          alignment: Alignment.center,
          decoration: const BoxDecoration(
              color: AppColors.primary, shape: BoxShape.circle),
          child: Text('$number',
              style: AppTextStyles.chipLabel(
                      fontSize: ds.sp(10), color: AppColors.onPrimary)
                  .copyWith(height: 1.0, letterSpacing: 0)),
        ),
        SizedBox(width: ds.w(11)),
        Expanded(
          child: Text(text,
              style: AppTextStyles.body(
                fontSize: ds.sp(12.5),
                weight: FontWeight.w500,
                color: AppColors.onPrimaryContainer,
              ).copyWith(height: 1.45)),
        ),
      ],
    );
  }
}
