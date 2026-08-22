import 'dart:math';

/// Constantes de prueba alineadas con:
/// - OnboardingAcceptanceTest.java (channel-mobile-service/src/test)
/// - Seeds de credit-product-service (006-seed-initial-products.sql)
/// - application-local.yml: otp-dev-code: "123456"
class TestData {
  TestData._();

  // ── Credenciales (de OnboardingAcceptanceTest) ──────────────────────────
  static const phone = '5512345678';
  static const otp = '123456'; // OTP_DEV_CODE del BFF local
  static const password = 'SecurePass1!'; // ≥8 chars, mayúscula, número, símbolo

  // ── Identidad (de OnboardingAcceptanceTest.kycPayload) ─────────────────
  static const curp = 'RAHE930326HSMLRM09';
  static const rfc = 'RAHE930326XXX';
  static const nombres = 'EMMANUEL';
  static const apellidoPaterno = 'RAMÍREZ';
  static const apellidoMaterno = 'HERNÁNDEZ';
  // Etiqueta del selector. El código que viaja al BFF es 'H' (estándar CURP).
  static const genero = 'Hombre';
  // Usamos estados que aparecen en los primeros ítems de la lista (a-z)
  // para evitar scroll dentro del dropdown durante los tests.
  static const estadoNacimiento = 'Aguascalientes';
  static const email = 'test@fintech.mx';

  // ── Domicilio ───────────────────────────────────────────────────────────
  static const calle = 'Av. Principal';
  static const numExt = '100';
  static const colonia = 'Centro';
  static const municipio = 'Culiacán';
  static const ciudad = 'Culiacán';
  static const cp = '80060';
  static const estadoDomicilio = 'Baja California';

  // ── Fecha de nacimiento: 1993-03-26 ────────────────────────────────────
  static const fechaNacimientoDia = '26';
  static const fechaNacimientoMes = 3; // marzo → 1-indexed
  static const fechaNacimientoAnio = 1993;

  // ── Para pruebas contra local: identidad única por ejecución ───────────
  /// Evita DUPLICATE_PROSPECT contra el backend real.
  static String uniquePhone() {
    final ts = DateTime.now().millisecondsSinceEpoch;
    return '55${ts.toString().substring(ts.toString().length - 8)}';
  }

  /// CURP única por corrida, con la forma que exige el BFF.
  ///
  /// Origination rechaza el alta con `DUPLICATE_PROSPECT` **por CURP**, así que contra una
  /// base persistente un valor fijo sólo pasa la primera vez.
  ///
  /// El patrón que valida `/kyc/submit` es `[A-Z]{4}\d{6}[HM][A-Z]{5}[A-Z0-9]\d`, así que
  /// lo que puede variar son las **cinco letras** del bloque intermedio y las dos últimas
  /// posiciones. Meter un dígito entre las cinco letras produce un 400 que en la app se ve
  /// como «Intentar de nuevo» en el análisis, sin decir que el problema fue la CURP.
  ///
  /// Antes sólo variaban las dos últimas (350 combinaciones, derivadas del reloj): con la
  /// base persistente ya se agotaron y las corridas empezaron a chocar contra
  /// `DUPLICATE_PROSPECT`. Variando también las cinco letras el espacio pasa a ~4·10⁹, y el
  /// azar viene de `Random()`, no del epoch —dos corridas en el mismo milisegundo ya no
  /// generan la misma CURP—.
  static String uniqueCurp() {
    final azar = Random();
    const letras = 'ABCDEFGHIJKLMNPQRSTUVWXYZ';
    const alnum = 'ABCDEFGHIJKLMNPQRSTUVWXYZ0123456789';
    final bloque =
        List.generate(5, (_) => letras[azar.nextInt(letras.length)]).join();
    return 'RAHE930326H$bloque'
        '${alnum[azar.nextInt(alnum.length)]}'
        '${azar.nextInt(10)}';
  }

  // ── Productos (de 006-seed-initial-products.sql) ────────────────────────
  static const productPersonalLoan = 'PL-IND-STD-V1';
  static const productRevolvingLine = 'RL-IND-STD-V1';
  static const productPayrollLoan = 'PY-IND-STD-V1';
}
