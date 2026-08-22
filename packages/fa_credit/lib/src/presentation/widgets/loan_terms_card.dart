import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:fa_design_system/fa_design_system.dart';

import '../../domain/services/amortization_calculator.dart';

/// Tarjeta de condiciones del crédito (monto/línea, plazo, pago por periodo,
/// total a pagar) — compartida entre `OfferScreen` (al presentar la oferta) y
/// `ContractSignScreen` (resumen antes de firmar). A propósito no muestra la
/// tasa de interés ni el CAT: el usuario decide con lo que realmente pagará.
class LoanTermsCard extends StatelessWidget {
  const LoanTermsCard({
    super.key,
    required this.amountLabel,
    required this.amount,
    this.term,
    this.estimate,
  });

  final String amountLabel;
  final double amount;
  final int? term;

  /// `null` si los datos disponibles no permiten calcularlo — la fila de pago
  /// simplemente no se renderiza en ese caso.
  final AmortizationEstimate? estimate;

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat.currency(locale: 'es_MX', symbol: '\$');
    final e = estimate;
    return DsPaymentSummaryCard(
      headlineLabel: amountLabel,
      headlineValue: fmt.format(amount),
      subLabel: term != null ? 'Plazo: $term meses' : null,
      emphasizedRow: e != null ? ('Pago ${e.periodAdjective}', fmt.format(e.periodicPayment)) : null,
      rows: e != null ? [('Total a pagar', fmt.format(e.totalRepayment))] : const [],
      interestRow: e != null ? ('Intereses incluidos', fmt.format(e.totalRepayment - amount)) : null,
    );
  }
}
