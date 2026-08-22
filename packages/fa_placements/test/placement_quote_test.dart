import 'package:fa_placements/fa_placements.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('PlacementQuote', () {
    test('el pago quincenal sale de la anualidad francesa del prototipo', () {
      // Journey App L1655–L1657: $45,000 a 24 quincenas con i = 0.289/24 da
      // $2,170.16 quincenales.
      const quote = PlacementQuote(amount: 45000, termFortnights: 24);
      expect(quote.fortnightlyPayment, closeTo(2170.16, 0.5));
    });

    test('a más plazo, menos pago quincenal pero más intereses', () {
      const corto = PlacementQuote(amount: 45000, termFortnights: 12);
      const largo = PlacementQuote(amount: 45000, termFortnights: 48);

      expect(largo.fortnightlyPayment, lessThan(corto.fortnightlyPayment));
      expect(largo.interest, greaterThan(corto.interest));
    });

    test('el total cobrado siempre supera al prestado', () {
      for (final term in PlacementPricing.terms) {
        final q = PlacementQuote(amount: 20000, termFortnights: term);
        expect(q.totalToCollect, greaterThan(q.amount),
            reason: 'plazo de $term quincenas');
      }
    });

    test('plazo cero no revienta la división', () {
      const q = PlacementQuote(amount: 10000, termFortnights: 0);
      expect(q.fortnightlyPayment, 0);
      expect(q.totalToCollect, 0);
    });

    test('la bonificación total es el 20% de todo lo cobrado a tiempo', () {
      const q = PlacementQuote(amount: 45000, termFortnights: 24);
      expect(q.commissionIfAllOnTime, closeTo(q.totalToCollect * 0.20, 0.01));
      expect(q.commissionPerPayment,
          closeTo(q.fortnightlyPayment * 0.20, 0.01));
    });
  });

  group('CommissionPolicy', () {
    test('la escala de atraso es la del diseño: 20, 17, 14, 10, 6 y cero', () {
      expect(CommissionPolicy.rateForDaysLate(0), 0.20);
      expect(CommissionPolicy.rateForDaysLate(1), 0.17);
      expect(CommissionPolicy.rateForDaysLate(2), 0.14);
      expect(CommissionPolicy.rateForDaysLate(3), 0.10);
      expect(CommissionPolicy.rateForDaysLate(4), 0.06);
      expect(CommissionPolicy.rateForDaysLate(5), 0);
    });

    test('al quinto día se pierde toda la comisión, y no vuelve', () {
      expect(CommissionPolicy.rateForDaysLate(5), 0);
      expect(CommissionPolicy.rateForDaysLate(30), 0);
      expect(CommissionPolicy.onPayment(4200, daysLate: 9), 0);
    });

    test('adelantarse no paga más que pagar a tiempo', () {
      // Un `daysLate` negativo llegaría de un backend que mide contra la fecha
      // de corte; no debe abrir la puerta a una comisión mayor al 20 %.
      expect(CommissionPolicy.rateForDaysLate(-3), 0.20);
    });
  });
}
