import '../../domain/entities/prequalified_product.dart';
import 'credit_product_dto.dart';

/// El BFF mergea en un solo mapa los campos del catálogo (código, nombre, tasa,
/// etc.) con los de la decisión de precalificación (evaluated/decision/riskLevel/
/// skippedReason) — un solo JSON por producto, sin anidar.
class PrequalifiedProductDto {
  const PrequalifiedProductDto(this._j);
  final Map<String, dynamic> _j;

  factory PrequalifiedProductDto.fromJson(Map<String, dynamic> j) =>
      PrequalifiedProductDto(j);

  PrequalifiedProduct toDomain() {
    // La preoferta llega anidada porque son condiciones de la persona, no del
    // producto: el mismo catálogo da límites distintos a cada solicitante.
    final offer = _j['preOffer'] as Map<String, dynamic>?;

    return PrequalifiedProduct(
      product: CreditProductDto.fromJson(_j).toDomain(),
      evaluated: _j['evaluated'] as bool? ?? false,
      skippedReason: _j['skippedReason'] as String?,
      decision: _j['decision'] as String?,
      riskLevel: _j['riskLevel'] as String?,
      approvedMinAmount: _num(offer?['minAmount']),
      approvedMaxAmount: _num(offer?['maxAmount']),
      approvedMinTerm: (offer?['minTerm'] as num?)?.toInt(),
      approvedMaxTerm: (offer?['maxTerm'] as num?)?.toInt(),
      approvedDefaultTerm: (offer?['defaultTerm'] as num?)?.toInt(),
      approvedRate: _num(offer?['nominalRate']),
    );
  }

  static double? _num(Object? v) => (v as num?)?.toDouble();
}
