import '../../domain/entities/distributor_line.dart';

/// Contrato de `GET /distributor/line-summary`.
class DistributorLineDto {
  const DistributorLineDto({
    required this.authorized,
    required this.placed,
    this.toCollect,
    this.dueToKredius,
    this.commissionAccrued,
    this.nextDueDate,
    this.daysPastDue,
  });

  final num authorized, placed;
  final num? toCollect, dueToKredius, commissionAccrued;
  final String? nextDueDate;
  final int? daysPastDue;

  factory DistributorLineDto.fromJson(Map<String, dynamic> j) =>
      DistributorLineDto(
        authorized: j['authorized'] as num? ?? 0,
        placed: j['placed'] as num? ?? 0,
        toCollect: j['toCollect'] as num?,
        dueToKredius: j['dueToKredius'] as num?,
        commissionAccrued: j['commissionAccrued'] as num?,
        nextDueDate: j['nextDueDate'] as String?,
        daysPastDue: (j['daysPastDue'] as num?)?.toInt(),
      );

  DistributorLine toDomain() => DistributorLine(
        authorized: authorized.toDouble(),
        placed: placed.toDouble(),
        toCollect: toCollect?.toDouble() ?? 0,
        dueToKredius: dueToKredius?.toDouble() ?? 0,
        commissionAccrued: commissionAccrued?.toDouble() ?? 0,
        nextDueDate: DateTime.tryParse(nextDueDate ?? ''),
        daysPastDue: daysPastDue ?? 0,
      );
}
