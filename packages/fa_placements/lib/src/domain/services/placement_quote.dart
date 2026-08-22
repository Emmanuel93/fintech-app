import 'dart:math' as math;

/// Condiciones comerciales de la colocación.
///
/// Los valores salen del prototipo (`Kredius Journey App.dc.html` L1652–L1657):
/// tasa de 28.9 % anual sobre 24 quincenas y plazos de 12, 24, 36 y 48. Viven
/// aquí y no en la pantalla porque el configurador, el resumen y la lista los
/// necesitan iguales.
///
/// Cuando el BFF exponga el catálogo de la línea, estos valores llegarán en la
/// respuesta de `/distributor/line-summary` y esta clase pasará a ser el
/// *fallback*, no la fuente.
abstract final class PlacementPricing {
  static const double annualRate = 0.289;

  /// Quincenas al año. El préstamo del distribuidor se cobra por quincena
  /// porque así cobra él a sus clientes (L1299).
  static const int periodsPerYear = 24;

  static const List<int> terms = [12, 24, 36, 48];

  static const double minAmount = 5000;
  static const double amountStep = 1000;

  static double get periodRate => annualRate / periodsPerYear;
}

/// Política de bonificación del distribuidor — Journey App L1335.
///
/// 20 % de lo que cobra **a tiempo**, y cada día de atraso la baja: 17, 14, 10,
/// 6 y al quinto día cero. No es una multa aparte: es la misma comisión, que se
/// devenga menos.
abstract final class CommissionPolicy {
  /// Índice = días de atraso. A partir del quinto, cero.
  static const List<double> _schedule = [0.20, 0.17, 0.14, 0.10, 0.06];

  static double get onTimeRate => _schedule.first;

  static double rateForDaysLate(int daysLate) {
    if (daysLate <= 0) return _schedule.first;
    if (daysLate >= _schedule.length) return 0;
    return _schedule[daysLate];
  }

  /// Lo que se gana por un cobro de [payment] con [daysLate] días de atraso.
  static double onPayment(double payment, {int daysLate = 0}) =>
      payment * rateForDaysLate(daysLate);
}

/// Cotización de una colocación: lo que paga el beneficiario y lo que gana el
/// distribuidor, para un monto y un plazo dados.
///
/// Es un cálculo local para que el slider responda en cada movimiento sin ir al
/// servidor. **La cifra que manda es la del contrato**: al aprobar, el backend
/// recalcula y lo que se firma es lo suyo.
class PlacementQuote {
  const PlacementQuote({required this.amount, required this.termFortnights});

  final double amount;
  final int termFortnights;

  /// Anualidad francesa sobre la tasa quincenal.
  double get fortnightlyPayment {
    final i = PlacementPricing.periodRate;
    if (termFortnights <= 0) return 0;
    if (i <= 0) return amount / termFortnights;
    return amount * i / (1 - math.pow(1 + i, -termFortnights));
  }

  /// Todo lo que el beneficiario va a pagar.
  double get totalToCollect => fortnightlyPayment * termFortnights;

  /// Intereses de la colocación.
  double get interest => totalToCollect - amount;

  /// Bonificación de una sola quincena cobrada a tiempo.
  double get commissionPerPayment =>
      CommissionPolicy.onPayment(fortnightlyPayment);

  /// Bonificación total si cobra todas las quincenas a tiempo — el "si" es
  /// parte del dato y por eso la etiqueta del diseño lo dice (L2062).
  double get commissionIfAllOnTime =>
      CommissionPolicy.onPayment(totalToCollect);
}
