class WalletBalance {
  const WalletBalance({
    required this.available,
    required this.accountNumber,
    this.frozen = 0,
    this.currency = 'MXN',
    this.clabe,
  });

  final double available;
  final double frozen;
  final String currency;
  final String accountNumber;

  /// CLABE de depósito (18 dígitos) — null hasta que el crédito esté activo.
  final String? clabe;

  double get total => available + frozen;

  /// Aplica un crédito (disposición) al saldo disponible.
  WalletBalance applyCredit(double amount) => WalletBalance(
        available: available + amount,
        accountNumber: accountNumber,
        frozen: frozen,
        currency: currency,
        clabe: clabe,
      );
}
