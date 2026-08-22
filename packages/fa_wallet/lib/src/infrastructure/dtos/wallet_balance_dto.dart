import '../../domain/entities/wallet_balance.dart';

class WalletBalanceDto {
  const WalletBalanceDto({
    required this.available,
    required this.accountNumber,
    required this.currency,
    this.clabe,
  });

  final double available;
  final String accountNumber, currency;
  final String? clabe;

  factory WalletBalanceDto.fromJson(Map<String, dynamic> j) => WalletBalanceDto(
        available: (j['available'] as num).toDouble(),
        accountNumber: j['accountNumber'] as String,
        currency: j['currency'] as String? ?? 'MXN',
        clabe: j['clabe'] as String?,
      );

  WalletBalance toDomain() => WalletBalance(
        available: available,
        accountNumber: accountNumber,
        currency: currency,
        clabe: clabe,
      );
}
