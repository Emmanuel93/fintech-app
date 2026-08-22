/// Banda de riesgo del beneficiario.
enum BureauBand {
  low,
  medium,
  high;

  static BureauBand fromName(String? name) => BureauBand.values
      .firstWhere((b) => b.name == name, orElse: () => BureauBand.medium);
}

/// Tono de un renglón del desglose.
enum BureauFactTone {
  ok,
  warn,
  bad;

  static BureauFactTone fromName(String? name) => BureauFactTone.values
      .firstWhere((t) => t.name == name, orElse: () => BureauFactTone.ok);
}

/// Un renglón del reporte: "Peor atraso en 24 meses" → "29 días".
class BureauFact {
  const BureauFact({
    required this.label,
    required this.value,
    this.tone = BureauFactTone.ok,
  });

  final String label, value;
  final BureauFactTone tone;
}

/// Reporte de buró del beneficiario, tal como se le entrega al distribuidor
/// (Journey App L1225–L1253).
///
/// Kredius **no aprueba ni rechaza** con esto (L1260): lo entrega completo para
/// que el distribuidor decida. Por eso el modelo no tiene un campo `approved`
/// — no existe tal decisión de este lado.
///
/// Se obtiene con la autorización que firmó el beneficiario, nunca con la del
/// distribuidor (L1226).
class BureauReport {
  const BureauReport({
    required this.score,
    required this.band,
    required this.bandLabel,
    required this.title,
    required this.description,
    required this.facts,
  });

  final int score;
  final BureauBand band;

  /// "RIESGO MEDIO".
  final String bandLabel;

  /// Lectura en palabras — "Paga, pero se ha atrasado".
  final String title;

  final String description;
  final List<BureauFact> facts;
}
