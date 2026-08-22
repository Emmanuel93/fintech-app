/// Estar al corriente y estar en mora no se distinguen por el saldo: se
/// distinguen por el tiempo. Estos tests fijan quién decide eso y con qué.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:fa_credit/src/domain/entities/credit_account.dart';

CreditAccount _account({
  int? daysPastDue,
  String status = 'ACTIVE',
  DateTime? dueDate,
  double pendingBalance = 42000,
  int? paymentsMade = 3,
  int? assignedTerm = 12,
}) {
  final due = dueDate ?? DateTime.now().add(const Duration(days: 10));
  return CreditAccount(
    creditLimit: 50000,
    usedAmount: 50000,
    pendingBalance: pendingBalance,
    minimumPayment: 4800,
    noInterestPayment: pendingBalance,
    cutoffDate: due.subtract(const Duration(days: 5)),
    paymentDueDate: due,
    noInterestDeadline: due,
    annualRate: 0.42,
    cat: 58,
    accountNumber: '**** 4821',
    productType: 'PERSONAL_LOAN',
    behavior: 'INSTALLMENT',
    status: status,
    assignedTerm: assignedTerm,
    paymentsMade: paymentsMade,
    principalPaid: 8000,
    daysPastDue: daysPastDue,
  );
}

void main() {
  group('quién decide la mora', () {
    test('manda cartera, no el reloj del teléfono', () {
      // Vencimiento pasado pero cartera dice que no hay atraso: hay días de
      // gracia, festivos y pagos en tránsito que la app no conoce.
      final conGracia = _account(
        daysPastDue: 0,
        dueDate: DateTime.now().subtract(const Duration(days: 2)),
      );
      expect(conGracia.isOverdue, isFalse);

      // Y al revés: cartera reporta atraso aunque la fecha aún no llegue.
      final enMora = _account(
        daysPastDue: 3,
        dueDate: DateTime.now().add(const Duration(days: 1)),
      );
      expect(enMora.isOverdue, isTrue);
    });

    test('sin daysPastDue se cae al estado, y luego a la fecha', () {
      expect(_account(status: 'PAST_DUE').isOverdue, isTrue);
      expect(
        _account(dueDate: DateTime.now().subtract(const Duration(days: 1)))
            .isOverdue,
        isTrue,
        reason: 'sin nada del backend, la fecha es la única aproximación',
      );
      expect(_account().isOverdue, isFalse);
    });

    test('un crédito liquidado nunca está en mora', () {
      // Aunque el vencimiento quedó atrás: ya no se debe nada.
      final liquidado = _account(
        status: 'PAID_OFF',
        pendingBalance: 0,
        daysPastDue: 9,
        dueDate: DateTime.now().subtract(const Duration(days: 9)),
      );
      expect(liquidado.isPaidOff, isTrue);
      expect(liquidado.isOverdue, isFalse,
          reason: 'cobrarle mora a quien ya pagó todo es un error caro');
    });

    test('saldo en cero cuenta como liquidado aunque el estado no llegue', () {
      expect(_account(pendingBalance: 0).isPaidOff, isTrue);
      // Medio peso de redondeo no es un adeudo.
      expect(_account(pendingBalance: 0.4).isPaidOff, isTrue);
      expect(_account(pendingBalance: 12).isPaidOff, isFalse);
    });
  });

  group('cómo se comunica el atraso', () {
    test('se dice de cuántos días es, en singular y plural', () {
      expect(_account(daysPastDue: 1).overdueLabel, '1 día');
      expect(_account(daysPastDue: 17).overdueLabel, '17 días');
    });

    test('sin atraso no hay etiqueta que mostrar', () {
      expect(_account(daysPastDue: 0).overdueLabel, isNull);
      expect(_account().overdueLabel, isNull);
    });
  });

  group('el avance de pagos', () {
    test('sabe en qué pago va', () {
      final c = _account(paymentsMade: 3, assignedTerm: 12);
      expect(c.paymentsMade, 3);
      expect(c.assignedTerm, 12);
      expect(c.paymentProgress, closeTo(0.25, 1e-9));
    });

    test('sin datos del backend no inventa un cero', () {
      // Una barra en 0% dice "no has pagado nada", que es distinto de "no sé".
      expect(_account(paymentsMade: null).paymentProgress, isNull);
      expect(_account(assignedTerm: null).paymentProgress, isNull);
    });

    test('un pago avanza el contador y baja el saldo', () {
      final despues = _account(paymentsMade: 3).applyPayment(4800);
      expect(despues.paymentsMade, 4);
      expect(despues.pendingBalance, 42000 - 4800);
    });
  });
}
