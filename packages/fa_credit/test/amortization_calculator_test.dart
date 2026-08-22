import 'package:flutter_test/flutter_test.dart';
import 'package:fa_credit/src/domain/services/amortization_calculator.dart';

void main() {
  group('AmortizationCalculator.estimate', () {
    test('amortización francesa estándar (\$12,000 a 12 meses, 24% anual, mensual)', () {
      final result = AmortizationCalculator.estimate(
        amount: 12000,
        termInMonths: 12,
        nominalRateAnnual: 0.24,
        paymentFrequency: 'MONTHLY',
      );

      expect(result, isNotNull);
      expect(result!.numPeriods, 12);
      expect(result.periodicPayment, closeTo(1134.72, 0.01));
      expect(result.totalRepayment, closeTo(13616.58, 0.01));
      expect(result.periodLabel, 'mes');
    });

    test('quincenal: numPeriods y periodLabel correctos', () {
      final result = AmortizationCalculator.estimate(
        amount: 5000,
        termInMonths: 3,
        nominalRateAnnual: 0.22,
        paymentFrequency: 'BIWEEKLY',
      );

      expect(result, isNotNull);
      expect(result!.numPeriods, 6); // 3 meses * 24 quincenas/año / 12
      expect(result.periodLabel, 'quincena');
      expect(result.periodicPayment, greaterThan(0));
    });

    test('tasa 0 — evita división entre cero, reparte el monto entre los periodos', () {
      final result = AmortizationCalculator.estimate(
        amount: 1200,
        termInMonths: 12,
        nominalRateAnnual: 0,
        paymentFrequency: 'MONTHLY',
      );

      expect(result, isNotNull);
      expect(result!.periodicPayment, closeTo(100, 0.001));
      expect(result.totalRepayment, closeTo(1200, 0.001));
    });

    test('entradas inválidas devuelven null, nunca NaN', () {
      expect(
        AmortizationCalculator.estimate(
          amount: 0,
          termInMonths: 12,
          nominalRateAnnual: 0.3,
          paymentFrequency: 'MONTHLY',
        ),
        isNull,
      );
      expect(
        AmortizationCalculator.estimate(
          amount: 5000,
          termInMonths: 0,
          nominalRateAnnual: 0.3,
          paymentFrequency: 'MONTHLY',
        ),
        isNull,
      );
      expect(
        AmortizationCalculator.estimate(
          amount: 5000,
          termInMonths: 12,
          nominalRateAnnual: 0.3,
          paymentFrequency: 'UNKNOWN',
        ),
        isNull,
      );
    });
  });
}
