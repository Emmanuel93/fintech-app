import 'credit_purpose.dart';

/// Estado de sesión efímero compartido entre módulos (en memoria).
///
/// Hoy guarda el `prospectId` creado en el alta (fa_onboarding) para que el
/// flujo de crédito (fa_credit) pueda crear una `CreditApplication` sobre la
/// persona onboardeada (ADR-001: persona ≠ crédito).
///
/// Nota: vive sólo durante la sesión del proceso. Persistirlo (secure storage)
/// o resolverlo desde un endpoint `/me` queda como mejora futura.

class AppSession {
  AppSession._();

  static final AppSession instance = AppSession._();

  /// Id del prospecto onboardeado (persona). Vacío si aún no se ha dado de alta.
  String prospectId = '';

  /// Para qué pidió el crédito: gobierna qué productos se evalúan, a dónde se
  /// llega tras el análisis y en qué se enfoca el home.
  CreditPurpose purpose = CreditPurpose.usoPropio;

  /// Nombre y CURP del titular, capturados en el alta. Los usa el clausulado
  /// del contrato, que se arma en otro módulo.
  String holderName = '';
  String holderCurp = '';

  /// Celular verificado con OTP en el alta. La firma electrónica del contrato
  /// lo muestra enmascarado ("55 •• •• 42 18") para que el usuario sepa a qué
  /// número le llegó el código.
  String phone = '';

  /// `true` cuando el titular ya tiene línea de colocación autorizada.
  ///
  /// Lo publica el módulo de colocación al cargarla y lo consume el de crédito
  /// para **no** pintar su propia tarjeta de esa misma línea: sin este dato,
  /// el home del distribuidor enseñaría "tu solicitud está en revisión" encima
  /// de una línea que ya está disponible, que es la contradicción más cara que
  /// puede tener esa pantalla.
  ///
  /// Vive aquí, y no en un módulo, porque es justo el tipo de hecho que dos
  /// módulos que no se importan entre sí necesitan compartir.
  bool hasDistributorLine = false;

  bool get hasProspect => prospectId.isNotEmpty;

  void clear() {
    prospectId = '';
    purpose = CreditPurpose.usoPropio;
    hasDistributorLine = false;
    phone = '';
    holderName = '';
    holderCurp = '';
  }
}
