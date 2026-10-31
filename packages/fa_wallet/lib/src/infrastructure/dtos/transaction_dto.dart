import '../../domain/entities/transaction.dart';

class TransactionDto {
  const TransactionDto({
    required this.id,
    required this.type,
    required this.category,
    required this.description,
    required this.amount,
    required this.date,
    this.merchant,
    this.reference,
  });

  final String id, type, category, description, date;
  final double amount;
  final String? merchant, reference;

  factory TransactionDto.fromJson(Map<String, dynamic> j) => TransactionDto(
        id: j['id'] as String,
        type: j['type'] as String,
        category: j['category'] as String,
        description: j['description'] as String,
        amount: (j['amount'] as num).toDouble(),
        date: j['date'] as String,
        merchant: j['merchant'] as String?,
        reference: j['reference'] as String?,
      );

  Transaction toDomain() => Transaction(
        id: id,
        type: _parseType(type),
        category: _parseCat(category),
        description: description,
        amount: amount,
        date: DateTime.parse(date).toLocal(),
        merchant: merchant,
        reference: reference,
      );

  static TransactionType _parseType(String s) =>
      TransactionType.values.firstWhere((e) => e.name == s,
          orElse: () => TransactionType.debit);

  static TransactionCategory _parseCat(String s) =>
      TransactionCategory.values.firstWhere((e) => e.name == s,
          orElse: () => TransactionCategory.other);
}
