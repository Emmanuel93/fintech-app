import '../../domain/entities/beneficiary.dart';

/// Contrato de `GET /beneficiaries`.
class BeneficiaryDto {
  const BeneficiaryDto({
    required this.partyId,
    required this.fullName,
    required this.phoneMask,
    required this.summary,
    required this.status,
    required this.facts,
    this.placementsCount,
  });

  final String partyId, fullName, phoneMask, summary, status;
  final List<Map<String, dynamic>> facts;
  final int? placementsCount;

  factory BeneficiaryDto.fromJson(Map<String, dynamic> j) => BeneficiaryDto(
        partyId: j['partyId'] as String? ?? '',
        fullName: j['fullName'] as String? ?? '',
        phoneMask: j['phoneMask'] as String? ?? '',
        summary: j['summary'] as String? ?? '',
        status: j['status'] as String? ?? 'active',
        facts: (j['facts'] as List<dynamic>? ?? const [])
            .cast<Map<String, dynamic>>(),
        placementsCount: (j['placementsCount'] as num?)?.toInt(),
      );

  Beneficiary toDomain() => Beneficiary(
        partyId: partyId,
        name: fullName,
        phoneMask: phoneMask,
        summary: summary,
        status: BeneficiaryStatus.fromName(status),
        placementsCount: placementsCount ?? 0,
        facts: facts
            .map((f) => BeneficiaryFact(
                  label: f['label'] as String? ?? '',
                  value: f['value'] as String? ?? '',
                  good: f['good'] as bool? ?? false,
                  bad: f['bad'] as bool? ?? false,
                ))
            .toList(),
      );
}
