/// Estado de una colocación, tal como lo define el flujo del diseño
/// (`Kredius Journey App.dc.html`, pantallas 18 → 25 y pestaña Colocaciones).
///
/// El orden de la enumeración es el orden del ciclo de vida. Los tres finales
/// no son "errores": expirar o cancelarse antes del KYC es un desenlace normal
/// y, sobre todo, **no toca la línea** (L1375).
enum PlacementStatus {
  /// Se mandó la liga; el beneficiario no la ha abierto.
  invited,

  /// El beneficiario está en su verificación (web propia, desde su celular).
  kycInProgress,

  /// KYC terminado y buró consultado: le toca decidir al distribuidor.
  bureauReady,

  /// El distribuidor aprobó; el dinero se está enviando.
  approved,

  /// Depositado y con contrato vivo: es la colocación que ya cobra.
  active,

  /// El beneficiario liquidó.
  paidOff,

  /// El distribuidor decidió no colocar tras ver el historial.
  declined,

  /// La liga venció sin que el beneficiario completara su verificación.
  expired,

  /// El distribuidor la canceló antes de que el beneficiario terminara.
  cancelled,

  /// Algo se rompió: el buró no respondió, la línea no alcanzó al momento de
  /// disponer, el desembolso falló.
  ///
  /// Es el único terminal que no es decisión de nadie, y por eso siempre trae
  /// motivo. Tiene que existir en este enum aunque la app no lo produzca: el
  /// fallback manda lo desconocido a [invited], y una colocación muerta pintada
  /// como «liga enviada» dejaría al distribuidor esperando para siempre.
  failed;

  static PlacementStatus fromName(String? name) => PlacementStatus.values
      .firstWhere((s) => s.name == name, orElse: () => PlacementStatus.invited);

  /// La colocación todavía no consume línea ni genera comisión: está en el
  /// tramo en que puede no llegar a existir.
  bool get isPending =>
      this == PlacementStatus.invited ||
      this == PlacementStatus.kycInProgress ||
      this == PlacementStatus.bureauReady;

  /// Terminó sin crédito. No aparece en "colocaciones vivas".
  bool get isClosedWithoutCredit =>
      this == PlacementStatus.declined ||
      this == PlacementStatus.expired ||
      this == PlacementStatus.cancelled ||
      this == PlacementStatus.failed;

  /// Consume línea: aprobada, activa o ya liquidada — de todas se dispuso.
  bool get consumesLine =>
      this == PlacementStatus.approved ||
      this == PlacementStatus.active ||
      this == PlacementStatus.paidOff;
}

/// Una colocación: el préstamo que un distribuidor envía a un beneficiario.
///
/// El crédito y el contrato quedan a nombre del beneficiario; la deuda de la
/// línea sigue siendo del distribuidor (L1045). Por eso esta entidad guarda las
/// dos caras: lo que el beneficiario paga y lo que el distribuidor gana.
class Placement {
  const Placement({
    required this.id,
    required this.beneficiaryName,
    required this.beneficiaryPhoneMask,
    required this.amount,
    required this.termFortnights,
    required this.fortnightlyPayment,
    required this.status,
    this.beneficiaryPartyId,
    this.relationship = '',
    this.commissionAccrued = 0,
    this.paymentsMade = 0,
    this.daysPastDue = 0,
    this.placedOn,
    this.inviteExpiresAt,
  });

  final String id;
  final String beneficiaryName;

  /// El celular nunca llega completo desde el BFF: el distribuidor no necesita
  /// verlo, sólo reconocerlo.
  final String beneficiaryPhoneMask;

  final double amount;
  final int termFortnights;
  final double fortnightlyPayment;
  final PlacementStatus status;

  /// Existe sólo cuando el beneficiario terminó su KYC y ya es un Party.
  final String? beneficiaryPartyId;

  /// "Clienta de mi tienda desde 2023" — lo que el distribuidor declaró.
  final String relationship;

  final double commissionAccrued;
  final int paymentsMade;

  /// Días de atraso de la mensualidad vencida. Lo decide el backend, nunca el
  /// reloj del teléfono: dependen de días de gracia y de cuándo se aplicó el
  /// pago.
  final int daysPastDue;

  final DateTime? placedOn;
  final DateTime? inviteExpiresAt;

  bool get isOverdue => daysPastDue > 0 && status == PlacementStatus.active;

  /// Total que el beneficiario paga en toda la vida del préstamo.
  double get totalToCollect => fortnightlyPayment * termFortnights;

  Placement copyWith({
    PlacementStatus? status,
    String? beneficiaryPartyId,
    double? commissionAccrued,
    int? paymentsMade,
    int? daysPastDue,
    DateTime? placedOn,
  }) =>
      Placement(
        id: id,
        beneficiaryName: beneficiaryName,
        beneficiaryPhoneMask: beneficiaryPhoneMask,
        amount: amount,
        termFortnights: termFortnights,
        fortnightlyPayment: fortnightlyPayment,
        status: status ?? this.status,
        beneficiaryPartyId: beneficiaryPartyId ?? this.beneficiaryPartyId,
        relationship: relationship,
        commissionAccrued: commissionAccrued ?? this.commissionAccrued,
        paymentsMade: paymentsMade ?? this.paymentsMade,
        daysPastDue: daysPastDue ?? this.daysPastDue,
        placedOn: placedOn ?? this.placedOn,
        inviteExpiresAt: inviteExpiresAt,
      );
}
