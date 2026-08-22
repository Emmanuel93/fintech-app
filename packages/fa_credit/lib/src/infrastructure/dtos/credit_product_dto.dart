import '../../domain/entities/credit_product.dart';

class CreditProductDto {
  const CreditProductDto(this._j);
  final Map<String, dynamic> _j;

  factory CreditProductDto.fromJson(Map<String, dynamic> j) =>
      CreditProductDto(j);

  CreditProduct toDomain() => CreditProduct(
        code: (_j['code'] ?? _j['productCode'] ?? '') as String,
        name: (_j['name'] ?? _j['displayName'] ?? _j['code'] ?? 'Producto')
            as String,
        productType: (_j['productType'] ?? '') as String,
        behavior: (_j['behavior'] ?? _j['productBehavior'] ?? '') as String,
        description: _j['description'] as String?,
        minAmount: (_j['minAmount'] as num?)?.toDouble(),
        maxAmount: (_j['maxAmount'] as num?)?.toDouble(),
        minTerm: (_j['minTerm'] as num?)?.toInt(),
        maxTerm: (_j['maxTerm'] as num?)?.toInt(),
        nominalRate:
            ((_j['nominalRate'] ?? _j['nominalRateAnnual']) as num?)
                ?.toDouble(),
        defaultPaymentFrequency: _j['defaultPaymentFrequency'] as String?,
        targetAudience: _j['targetAudience'] as String?,
        amountStep: (_j['amountStep'] as num?)?.toInt(),
        defaultTerm: (_j['defaultTerm'] as num?)?.toInt(),
      );
}
