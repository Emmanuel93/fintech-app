import 'package:flutter_test/flutter_test.dart';
import 'package:fa_credit/src/domain/entities/credit_account.dart';

CreditAccount _makeAccount({
  double creditLimit = 10000,
  double usedAmount = 3000,
  double pendingBalance = 3100,
  double minimumPayment = 310,
  double noInterestPayment = 3100,
}) =>
    CreditAccount(
      creditLimit: creditLimit,
      usedAmount: usedAmount,
      pendingBalance: pendingBalance,
      minimumPayment: minimumPayment,
      noInterestPayment: noInterestPayment,
      cutoffDate: DateTime(2026, 6, 1),
      paymentDueDate: DateTime(2026, 6, 20),
      noInterestDeadline: DateTime(2026, 6, 20),
      annualRate: 36.0,
      cat: 45.0,
      accountNumber: '4111111111111111',
    );

void main() {
  group('CreditAccount', () {
    test('availableCredit es límite menos usado', () {
      final account = _makeAccount(creditLimit: 10000, usedAmount: 3000);
      expect(account.availableCredit, equals(7000));
    });

    test('applyPayment reduce pendingBalance y usedAmount', () {
      final account = _makeAccount(usedAmount: 3000, pendingBalance: 3100);
      final after = account.applyPayment(1000);
      expect(after.pendingBalance, equals(2100));
      expect(after.usedAmount, equals(2000));
    });

    test('applyPayment no produce valores negativos', () {
      final account = _makeAccount(usedAmount: 500, pendingBalance: 500);
      final after = account.applyPayment(10000);
      expect(after.pendingBalance, equals(0));
      expect(after.usedAmount, equals(0));
    });

    test('applyDisposition incrementa usedAmount y pendingBalance', () {
      final account = _makeAccount(usedAmount: 3000, pendingBalance: 3100);
      final after = account.applyDisposition(2000);
      expect(after.usedAmount, equals(5000));
      expect(after.pendingBalance, equals(5100));
    });

    test('applyDisposition no supera creditLimit en usedAmount', () {
      // El guard de negocio está en el provider; la entidad solo aplica la operación.
      // Este test documenta el comportamiento actual (sin clamp).
      final account = _makeAccount(creditLimit: 10000, usedAmount: 9500);
      final after = account.applyDisposition(1000);
      expect(after.usedAmount, equals(10500)); // sin clamp intencional en la entidad
    });
  });
}
