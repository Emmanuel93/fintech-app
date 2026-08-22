/// Resumen de la línea de colocación del distribuidor — la tarjeta
/// "MI LÍNEA DE DISTRIBUIDOR" del home (Journey App L703–L734).
///
/// Mezcla dos cosas a propósito: el estado de la línea (autorizado, colocado,
/// disponible) y el corte de la quincena (qué va a cobrar, qué le toca pagar,
/// cuánto lleva ganado). Quien coloca no piensa en ellas por separado.
class DistributorLine {
  const DistributorLine({
    required this.authorized,
    required this.placed,
    required this.toCollect,
    required this.dueToKredius,
    required this.commissionAccrued,
    this.nextDueDate,
    this.daysPastDue = 0,
  });

  /// Línea total autorizada por el comité.
  final double authorized;

  /// Lo colocado y vivo. `authorized - placed` es lo que se puede colocar hoy.
  final double placed;

  /// Lo que los beneficiarios le deben pagar en el corte.
  final double toCollect;

  /// Lo que el distribuidor le debe pagar a Kredius en el corte.
  final double dueToKredius;

  /// Bonificación acumulada del periodo.
  final double commissionAccrued;

  final DateTime? nextDueDate;

  /// Atraso de la propia línea con Kredius (no el de sus beneficiarios).
  final int daysPastDue;

  double get available => (authorized - placed).clamp(0, authorized);

  /// 0..1 — porción de la línea ya colocada. Si no hay línea autorizada, 0:
  /// dividir entre cero pintaría una barra llena con línea de cero.
  double get usage => authorized <= 0 ? 0 : (placed / authorized).clamp(0, 1);

  bool get isOverdue => daysPastDue > 0;

  String get statusLabel => isOverdue ? 'EN MORA' : 'AL CORRIENTE';
}
