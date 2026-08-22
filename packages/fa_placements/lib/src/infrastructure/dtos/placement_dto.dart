import '../../domain/entities/placement.dart';

/// Contrato de `GET /placements` y `GET /placements/{id}`.
class PlacementDto {
  const PlacementDto({
    required this.placementId,
    required this.beneficiaryName,
    required this.beneficiaryPhoneMask,
    required this.amount,
    required this.termFortnights,
    required this.fortnightlyPayment,
    required this.status,
    this.beneficiaryPartyId,
    this.relationship,
    this.commissionAccrued,
    this.paymentsMade,
    this.daysPastDue,
    this.placedOn,
    this.inviteExpiresAt,
  });

  final String placementId;
  final String beneficiaryName, beneficiaryPhoneMask, status;
  final num amount, fortnightlyPayment;
  final int termFortnights;
  final String? beneficiaryPartyId, relationship, placedOn, inviteExpiresAt;
  final num? commissionAccrued;
  final int? paymentsMade, daysPastDue;

  factory PlacementDto.fromJson(Map<String, dynamic> j) => PlacementDto(
        placementId: j['placementId'] as String,
        beneficiaryName: j['beneficiaryName'] as String? ?? '',
        beneficiaryPhoneMask: j['beneficiaryPhoneMask'] as String? ?? '',
        amount: j['amount'] as num? ?? 0,
        termFortnights: (j['termFortnights'] as num?)?.toInt() ?? 0,
        fortnightlyPayment: j['fortnightlyPayment'] as num? ?? 0,
        status: j['status'] as String? ?? 'invited',
        beneficiaryPartyId: j['beneficiaryPartyId'] as String?,
        relationship: j['relationship'] as String?,
        commissionAccrued: j['commissionAccrued'] as num?,
        paymentsMade: (j['paymentsMade'] as num?)?.toInt(),
        daysPastDue: (j['daysPastDue'] as num?)?.toInt(),
        placedOn: j['placedOn'] as String?,
        inviteExpiresAt: j['inviteExpiresAt'] as String?,
      );

  Placement toDomain() => Placement(
        id: placementId,
        beneficiaryName: beneficiaryName,
        beneficiaryPhoneMask: beneficiaryPhoneMask,
        amount: amount.toDouble(),
        termFortnights: termFortnights,
        fortnightlyPayment: fortnightlyPayment.toDouble(),
        status: PlacementStatus.fromName(status),
        beneficiaryPartyId: beneficiaryPartyId,
        relationship: relationship ?? '',
        commissionAccrued: commissionAccrued?.toDouble() ?? 0,
        paymentsMade: paymentsMade ?? 0,
        daysPastDue: daysPastDue ?? 0,
        placedOn: DateTime.tryParse(placedOn ?? ''),
        inviteExpiresAt: DateTime.tryParse(inviteExpiresAt ?? ''),
      );
}
