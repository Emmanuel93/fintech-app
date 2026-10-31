import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:fa_design_system/fa_design_system.dart';

import '../../domain/services/amortization_calculator.dart';
import '../providers/credit_application_provider.dart';

/// Pantalla 7 del prototipo — "Arma tu préstamo" (Journey L401–L463,
/// cálculo en L907–L913).
///
/// El pago se recalcula en **cada** `onChanged` del slider, no al soltarlo, y
/// nunca se muestra la tasa ni el CAT: sólo pago, total e intereses
/// (regla del handoff, `IMPLEMENTACION_UI.md` §4).
class ApplicationAmountScreen extends StatefulWidget {
  const ApplicationAmountScreen({super.key});

  @override
  State<ApplicationAmountScreen> createState() =>
      _ApplicationAmountScreenState();
}

class _ApplicationAmountScreenState extends State<ApplicationAmountScreen> {
  // Se inicializan en build() a partir de los límites del producto — un
  // slider/stepper acotado nunca puede salir de rango, así que no hace falta
  // Form/validators como en la versión anterior con campos de texto libres.
  double? _amount;
  int? _term;

  /// Crea la solicitud y va directo a la resolución.
  ///
  /// Ya no pasa por el consentimiento de buró: la autorización de consulta se
  /// firmó al abrir el alta y la consulta se hizo en ese análisis. Volver a
  /// pedirla aquí sería pedir permiso dos veces para lo mismo y dejar una
  /// segunda huella en el historial del cliente.
  Future<void> _continue({required bool requiresAmount}) async {
    final provider = context.read<CreditApplicationProvider>();
    provider.stageAmount(
      amount: requiresAmount ? _amount : null,
      term: requiresAmount ? _term : null,
    );
    final ok = await provider.submitPending();
    if (!mounted) return;
    if (ok) {
      context.go('/credit/apply/status');
    } else if (provider.identityHold != null) {
      context.go('/credit/apply/identity');
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(provider.error ?? 'No se pudo enviar.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final ds = context.ds;
    final provider = context.watch<CreditApplicationProvider>();
    final product = provider.selectedProduct;

    if (product == null) {
      // Estado inválido: regresa a la selección.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) context.go('/credit/apply');
      });
      return const SizedBox.shrink();
    }

    final requiresAmount = product.requiresAmount;
    // `selectedProduct` ya viene con los topes de la preoferta encima cuando se
    // eligió desde oportunidades (`selectPrequalifiedProduct`), así que el
    // slider se mueve dentro de lo que el scoring autorizó, no del catálogo.
    final minAmount = product.minAmount ?? 0;
    final maxAmount = product.maxAmount ?? (minAmount + 1);
    final minTerm = product.minTerm ?? 1;
    final maxTerm = product.maxTerm ?? minTerm;

    // Arranca en el máximo autorizado por el scoring, que es lo que el usuario
    // espera de una "línea autorizada".
    _amount ??= maxAmount.clamp(minAmount, maxAmount);
    _term ??= (product.defaultTerm ?? minTerm).clamp(minTerm, maxTerm);

    final fmt =
        NumberFormat.currency(locale: 'es_MX', symbol: '\$', decimalDigits: 0);
    final estimate = (requiresAmount && product.nominalRate != null)
        ? AmortizationCalculator.estimate(
            amount: _amount!,
            termInMonths: _term!,
            nominalRateAnnual: product.nominalRate!,
            paymentFrequency: product.defaultPaymentFrequency ?? 'MONTHLY',
          )
        : null;

    final frecuencia = product.defaultPaymentFrequency ?? 'MONTHLY';
    final primerPago =
        AmortizationCalculator.dueDate(n: 1, paymentFrequency: frecuencia);
    final ultimoPago = AmortizationCalculator.dueDate(
        n: estimate?.numPeriods ?? 1, paymentFrequency: frecuencia);

    return Scaffold(
      backgroundColor: AppColors.surfaceVariant,
      body: SafeArea(
        child: DsResponsiveBody(
          child: Column(
            children: [
              Padding(
                padding: EdgeInsets.fromLTRB(
                    ds.gutterWide, ds.topGap, ds.gutterWide, 0),
                child: Row(
                  children: [
                    _BackButton(onTap: () => context.go('/credit/apply')),
                    SizedBox(width: ds.w(14)),
                    Expanded(
                      child: Text(
                        requiresAmount ? 'Arma tu préstamo' : product.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.cardTitle(fontSize: ds.sp(15))
                            .copyWith(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: EdgeInsets.fromLTRB(
                      ds.gutterWide, ds.h(18), ds.gutterWide, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (!requiresAmount) ...[
                        Text('Confirma tu solicitud',
                            style:
                                AppTextStyles.screenTitle(fontSize: ds.sp(27))),
                        SizedBox(height: ds.h(6)),
                        Text(
                          'Es una línea revolvente: el límite se asigna según tu '
                          'evaluación y el monto lo defines al disponer.',
                          style: AppTextStyles.body(fontSize: ds.sp(14)),
                        ),
                        SizedBox(height: ds.h(20)),
                      ],
                      if (requiresAmount) ...[
                        DsAmountSlider(
                          amount: _amount!,
                          min: minAmount,
                          max: maxAmount,
                          step: product.amountStep,
                          onChanged: (v) => setState(() => _amount = v),
                        ),
                        SizedBox(height: ds.h(11)),
                        DsTermStepper(
                          term: _term!,
                          min: minTerm,
                          max: maxTerm,
                          onChanged: (v) => setState(() => _term = v),
                        ),
                        SizedBox(height: ds.h(11)),
                        if (estimate != null) ...[
                          DsPaymentSummaryCard(
                            headlineLabel: 'Pagas cada ${estimate.periodLabel}',
                            headlineValue: fmt.format(estimate.periodicPayment),
                            // Un pago suelto no dice nada sin saber cuántos son
                            // ni cuándo empieza: el compromiso es el calendario.
                            subLabel: '${estimate.numPeriods} pagos '
                                '${estimate.periodAdjective}es · '
                                'el primero el ${_fechaLarga(primerPago)}',
                            rows: [
                              ('Total a pagar',
                                  fmt.format(estimate.totalRepayment)),
                              ('Último pago', _fechaLarga(ultimoPago)),
                            ],
                            interestRow: (
                              'Intereses incluidos',
                              fmt.format(estimate.totalRepayment - _amount!),
                            ),
                            footnote:
                                'Estimado con las condiciones que tienes aprobadas. '
                                'Puedes adelantar pagos sin penalización.',
                          ),
                          SizedBox(height: ds.h(10)),
                          DsDocumentLink(
                            label: 'Ver tabla de amortización',
                            caption:
                                'Fecha, monto e intereses de cada uno de los '
                                '${estimate.numPeriods} pagos',
                            onTap: () {
                              context
                                  .read<CreditApplicationProvider>()
                                  .stageAmount(amount: _amount, term: _term);
                              context.push('/credit/apply/schedule');
                            },
                          ),
                        ],
                      ],
                      SizedBox(height: ds.h(22)),
                      DsButton(
                        label: 'Revisar solicitud',
                        isLoading: provider.isSubmitting,
                        onPressed: () =>
                            _continue(requiresAmount: requiresAmount),
                      ),
                      SizedBox(height: ds.bottomGap(28)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// "9 de septiembre de 2026" — la fecha completa, no un "en 30 días" que
/// obliga a hacer la cuenta.
String _fechaLarga(DateTime d) =>
    DateFormat("d 'de' MMMM 'de' y", 'es_MX').format(d);

/// Botón de retroceso del prototipo — 38×38, blanco, radio 12 (Journey L926).
class _BackButton extends StatelessWidget {
  const _BackButton({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ds = context.ds;
    return Semantics(
      button: true,
      label: 'Volver',
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Container(
          width: ds.w(38),
          height: ds.w(38),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(ds.r(12)),
            border: Border.all(color: AppColors.outlineVariant),
          ),
          child: Icon(Icons.arrow_back_rounded,
              size: ds.sp(18), color: AppColors.onSurface),
        ),
      ),
    );
  }
}
