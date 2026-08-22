import '../../domain/entities/credit_account.dart';

class CreditAccountDto {
  const CreditAccountDto({
    required this.creditLimit,
    required this.usedAmount,
    required this.pendingBalance,
    required this.minimumPayment,
    required this.noInterestPayment,
    required this.cutoffDate,
    required this.paymentDueDate,
    required this.noInterestDeadline,
    required this.annualRate,
    required this.cat,
    required this.accountNumber,
    required this.productType,
    required this.behavior,
    required this.status,
    this.assignedTerm,
    this.paymentsMade,
    this.principalPaid,
    this.daysPastDue,
    this.overdueAmount,
  });

  final double creditLimit, usedAmount, pendingBalance;
  final double minimumPayment, noInterestPayment;
  final String cutoffDate, paymentDueDate, noInterestDeadline;
  final double annualRate, cat;
  final String accountNumber;
  final String productType, behavior, status;
  final int? assignedTerm;
  final int? paymentsMade;
  final double? principalPaid;
  final int? daysPastDue;
  final double? overdueAmount;

  // Tolerante al shape del BFF (credit-portfolio): algunos campos como
  // usedAmount/pendingBalance/annualRate llegan con otro nombre; los demás
  // (minimumPayment, cat, fechas) pueden no venir hasta que haya statement.
  // Para créditos a plazo (INSTALLMENT) creditLimit puede venir null → 0.
  factory CreditAccountDto.fromJson(Map<String, dynamic> j) {
    double num_(String k, [String? alt]) =>
        ((j[k] ?? (alt != null ? j[alt] : null)) as num?)?.toDouble() ?? 0;
    String str_(String k) => j[k] as String? ?? '';
    return CreditAccountDto(
      creditLimit: num_('creditLimit'),
      usedAmount: num_('usedAmount', 'principalBalance'),
      pendingBalance: num_('pendingBalance', 'totalDebt'),
      minimumPayment: num_('minimumPayment'),
      noInterestPayment: num_('noInterestPayment'),
      cutoffDate: str_('cutoffDate'),
      paymentDueDate: str_('paymentDueDate'),
      noInterestDeadline: str_('noInterestDeadline'),
      annualRate: num_('annualRate', 'nominalRate'),
      cat: num_('cat'),
      accountNumber: str_('accountNumber'),
      productType: str_('productType'),
      behavior: (j['productBehavior'] ?? j['behavior'] ?? 'REVOLVING') as String,
      status: (j['status'] ?? 'ACTIVE') as String,
      assignedTerm: (j['assignedTerm'] as num?)?.toInt(),
      // Todavía no los manda el BFF en todos los shapes: null es un estado
      // válido y la UI lo contempla.
      paymentsMade: (j['paymentsMade'] ?? j['paidInstallments']) is num
          ? ((j['paymentsMade'] ?? j['paidInstallments']) as num).toInt()
          : null,
      principalPaid: (j['principalPaid'] as num?)?.toDouble(),
      // Cartera lo llama `daysDelinquent`; se acepta también `daysPastDue`
      // por si el contrato del BFF se alinea al nombre del payload móvil.
      daysPastDue: ((j['daysPastDue'] ?? j['daysDelinquent']) as num?)?.toInt(),
      // Lo vencido: el BFF de cartera lo expone como saldo de penalizaciones.
      overdueAmount:
          ((j['overdueAmount'] ?? j['penaltyBalance']) as num?)?.toDouble(),
    );
  }

  CreditAccount toDomain() => CreditAccount(
        creditLimit: creditLimit,
        usedAmount: usedAmount,
        pendingBalance: pendingBalance,
        minimumPayment: minimumPayment,
        noInterestPayment: noInterestPayment,
        cutoffDate: DateTime.tryParse(cutoffDate) ?? DateTime.now(),
        paymentDueDate: DateTime.tryParse(paymentDueDate) ?? DateTime.now(),
        noInterestDeadline: DateTime.tryParse(noInterestDeadline) ?? DateTime.now(),
        annualRate: annualRate,
        cat: cat,
        accountNumber: accountNumber,
        productType: productType,
        behavior: behavior,
        status: status,
        assignedTerm: assignedTerm,
        paymentsMade: paymentsMade,
        principalPaid: principalPaid,
        daysPastDue: daysPastDue,
        overdueAmount: overdueAmount,
      );
}
