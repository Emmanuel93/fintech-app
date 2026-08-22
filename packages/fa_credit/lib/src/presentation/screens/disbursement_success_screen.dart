import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:fa_design_system/fa_design_system.dart';

import '../../domain/services/amortization_calculator.dart';
import '../providers/credit_application_provider.dart';
import '../providers/credit_provider.dart';

/// Pantalla 10 del prototipo — "Listo, el dinero va en camino"
/// (Journey L545–L566, filas en L1257–L1261).
///
/// Héroe azul con el halo verde centrado y el check de 94px entrando con
/// `kr-rise`. La tarjeta de datos entra 90ms después: el prototipo no escalona
/// nada, pero el desfase hace que el ojo lea primero el "ya está" y luego el
/// detalle.
class DisbursementSuccessScreen extends StatefulWidget {
  const DisbursementSuccessScreen({super.key});

  @override
  State<DisbursementSuccessScreen> createState() =>
      _DisbursementSuccessScreenState();
}

class _DisbursementSuccessScreenState extends State<DisbursementSuccessScreen> {
  @override
  void initState() {
    super.initState();
    // La cuenta la crea cartera al consumir el evento de la firma, así que
    // llega un momento después. Se pide aquí, mientras el usuario lee el "ya
    // está", para que el home no lo reciba con "todavía no tienes créditos".
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<CreditProvider>().loadAfterDisbursement();
    });
  }

  @override
  Widget build(BuildContext context) {
    final ds = context.ds;
    final provider = context.watch<CreditApplicationProvider>();
    final app = provider.application;

    if (app == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted) context.go('/home');
      });
      return const SizedBox.shrink();
    }

    final fmt =
        NumberFormat.currency(locale: 'es_MX', symbol: '\$', decimalDigits: 0);
    final amount = app.offerAmountOrLine ?? 0;
    final estimate = AmortizationCalculator.estimateForApplication(
      app,
      paymentFrequency: provider.selectedProduct?.defaultPaymentFrequency,
    );
    final clabe = provider.stagedClabe;
    final last4 = (clabe != null && clabe.length >= 4)
        ? clabe.substring(clabe.length - 4)
        : null;

    final rows = <(String, String)>[
      if (estimate != null)
        ('Primer pago', _firstPaymentLabel()),
      if (estimate != null)
        ('Pago ${estimate.periodLabel}', fmt.format(estimate.periodicPayment)),
      if (estimate != null)
        ('Total a pagar', fmt.format(estimate.totalRepayment)),
    ];

    return DsHeroScaffold(
      blobs: DsHeroBlobs.centerTop,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(height: ds.h(40)),
          KrRise(
            child: Column(
              children: [
                Container(
                  width: ds.w(94),
                  height: ds.w(94),
                  alignment: Alignment.center,
                  decoration: const BoxDecoration(
                    color: AppColors.accentGreen,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.check_rounded,
                      size: ds.sp(46), color: AppColors.onPrimary),
                ),
                SizedBox(height: ds.h(22)),
                Text(
                  'Listo, el dinero va en camino',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.heroTitle(ds.sp(29),
                      color: AppColors.onPrimary),
                ),
                SizedBox(height: ds.h(10)),
                ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: ds.w(300)),
                  child: Text(
                    last4 != null
                        ? 'Depositamos ${fmt.format(amount)} a tu cuenta •••• $last4 hoy mismo.'
                        : 'Depositamos ${fmt.format(amount)} a tu cuenta hoy mismo.',
                    textAlign: TextAlign.center,
                    style: AppTextStyles.body(
                      fontSize: ds.sp(14.5),
                      color: AppColors.onPrimary.withValues(alpha: 0.65),
                    ).copyWith(height: 1.55),
                  ),
                ),
              ],
            ),
          ),
          if (rows.isNotEmpty) ...[
            SizedBox(height: ds.h(36)),
            KrRise(
              delay: const Duration(milliseconds: 90),
              child: Container(
                padding: EdgeInsets.symmetric(
                    horizontal: ds.w(20), vertical: ds.h(18)),
                decoration: BoxDecoration(
                  color: AppColors.onPrimary.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(ds.r(AppRadii.card)),
                  border: Border.all(
                      color: AppColors.onPrimary.withValues(alpha: 0.16)),
                ),
                child: Column(
                  children: [
                    for (var i = 0; i < rows.length; i++) ...[
                      if (i > 0) SizedBox(height: ds.h(13)),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Expanded(
                            child: Text(rows[i].$1,
                                style: AppTextStyles.body(
                                  fontSize: ds.sp(13),
                                  weight: FontWeight.w500,
                                  color: AppColors.onPrimary
                                      .withValues(alpha: 0.6),
                                ).copyWith(height: 1.0)),
                          ),
                          SizedBox(width: ds.w(10)),
                          Text(rows[i].$2,
                              style: AppTextStyles.cardTitle(
                                      fontSize: ds.sp(14),
                                      color: AppColors.onPrimary)
                                  .copyWith(height: 1.0)),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
          const Spacer(),
          SizedBox(height: ds.h(24)),
          DsWhiteCta(
            label: 'Ir a mi crédito',
            onTap: () {
              // El provider se resetea al entrar al catálogo (ProductSelection
              // lo hace en su initState), así que aquí sólo navegamos.
              context.go('/home');
            },
          ),
        ],
      ),
    );
  }

  /// Primer pago: el día 5 del mes siguiente, como asume el prototipo
  /// (Journey L458 — "Tu primer pago sería el 5 de septiembre").
  static String _firstPaymentLabel() {
    final now = DateTime.now();
    final next = DateTime(now.year, now.month + 1, 5);
    return DateFormat("d 'de' MMMM", 'es_MX').format(next);
  }
}
