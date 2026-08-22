class CreditAccount {
  const CreditAccount({
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
    this.productType = '',
    this.behavior = 'REVOLVING',
    this.status = 'ACTIVE',
    this.assignedTerm,
    this.paymentsMade,
    this.principalPaid,
    this.daysPastDue,
    this.overdueAmount,
  });

  final double creditLimit;
  final double usedAmount;
  final double pendingBalance;
  final double minimumPayment;
  final double noInterestPayment;
  final DateTime cutoffDate;
  final DateTime paymentDueDate;
  final DateTime noInterestDeadline;
  final double annualRate;
  final double cat;
  final String accountNumber;
  final String productType;
  final String behavior; // REVOLVING | INSTALLMENT
  final String status;
  final int? assignedTerm; // plazo (productos a plazo)

  /// Pagos ya aplicados. `null` cuando el BFF todavía no lo expone — la UI
  /// muestra el crédito sin el contador en vez de inventar un cero.
  final int? paymentsMade;

  /// Capital ya amortizado. `null` si el BFF no lo manda.
  final double? principalPaid;

  /// Días de atraso y monto vencido, tal como los calcula cartera.
  ///
  /// La mora **la decide el backend**, no el reloj del teléfono: depende de
  /// días de gracia, festivos y de cuándo se aplicó el pago, cosas que la app
  /// no sabe. Cuando el BFF los manda, mandan ellos.
  final int? daysPastDue;
  final double? overdueAmount;

  /// Avance del plan de pagos, 0..1. `null` para revolventes (no hay plan) y
  /// mientras no se sepan los pagos hechos.
  double? get paymentProgress {
    final term = assignedTerm;
    final made = paymentsMade;
    if (isRevolving || term == null || term <= 0 || made == null) return null;
    return (made / term).clamp(0.0, 1.0);
  }

  bool get isRevolving => behavior.toUpperCase() == 'REVOLVING';

  static const _terminalStatuses = {'SETTLED', 'WRITTEN_OFF', 'CLOSED'};

  /// `true` para SETTLED/WRITTEN_OFF/CLOSED — mismo criterio que
  /// `CreditAccountStatus.isTerminal()` en credit-portfolio-service.
  bool get isTerminal => _terminalStatuses.contains(status.toUpperCase());

  static const _titleByProductType = {
    'PERSONAL_LOAN': 'Préstamo Personal',
    'PAYROLL_LOAN': 'Crédito de Nómina',
    'MICRO_LOAN': 'Micro Préstamo',
    'GROUP_LOAN': 'Crédito Grupal',
    'REVOLVING_LINE': 'Línea Revolvente',
    'CREDIT_CARD': 'Tarjeta de Crédito',
    'SME_LOAN': 'Crédito PYME',
    'BUSINESS_REVOLVING_LINE': 'Línea Empresarial',
    'DISTRIBUTOR_LINE': 'Línea Distribuidor',
  };

  /// Título legible según el tipo de producto (multi-segmento).
  String get displayTitle =>
      _titleByProductType[productType.toUpperCase()] ??
      (isRevolving ? 'Mi Crédito Revolvente' : 'Mi Crédito');

  double get availableCredit => (creditLimit - usedAmount).clamp(0.0, double.infinity);
  double get usedPercentage => creditLimit > 0 ? (usedAmount / creditLimit).clamp(0.0, 1.0) : 0.0;

  bool get isPaymentDueSoon {
    final daysUntilDue = paymentDueDate.difference(DateTime.now()).inDays;
    return daysUntilDue <= 5 && daysUntilDue >= 0;
  }

  /// En mora. Se prefiere lo que diga cartera; sólo si el BFF no lo expone se
  /// cae a comparar contra el vencimiento, que es una aproximación.
  bool get isOverdue {
    if (isPaidOff) return false;
    if (daysPastDue != null) return daysPastDue! > 0;
    if (status.toUpperCase() == 'PAST_DUE') return true;
    return DateTime.now().isAfter(paymentDueDate);
  }

  /// Liquidado: ya no se debe nada, así que tampoco se puede estar en mora.
  bool get isPaidOff =>
      status.toUpperCase() == 'PAID_OFF' || pendingBalance <= 0.5;

  /// "3 días" / "1 día" — para decir de cuánto es el atraso, no sólo que lo hay.
  String? get overdueLabel {
    final d = daysPastDue;
    if (d == null || d <= 0) return null;
    return d == 1 ? '1 día' : '$d días';
  }

  CreditAccount _copyWith({
    double? usedAmount,
    double? pendingBalance,
    double? noInterestPayment,
    int? paymentsMade,
  }) {
    return CreditAccount(
      creditLimit: creditLimit,
      usedAmount: usedAmount ?? this.usedAmount,
      pendingBalance: pendingBalance ?? this.pendingBalance,
      minimumPayment: minimumPayment,
      noInterestPayment: noInterestPayment ?? this.noInterestPayment,
      cutoffDate: cutoffDate,
      paymentDueDate: paymentDueDate,
      noInterestDeadline: noInterestDeadline,
      annualRate: annualRate,
      cat: cat,
      accountNumber: accountNumber,
      productType: productType,
      behavior: behavior,
      status: status,
      assignedTerm: assignedTerm,
      // Se arrastran: perderlos apaga el contador "PAGO n DE m" y la barra de
      // avance del home justo después de pagar, que es cuando el usuario mira
      // la tarjeta para comprobar que su pago entró.
      paymentsMade: paymentsMade ?? this.paymentsMade,
      principalPaid: principalPaid,
      daysPastDue: daysPastDue,
      overdueAmount: overdueAmount,
    );
  }

  /// Aplica un pago: reduce [pendingBalance] y [usedAmount], y avanza el
  /// contador de mensualidades. Proyección optimista mientras llega la
  /// relectura del BFF.
  ///
  /// Es una aproximación a propósito: el cliente no sabe cómo se reparte el
  /// pago entre interés y capital, así que descuenta todo del saldo. Quien la
  /// use debe releer después — si no, la tarjeta acaba creyendo que el crédito
  /// quedó liquidado varias mensualidades antes de tiempo.
  CreditAccount applyPayment(double amount) {
    final newBalance = (pendingBalance - amount).clamp(0.0, double.infinity);
    final newUsed = (usedAmount - amount).clamp(0.0, double.infinity);
    return _copyWith(
      usedAmount: newUsed,
      pendingBalance: newBalance,
      noInterestPayment: newBalance,
      paymentsMade: paymentsMade == null ? null : paymentsMade! + 1,
    );
  }

  /// Aplica una disposición: incrementa [usedAmount] y [pendingBalance].
  CreditAccount applyDisposition(double amount) {
    return _copyWith(
      usedAmount: usedAmount + amount,
      pendingBalance: pendingBalance + amount,
      noInterestPayment: noInterestPayment + amount,
    );
  }
}
