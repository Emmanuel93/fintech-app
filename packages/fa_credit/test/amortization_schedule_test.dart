/// El calendario de pagos es lo que el cliente firma como "tabla de
/// amortización". Si las fechas o el saldo final están mal, el documento que
/// acepta no describe su crédito.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:fa_credit/src/domain/services/amortization_calculator.dart';

void main() {
  group('dueDate', () {
    test('los meses avanzan por calendario, no en bloques de 30 días', () {
      final firma = DateTime(2026, 1, 15);
      expect(
        AmortizationCalculator.dueDate(
            n: 1, paymentFrequency: 'MONTHLY', from: firma),
        DateTime(2026, 2, 15),
      );
      expect(
        AmortizationCalculator.dueDate(
            n: 12, paymentFrequency: 'MONTHLY', from: firma),
        DateTime(2027, 1, 15),
      );
    });

    test('quien firma un 31 paga el último día del mes corto, no en marzo', () {
      // DateTime(2026, 2, 31) normaliza a marzo por su cuenta: sin acotar, el
      // cliente vería su primer pago un 3 de marzo.
      expect(
        AmortizationCalculator.dueDate(
            n: 1,
            paymentFrequency: 'MONTHLY',
            from: DateTime(2026, 1, 31)),
        DateTime(2026, 2, 28),
      );
    });

    test('semanal y quincenal cuentan días', () {
      final firma = DateTime(2026, 3, 10);
      expect(
        AmortizationCalculator.dueDate(
            n: 2, paymentFrequency: 'WEEKLY', from: firma),
        DateTime(2026, 3, 24),
      );
      expect(
        AmortizationCalculator.dueDate(
            n: 2, paymentFrequency: 'BIWEEKLY', from: firma),
        DateTime(2026, 4, 9),
      );
    });
  });

  group('schedule', () {
    List<AmortizationRow> build() => AmortizationCalculator.schedule(
          amount: 50000,
          termInMonths: 12,
          nominalRateAnnual: 0.34,
          paymentFrequency: 'MONTHLY',
          from: DateTime(2026, 1, 10),
        );

    test('hay una fila por pago y las fechas van en orden', () {
      final rows = build();
      expect(rows, hasLength(12));
      expect(rows.first.number, 1);
      expect(rows.first.dueDate, DateTime(2026, 2, 10));
      for (var i = 1; i < rows.length; i++) {
        expect(rows[i].dueDate.isAfter(rows[i - 1].dueDate), isTrue);
      }
    });

    test('el saldo cierra exactamente en cero', () {
      // Arrastrar centavos dejaría un adeudo de $0.03 que nadie sabe pagar.
      expect(build().last.balance, 0);
    });

    test('el capital amortizado suma el monto prestado', () {
      final capital = build().fold<double>(0, (a, r) => a + r.principal);
      expect(capital, closeTo(50000, 0.01));
    });

    test('con el tiempo se paga menos interés y más capital', () {
      final rows = build();
      expect(rows.last.interest, lessThan(rows.first.interest));
      expect(rows.last.principal, greaterThan(rows.first.principal));
    });

    test('sin datos válidos devuelve vacío en vez de filas con NaN', () {
      expect(
        AmortizationCalculator.schedule(
          amount: 0,
          termInMonths: 12,
          nominalRateAnnual: 0.34,
          paymentFrequency: 'MONTHLY',
        ),
        isEmpty,
      );
    });
  });
}
