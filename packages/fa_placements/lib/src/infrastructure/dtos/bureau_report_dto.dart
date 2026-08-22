import '../../domain/entities/bureau_report.dart';

/// Contrato de `GET /placements/{id}/bureau`.
class BureauReportDto {
  const BureauReportDto({
    required this.score,
    required this.band,
    required this.bandLabel,
    required this.title,
    required this.description,
    required this.facts,
  });

  final int score;
  final String band, bandLabel, title, description;
  final List<Map<String, dynamic>> facts;

  factory BureauReportDto.fromJson(Map<String, dynamic> j) => BureauReportDto(
        score: (j['score'] as num?)?.toInt() ?? 0,
        band: j['band'] as String? ?? 'medium',
        bandLabel: j['bandLabel'] as String? ?? '',
        title: j['title'] as String? ?? '',
        description: j['description'] as String? ?? '',
        facts: (j['facts'] as List<dynamic>? ?? const [])
            .cast<Map<String, dynamic>>(),
      );

  BureauReport toDomain() => BureauReport(
        score: score,
        band: BureauBand.fromName(band),
        bandLabel: bandLabel,
        title: title,
        description: description,
        facts: facts
            .map((f) => BureauFact(
                  label: f['label'] as String? ?? '',
                  value: f['value'] as String? ?? '',
                  tone: BureauFactTone.fromName(f['tone'] as String?),
                ))
            .toList(),
      );
}
