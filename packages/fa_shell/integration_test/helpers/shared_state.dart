import 'test_data.dart';

/// Estado compartido entre flujos de prueba dentro de la misma sesión.
///
/// El flujo de crear cuenta escribe aquí las credenciales recién creadas;
/// el flujo de login las lee. Esto garantiza que login SIEMPRE use una
/// cuenta que acaba de existir — nunca credenciales hardcodeadas que
/// pueden no existir en el backend local.
class SharedTestState {
  SharedTestState._();

  /// Teléfono usado al crear la cuenta. En mock = TestData.phone.
  /// En local = teléfono único generado por el test de crear cuenta.
  static String phone = TestData.phone;

  /// CURP con la que se dio de alta. Contra el backend real es única por
  /// corrida; contra el mock da igual y se queda con la de [TestData].
  static String curp = TestData.curp;

  /// Contraseña usada al crear la cuenta.
  static String password = TestData.password;

  /// True cuando el test de crear cuenta completó con éxito.
  static bool accountCreated = false;

  static void reset() {
    phone = TestData.phone;
    curp = TestData.curp;
    password = TestData.password;
    accountCreated = false;
  }
}
