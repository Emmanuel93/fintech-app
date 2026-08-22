/// Los pasos del alta, en un solo lugar.
///
/// El orden responde a una regla: **nada se pide antes de tener permiso para
/// pedirlo**. Por eso la privacidad y la autorización de consulta a buró y
/// círculo abren el alta, antes de cualquier dato personal — pedir el celular
/// y después preguntar si se puede guardar es pedir perdón en vez de permiso.
///
/// Después va **el propósito** (uso propio o colocación), que el prototipo no
/// contempla: define qué productos se evalúan y a qué pantalla lleva el
/// análisis, así que preguntarlo más tarde obligaría a rehacer la evaluación.
///
/// Y sólo entonces el celular, que es lo primero que identifica a la persona:
/// se captura y se verifica de inmediato con el código, sin pantallas de por
/// medio que enfríen la espera del SMS.
enum AltaStep {
  /// Aviso de privacidad, términos y autorización de consulta a SIC.
  privacidad(1),

  /// Para qué quiere el crédito: uso propio o colocación. Gobierna qué
  /// productos se evalúan y a dónde lleva el análisis.
  proposito(2),

  /// Celular + correo de contacto. Al continuar sale el código.
  celular(3),

  /// Verificación del código de un solo uso, que firma la autorización.
  codigo(4),

  /// Documentos → Verifica tus datos (una pantalla, dos pestañas).
  identidad(5),

  /// Creación de contraseña y alta del prospecto.
  contrasena(6);

  const AltaStep(this.number);

  /// Posición 1-based dentro del alta.
  final int number;

  /// Total de pasos — el denominador de "N/total".
  static const int total = 6;
}
