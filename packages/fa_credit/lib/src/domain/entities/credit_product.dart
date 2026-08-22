/// Producto del catálogo de crédito (credit-product-service, D4).
/// La persona ya onboardeada elige uno para crear una `CreditApplication`.
class CreditProduct {
  const CreditProduct({
    required this.code,
    required this.name,
    required this.productType,
    required this.behavior,
    this.description,
    this.minAmount,
    this.maxAmount,
    this.minTerm,
    this.maxTerm,
    this.nominalRate,
    this.defaultPaymentFrequency,
    this.targetAudience,
    this.amountStep,
    this.defaultTerm,
  });

  final String code;
  final String name;

  /// PERSONAL_LOAN | REVOLVING_LINE | PAYROLL_LOAN | GROUP_LOAN | DISTRIBUTOR_LINE
  final String productType;

  /// REVOLVING | INSTALLMENT
  final String behavior;

  final String? description;
  final double? minAmount;
  final double? maxAmount;
  final int? minTerm;
  final int? maxTerm;
  final double? nominalRate;

  /// WEEKLY | BIWEEKLY | MONTHLY — periodo de pago del producto (null para algunos
  /// revolventes sin amortización fija). Usado por AmortizationCalculator.
  final String? defaultPaymentFrequency;

  /// B2C | B2B | B2B2C
  final String? targetAudience;

  /// Incremento mínimo del slider de monto (ej. 1000 → $5k, $6k, $7k...).
  final int? amountStep;

  /// Plazo sugerido para preseleccionar el selector de plazo.
  final int? defaultTerm;

  /// Copia con los límites que autorizó el scoring encima de los del catálogo.
  /// El catálogo dice hasta dónde llega el producto; la preoferta, hasta dónde
  /// llega **esta** persona.
  CreditProduct withLimits({
    double? minAmount,
    double? maxAmount,
    int? minTerm,
    int? maxTerm,
    int? defaultTerm,
    double? nominalRate,
  }) =>
      CreditProduct(
        code: code,
        name: name,
        productType: productType,
        behavior: behavior,
        description: description,
        minAmount: minAmount ?? this.minAmount,
        maxAmount: maxAmount ?? this.maxAmount,
        minTerm: minTerm ?? this.minTerm,
        maxTerm: maxTerm ?? this.maxTerm,
        nominalRate: nominalRate ?? this.nominalRate,
        defaultPaymentFrequency: defaultPaymentFrequency,
        targetAudience: targetAudience,
        amountStep: amountStep,
        defaultTerm: defaultTerm ?? this.defaultTerm,
      );

  bool get isRevolving => behavior.toUpperCase() == 'REVOLVING';

  /// Las líneas revolventes no requieren monto/plazo al solicitar.
  bool get requiresAmount => !isRevolving;
}
