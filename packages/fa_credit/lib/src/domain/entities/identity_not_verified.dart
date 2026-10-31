/// La solicitud no se recibió porque la identidad de la persona todavía no
/// está verificada.
///
/// No es un error del sistema: sin proveedor biométrico conectado, toda
/// identidad pasa por revisión humana, y mientras tanto origination no recibe
/// solicitudes. La app lo dice como lo que es —«estamos verificando tu
/// identidad»— en vez de «no pudimos enviar tu solicitud, intenta de nuevo»,
/// que invitaba a reintentar algo que no depende de la persona.
class IdentityNotVerified implements Exception {
  const IdentityNotVerified({this.identityStatus, this.screeningStatus});

  /// `PENDING` · `IN_REVIEW` · `REJECTED` (compliance).
  final String? identityStatus;

  /// `PENDING` · `CLEARED` · `POTENTIAL_MATCH` · `CONFIRMED_MATCH`.
  final String? screeningStatus;

  /// Ya hay dictamen y no pasa: esperar no lo cambia.
  bool get isFinal =>
      identityStatus == 'REJECTED' || screeningStatus == 'CONFIRMED_MATCH';

  @override
  String toString() =>
      'IdentityNotVerified(identity=$identityStatus, screening=$screeningStatus)';
}
