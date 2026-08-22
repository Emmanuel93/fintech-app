import 'credit_product.dart';

/// Resultado de precalificar un producto contra el score del prospecto
/// (GET /credit/prequalification). Envuelve el `CreditProduct` del catálogo
/// con la decisión de scoring correspondiente.
class PrequalifiedProduct {
  const PrequalifiedProduct({
    required this.product,
    required this.evaluated,
    this.skippedReason,
    this.decision,
    this.riskLevel,
    this.approvedMinAmount,
    this.approvedMaxAmount,
    this.approvedMinTerm,
    this.approvedMaxTerm,
    this.approvedDefaultTerm,
    this.approvedRate,
  });

  final CreditProduct product;
  final bool evaluated;

  /// NO_BUREAU_REPORT | NO_ACTIVE_POLICY | null si evaluated=true
  final String? skippedReason;

  /// AUTO_APPROVED | MANUAL_REVIEW | REJECTED | null si evaluated=false
  final String? decision;

  /// BAJO | MEDIO | ALTO | null si evaluated=false
  final String? riskLevel;

  /// La preoferta: hasta dónde llega **esta** persona, no el producto.
  ///
  /// El catálogo publica el rango comercial (p. ej. $5.000–$150.000 a 6–48
  /// meses); el scoring decide qué parte de ese rango se le abre a quien lo
  /// pide. Configurar sobre el rango del catálogo es ofrecer un monto que
  /// después se recorta en la resolución — el usuario arma un préstamo que no
  /// existe y se entera al final.
  final double? approvedMinAmount, approvedMaxAmount;
  final int? approvedMinTerm, approvedMaxTerm, approvedDefaultTerm;

  /// La tasa también sale del riesgo: a mayor riesgo, mayor tasa.
  final double? approvedRate;

  bool get isAutoApproved => decision == 'AUTO_APPROVED';

  /// Hay condiciones concretas que configurar (y no sólo un rango de catálogo).
  bool get hasPreOffer => approvedMaxAmount != null || approvedMaxTerm != null;

  /// El producto tal como se le puede ofrecer a esta persona: los topes del
  /// catálogo, recortados a lo que el scoring autorizó. Es lo que consumen el
  /// configurador y el contrato, para que ambos hablen del mismo crédito.
  CreditProduct get offer => product.withLimits(
        minAmount: approvedMinAmount,
        maxAmount: approvedMaxAmount,
        minTerm: approvedMinTerm,
        maxTerm: approvedMaxTerm,
        defaultTerm: approvedDefaultTerm,
        nominalRate: approvedRate,
      );
}
