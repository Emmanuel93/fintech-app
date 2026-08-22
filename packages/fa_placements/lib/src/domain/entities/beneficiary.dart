/// Estado de la relación con un beneficiario, para el directorio (pestaña
/// Beneficiarios, Journey App L873–L932).
enum BeneficiaryStatus {
  /// Con préstamo vivo y al corriente.
  active,

  /// Con préstamo vivo y atrasado.
  overdue,

  /// Todavía terminando su verificación: aún no hay crédito.
  onboarding,

  /// Ya liquidó todo lo que le prestaste.
  paidOff;

  static BeneficiaryStatus fromName(String? name) =>
      BeneficiaryStatus.values.firstWhere((s) => s.name == name,
          orElse: () => BeneficiaryStatus.active);
}

/// Un dato de la ficha desplegable del beneficiario.
class BeneficiaryFact {
  const BeneficiaryFact({
    required this.label,
    required this.value,
    this.good = false,
    this.bad = false,
  });

  final String label, value;
  final bool good, bad;
}

/// Ficha de un beneficiario en el directorio del distribuidor.
///
/// No es lo mismo que [Placement]: la colocación es una operación y esto es la
/// persona. Una persona puede tener varias colocaciones a lo largo del tiempo,
/// y el diseño lo separa en dos pestañas justo por eso (L930).
class Beneficiary {
  const Beneficiary({
    required this.partyId,
    required this.name,
    required this.phoneMask,
    required this.summary,
    required this.status,
    required this.facts,
    this.placementsCount = 0,
  });

  final String partyId;
  final String name;
  final String phoneMask;

  /// "Clienta desde 2023 · 2 préstamos contigo".
  final String summary;

  final BeneficiaryStatus status;
  final List<BeneficiaryFact> facts;
  final int placementsCount;

  /// Coincide con lo tecleado en el buscador, por nombre o por teléfono
  /// (L2123). Ignora mayúsculas; el teléfono se compara sólo por dígitos para
  /// que "55 41" encuentre al que se guardó como "5541…".
  bool matches(String query) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return true;
    if (name.toLowerCase().contains(q)) return true;
    final digits = RegExp(r'\D').allMatches(q).isEmpty ? q : q.replaceAll(RegExp(r'\D'), '');
    return digits.isNotEmpty && phoneMask.replaceAll(RegExp(r'\D'), '').contains(digits);
  }
}
