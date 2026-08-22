import '../../domain/entities/credit_application.dart';

class CreditApplicationDto {
  const CreditApplicationDto(this._j);
  final Map<String, dynamic> _j;

  factory CreditApplicationDto.fromJson(Map<String, dynamic> j) =>
      CreditApplicationDto(j);

  double? _d(String k) => (_j[k] as num?)?.toDouble();
  int? _i(String k) => (_j[k] as num?)?.toInt();

  CreditApplication toDomain() => CreditApplication(
        applicationId: (_j['applicationId'] ?? '') as String,
        prospectId: (_j['prospectId'] ?? '') as String,
        productType: (_j['productType'] ?? '') as String,
        status: (_j['status'] ?? 'PENDING_SCORING') as String,
        requestedAmount: _d('requestedAmount'),
        requestedTerm: _i('requestedTerm'),
        decision: _j['decision'] as String?,
        riskLevel: _j['riskLevel'] as String?,
        rejectionReason: _j['rejectionReason'] as String?,
        // Oferta (pass-through del CreditApplicationResponse de origination vía BFF)
        offeredAmount: _d('offeredAmount'),
        offeredLine: _d('offeredLine'),
        offeredTerm: _i('offeredTerm'),
        nominalRate: _d('nominalRate'),
        cat: _d('cat'),
        validUntil: _j['validUntil'] as String?,
        // Contrato
        contractNumber: _j['contractNumber'] as String?,
        clabeAccount: _j['clabeAccount'] as String?,
      );
}
