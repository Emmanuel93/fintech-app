import 'dart:math';

import '../entities/credit_application.dart';

/// Estimación de pago por periodo bajo amortización francesa (cuotas iguales).
/// Usa la tasa base del producto — no refleja tasas escalonadas por monto/riesgo
/// (rate cards), que solo se resuelven server-side al enviar la solicitud.
class AmortizationEstimate {
  const AmortizationEstimate({
    required this.periodicPayment,
    required this.numPeriods,
    required this.totalRepayment,
    required this.periodLabel,
  });

  final double periodicPayment;
  final int numPeriods;
  final double totalRepayment;

  /// 'semana' | 'quincena' | 'mes'
  final String periodLabel;

  static const _adjectiveByPeriod = {
    'semana': 'semanal',
    'quincena': 'quincenal',
    'mes': 'mensual',
  };

  /// Forma adjetiva de [periodLabel] — 'semanal' | 'quincenal' | 'mensual'.
  String get periodAdjective => _adjectiveByPeriod[periodLabel] ?? periodLabel;

  /// Plural de [periodLabel] — 'semanas' | 'quincenas' | 'meses'.
  String get periodPlural => periodLabel == 'mes' ? 'meses' : '${periodLabel}s';
}

/// Un pago del calendario: cuándo, cuánto, y cómo se reparte.
class AmortizationRow {
  const AmortizationRow({
    required this.number,
    required this.dueDate,
    required this.payment,
    required this.interest,
    required this.principal,
    required this.balance,
  });

  final int number;
  final DateTime dueDate;
  final double payment, interest, principal, balance;
}

abstract final class AmortizationCalculator {
  static const _periodsPerYear = {
    'WEEKLY': 52,
    'BIWEEKLY': 24,
    'MONTHLY': 12,
  };

  static const _periodLabels = {
    'WEEKLY': 'semana',
    'BIWEEKLY': 'quincena',
    'MONTHLY': 'mes',
  };

  /// Devuelve `null` si los datos de entrada no permiten un cálculo válido
  /// (monto/plazo no positivos, o frecuencia desconocida) — el caller debe
  /// simplemente no mostrar nada en ese caso, nunca un NaN en pantalla.
  static AmortizationEstimate? estimate({
    required double amount,
    required int termInMonths,
    required double nominalRateAnnual,
    required String paymentFrequency,
  }) {
    if (amount <= 0 || termInMonths <= 0) return null;
    final periodsPerYear = _periodsPerYear[paymentFrequency.toUpperCase()];
    if (periodsPerYear == null) return null;

    final numPeriods = (termInMonths * periodsPerYear / 12).round();
    if (numPeriods <= 0) return null;

    final periodRate = nominalRateAnnual / periodsPerYear;
    final double payment;
    if (periodRate == 0) {
      payment = amount / numPeriods;
    } else {
      payment = amount * periodRate / (1 - pow(1 + periodRate, -numPeriods));
    }

    return AmortizationEstimate(
      periodicPayment: payment,
      numPeriods: numPeriods,
      totalRepayment: payment * numPeriods,
      periodLabel: _periodLabels[paymentFrequency.toUpperCase()] ?? 'periodo',
    );
  }

  /// Atajo para `OfferScreen`/`ContractSignScreen`: ambas necesitan el mismo
  /// estimado a partir de una `CreditApplication` ya con oferta presentada.
  static AmortizationEstimate? estimateForApplication(
    CreditApplication app, {
    String? paymentFrequency,
  }) {
    final amount = app.offerAmountOrLine;
    final term = app.offeredTerm;
    final rate = app.nominalRate;
    if (amount == null || term == null || rate == null) return null;
    return estimate(
      amount: amount,
      termInMonths: term,
      nominalRateAnnual: rate,
      paymentFrequency: paymentFrequency ?? 'MONTHLY',
    );
  }

  /// Cuándo vence el pago número [n] (1-based) contado desde [from].
  ///
  /// Los meses se avanzan por calendario y no en bloques de 30 días: quien
  /// firma el 31 de enero espera pagar el 28 de febrero, no el 2 de marzo.
  /// `DateTime(2026, 2, 31)` normaliza a marzo, así que se acota al último día
  /// del mes destino.
  static DateTime dueDate({
    required int n,
    required String paymentFrequency,
    DateTime? from,
  }) {
    final start = from ?? DateTime.now();
    switch (paymentFrequency.toUpperCase()) {
      case 'WEEKLY':
        return start.add(Duration(days: 7 * n));
      case 'BIWEEKLY':
        return start.add(Duration(days: 15 * n));
      default:
        final month = start.month + n;
        final year = start.year + (month - 1) ~/ 12;
        final normalized = (month - 1) % 12 + 1;
        final lastDay = DateTime(year, normalized + 1, 0).day;
        return DateTime(year, normalized, min(start.day, lastDay));
    }
  }

  /// El calendario completo, cuota por cuota.
  ///
  /// Es lo que el contrato llama "tabla de amortización" y lo que hasta ahora
  /// se aceptaba sin poder verse. La última cuota absorbe el redondeo para que
  /// el saldo cierre exactamente en cero.
  static List<AmortizationRow> schedule({
    required double amount,
    required int termInMonths,
    required double nominalRateAnnual,
    required String paymentFrequency,
    DateTime? from,
  }) {
    final est = estimate(
      amount: amount,
      termInMonths: termInMonths,
      nominalRateAnnual: nominalRateAnnual,
      paymentFrequency: paymentFrequency,
    );
    if (est == null) return const [];

    final periodsPerYear = _periodsPerYear[paymentFrequency.toUpperCase()]!;
    final periodRate = nominalRateAnnual / periodsPerYear;

    var balance = amount;
    final rows = <AmortizationRow>[];
    for (var n = 1; n <= est.numPeriods; n++) {
      final interest = balance * periodRate;
      final isLast = n == est.numPeriods;
      // La última cuota liquida el saldo: arrastrar centavos dejaría un
      // adeudo de $0.03 que nadie sabe cómo pagar.
      final payment = isLast ? balance + interest : est.periodicPayment;
      final principal = payment - interest;
      balance = isLast ? 0 : balance - principal;
      rows.add(AmortizationRow(
        number: n,
        dueDate: dueDate(n: n, paymentFrequency: paymentFrequency, from: from),
        payment: payment,
        interest: interest,
        principal: principal,
        balance: balance,
      ));
    }
    return rows;
  }
}
