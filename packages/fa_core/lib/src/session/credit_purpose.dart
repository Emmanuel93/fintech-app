/// Para qué quiere el crédito la persona que se da de alta.
///
/// Es la primera decisión del alta y la que gobierna todo lo que sigue: qué
/// productos se evalúan, a qué pantalla se llega después del análisis, qué
/// clausulado lleva el contrato y en qué se enfoca el home.
///
/// Vive en `fa_core` porque la eligen en `fa_onboarding` y la consumen
/// `fa_credit` y el shell — los módulos no se importan entre sí.
enum CreditPurpose {
  /// El crédito lo usa quien lo pide. Productos B2C.
  usoPropio(
    title: 'Para mí',
    subtitle: 'Uso propio: el dinero llega a tu cuenta y tú lo pagas.',
    highlights: [
      'Préstamo personal, nómina, revolvente y grupal',
      'Un solo expediente: el tuyo',
      'Depósito directo a tu CLABE',
    ],
    audiences: {'B2C'},
  ),

  /// El crédito se coloca con terceros. Productos B2B y B2B2C: el titular
  /// dispone de una línea y presta a sus clientes, cobrando una comisión.
  distribuidor(
    title: 'Para colocar a terceros',
    subtitle: 'Distribuidora: prestas con nuestra línea y ganas comisión.',
    highlights: [
      'Línea revolvente de \$25,000 a \$500,000',
      'KYC de cada beneficiario desde la app',
      '20% de comisión sobre lo que cobras a tiempo',
    ],
    audiences: {'B2B', 'B2B2C'},
  );

  const CreditPurpose({
    required this.title,
    required this.subtitle,
    required this.highlights,
    required this.audiences,
  });

  final String title;
  final String subtitle;

  /// Lo que incluye cada camino, en tres viñetas. El diseño (Journey App
  /// L1905, L1908) las despliega **sólo en la opción elegida**: mostrarlas
  /// todas convierte la decisión en un comparativo de seis renglones.
  final List<String> highlights;

  /// Segmentos de `CreditProduct.targetAudience` que aplican a este propósito.
  final Set<String> audiences;

  bool get isDistribuidor => this == CreditPurpose.distribuidor;

  /// `true` si el producto de este `targetAudience` corresponde al propósito.
  bool matches(String? targetAudience) =>
      audiences.contains((targetAudience ?? 'B2C').toUpperCase());

  static CreditPurpose fromName(String? name) =>
      CreditPurpose.values.firstWhere(
        (p) => p.name == name,
        orElse: () => CreditPurpose.usoPropio,
      );
}
