/// Aplicación de crédito (subdominio underwriting de origination, ADR-001).
/// Se crea cuando una persona onboardeada elige un producto → dispara scoring.
/// Ciclo completo: PENDING_SCORING → APPROVED/comité → OFFER_PRESENTED →
/// OFFER_ACCEPTED → PENDING_SIGNATURE → CONTRACT_SIGNED → (activación) DISBURSED.
class CreditApplication {
  const CreditApplication({
    required this.applicationId,
    required this.prospectId,
    required this.productType,
    required this.status,
    this.requestedAmount,
    this.requestedTerm,
    this.decision,
    this.riskLevel,
    this.rejectionReason,
    // Oferta
    this.offeredAmount,
    this.offeredLine,
    this.offeredTerm,
    this.nominalRate,
    this.cat,
    this.validUntil,
    // Contrato
    this.contractNumber,
    this.clabeAccount,
  });

  final String applicationId;
  final String prospectId;
  final String productType;

  /// PENDING_SCORING | SCORING | APPROVED | UNDER_MANUAL_REVIEW | COMMITTEE_REVIEW |
  /// OFFER_PRESENTED | OFFER_ACCEPTED | PENDING_SIGNATURE | CONTRACT_SIGNED | DISBURSED |
  /// REJECTED | ...
  final String status;
  final double? requestedAmount;
  final int? requestedTerm;

  /// Decisión de scoring: AUTO_APPROVED | MANUAL_REVIEW | REJECTED (cuando llega).
  final String? decision;
  final String? riskLevel; // BAJO | MEDIO | ALTO
  final String? rejectionReason;

  // ── Oferta (poblada tras present offer) ────────────────────────────────────
  final double? offeredAmount; // monto (productos a plazo)
  final double? offeredLine;   // línea (productos revolventes)
  final int? offeredTerm;
  final double? nominalRate;   // tasa anual (0.32 = 32%)
  final double? cat;           // CAT
  final String? validUntil;

  // ── Contrato ───────────────────────────────────────────────────────────────
  final String? contractNumber;
  final String? clabeAccount;

  String get _s => status.toUpperCase();

  /// Estados en los que seguimos haciendo polling del backend (aún no requieren
  /// acción del usuario ni son terminales).
  static const _pending = {
    'DRAFT',
    'KYC_VALIDATION',
    'PENDING_SCORING',
    'SCORING',
    'PENDING_APPROVAL',
  };

  bool get isPending => _pending.contains(_s);

  /// Aprobada por scoring/comité — todavía sin oferta presentada.
  bool get isApproved => _s == 'APPROVED';

  bool get isRejected => _s == 'REJECTED' || (decision?.toUpperCase() == 'REJECTED');

  bool get isManualReview => _s == 'UNDER_MANUAL_REVIEW' || _s == 'COMMITTEE_REVIEW';

  bool get isOfferPresented => _s == 'OFFER_PRESENTED';
  bool get isOfferAccepted => _s == 'OFFER_ACCEPTED';
  bool get isPendingSignature => _s == 'PENDING_SIGNATURE';
  bool get isContractSigned => _s == 'CONTRACT_SIGNED' || _s == 'DISBURSED';

  /// Monto/línea a mostrar en la oferta (revolvente usa línea, a plazo usa monto).
  double? get offerAmountOrLine => offeredLine ?? offeredAmount;
}
