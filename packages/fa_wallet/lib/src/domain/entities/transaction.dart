enum TransactionType { credit, debit }

enum TransactionCategory {
  disposicion,
  transferOut,
  transferIn,
  payment,
  deposit,
  withdrawal,
  interest,
  other,
}

enum TransactionStatus { completed, pending, failed }

class Transaction {
  const Transaction({
    required this.id,
    required this.type,
    required this.category,
    required this.description,
    required this.amount,
    required this.date,
    this.status = TransactionStatus.completed,
    this.reference,
    this.merchant,
  });

  final String id;
  final TransactionType type;
  final TransactionCategory category;
  final String description;
  final double amount;
  final DateTime date;
  final TransactionStatus status;
  final String? reference;
  final String? merchant;

  bool get isIncome => type == TransactionType.credit;

  /// Crea una transacción de disposición de crédito de forma inmutable.
  factory Transaction.disposition({required double amount}) => Transaction(
        id: 'disp_${DateTime.now().millisecondsSinceEpoch}',
        type: TransactionType.credit,
        category: TransactionCategory.disposicion,
        description: 'Disposición de crédito',
        amount: amount,
        date: DateTime.now(),
      );
}
