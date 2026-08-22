import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:gap/gap.dart';
import 'package:provider/provider.dart';
import 'package:fa_design_system/fa_design_system.dart';
import '../providers/kyc_provider.dart';

class KycSuccessScreen extends StatefulWidget {
  const KycSuccessScreen({super.key});

  @override
  State<KycSuccessScreen> createState() => _KycSuccessScreenState();
}

class _KycSuccessScreenState extends State<KycSuccessScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scale;
  late final Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _scale = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.elasticOut),
    );
    _opacity = CurvedAnimation(parent: _controller, curve: Curves.easeIn);
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final h = MediaQuery.of(context).size.height;
    final w = MediaQuery.of(context).size.width;
    final folio = context.watch<KycProvider>().state.folioKyc;
    final phone = context.watch<KycProvider>().state.phone;
    final name = context.watch<KycProvider>().state.personalData.nombres;

    return Scaffold(
      backgroundColor: AppColors.surfaceVariant,
      body: Column(
        children: [
          // Héroe azul de éxito, fiel a las pantallas azules del prototipo.
          Container(
            width: double.infinity,
            decoration: const BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(28)),
            ),
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: EdgeInsets.fromLTRB(w * 0.064, h * 0.02, w * 0.064, h * 0.04),
                child: Column(
                  children: [
                    ScaleTransition(
                      scale: _scale,
                      child: Container(
                        width: h * 0.12,
                        height: h * 0.12,
                        decoration: const BoxDecoration(
                          color: AppColors.accentGreen,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.check_rounded,
                            color: AppColors.onPrimary, size: h * 0.07),
                      ),
                    ),
                    Gap(h * 0.025),
                    FadeTransition(
                      opacity: _opacity,
                      child: Column(
                        children: [
                          Text(
                            name.isNotEmpty ? '¡Listo, $name!' : '¡Expediente enviado!',
                            textAlign: TextAlign.center,
                            style: AppTextStyles.heroTitle(h * 0.032,
                                color: AppColors.onPrimary),
                          ),
                          Gap(h * 0.012),
                          Text(
                            'Tu solicitud KYC fue recibida y está en revisión. '
                            'Recibirás una notificación en 24-48 horas hábiles.',
                            textAlign: TextAlign.center,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: AppColors.onPrimary.withValues(alpha: 0.72),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(w * 0.064, h * 0.03, w * 0.064, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (folio.isNotEmpty)
                      Container(
                        padding: EdgeInsets.all(h * 0.025),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppColors.outlineVariant),
                        ),
                        child: Column(
                          children: [
                            Text(
                              'Folio de solicitud',
                              style: theme.textTheme.labelMedium?.copyWith(
                                color: AppColors.onSurfaceVariant,
                              ),
                            ),
                            Gap(h * 0.008),
                            Text(
                              folio,
                              style: theme.textTheme.titleLarge?.copyWith(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 1.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    Gap(h * 0.02),
                    Wrap(
                      alignment: WrapAlignment.center,
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _SummaryChip(Icons.phone_rounded, '+52 $phone'),
                        const _SummaryChip(Icons.badge_rounded, 'INE verificado'),
                        const _SummaryChip(Icons.home_rounded, 'Domicilio'),
                        const _SummaryChip(Icons.attach_money_rounded, 'Ingresos'),
                      ],
                    ),
                    Gap(h * 0.04),
                    Container(
                      padding: EdgeInsets.all(h * 0.02),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.outlineVariant),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('¿Qué sigue?', style: theme.textTheme.titleSmall),
                          Gap(h * 0.015),
                          _TimelineItem(
                            icon: Icons.search_rounded,
                            title: 'Validación de identidad',
                            subtitle: 'Cotejamos INE contra registros oficiales',
                            isLast: false,
                          ),
                          _TimelineItem(
                            icon: Icons.analytics_outlined,
                            title: 'Análisis crediticio (Scoring)',
                            subtitle: 'Consulta a Buró + modelo de riesgo',
                            isLast: false,
                          ),
                          _TimelineItem(
                            icon: Icons.notifications_active_outlined,
                            title: 'Resultado en tu celular',
                            subtitle: 'SMS + notificación push',
                            isLast: true,
                          ),
                        ],
                      ),
                    ),
                    Gap(h * 0.02),
                  ],
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(w * 0.064, 0, w * 0.064, h * 0.03),
              child: DsButton(
                label: 'Ir a inicio',
                onPressed: () => context.go('/home'),
              ),
            ),
          ],
        ),
    );
  }
}

class _SummaryChip extends StatelessWidget {
  const _SummaryChip(this.icon, this.label);
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.primaryContainer,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppColors.primary),
          const Gap(5),
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                ),
          ),
        ],
      ),
    );
  }
}

class _TimelineItem extends StatelessWidget {
  const _TimelineItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.isLast,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final h = MediaQuery.of(context).size.height;
    final circleSize = h * 0.04;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: circleSize,
              height: circleSize,
              decoration: const BoxDecoration(
                color: AppColors.primaryContainer,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: AppColors.primary, size: h * 0.02),
            ),
            if (!isLast)
              Container(width: 2, height: h * 0.025, color: AppColors.outlineVariant),
          ],
        ),
        const Gap(12),
        Expanded(
          child: Padding(
            padding: EdgeInsets.only(bottom: isLast ? 0 : h * 0.01),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: Theme.of(context).textTheme.labelLarge),
                Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
