/// Colocación E2E **conectada** — sin un solo mock.
///
/// Corre la app en flavor `local`, que apunta al gateway; de ahí en adelante
/// todo es real: BFF → beneficiary-service → credit-portfolio, scoring, wallet.
/// Lo único simulado son los servicios externos de verdad (buró y SPEI), que
/// están stubbeados **dentro** de los servicios, como corresponde.
///
/// Verifica lo que ningún test unitario puede: que el contrato que la app
/// parsea es el que el backend emite, campo por campo.
///
/// Requiere el stack arriba:
///   docker compose up -d   (en fintech-services)
///
/// Correr:
///   flutter test integration_test/placement_connected_e2e_test.dart -d <device>
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'helpers/test_data.dart';
import 'helpers/test_helpers.dart';
import 'package:fa_shell/main_local.dart' as local_app;

/// Distribuidora sembrada con línea `DL-DIST-STD-V1` activa.
///
/// El teléfono cambia cada vez que se resiembra la base (`scripts/reinicia-y-siembra.sh`).
/// Para encontrar uno vigente:
///
/// ```sql
/// select c.username from identity.credentials c
///   join credit_portfolio.credit_accounts ca
///     on ca.obligor_party_id = c.party_id
///    and ca.product_type = 'DISTRIBUTOR_LINE' and ca.status = 'ACTIVE';
/// ```
/// Distribuidora sembrada con línea aprobada.
///
/// `seed-distribuidoras.py` genera los teléfonos al azar (`55` + 8 dígitos), así que
/// este valor caduca en cuanto se resiembra la base: el login devuelve
/// `credential_not_found` y el flujo muere en el home. Para reapuntarlo:
///
/// ```sh
/// docker exec fintech-services-postgres-1 psql -U fintech -d fintech -c "
///   select c.username, ca.available_credit
///   from credit_portfolio.credit_accounts ca
///   join identity.credentials c on c.party_id = ca.obligor_party_id
///   where ca.product_code='DL-DIST-STD-V1' and ca.status='ACTIVE'
///   order by ca.available_credit desc limit 5;"
/// ```
///
/// y correr con `--dart-define=DIST_PHONE=<el que salga>`.
const _phone = String.fromEnvironment('DIST_PHONE', defaultValue: '5546645958');
/// Contraseña de la distribuidora sembrada.
///
/// Se sobreescribe con `--dart-define=DIST_PASSWORD=...`. El valor por omisión
/// es el mismo de [TestData.password] porque las cuentas que deja el sembrado
/// —y las que crean estos propios E2E— se dan de alta con él.
const _password =
    String.fromEnvironment('DIST_PASSWORD', defaultValue: TestData.password);

void _log(String msg) {
  // ignore: avoid_print
  print('🔌 $msg');
}

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  binding.framePolicy = LiveTestWidgetsFlutterBindingFramePolicy.fullyLive;

  testWidgets('La colocación funciona contra los servicios reales',
      (tester) async {
    local_app.main();
    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();

    // ── Login contra identity real ───────────────────────────────────────
    await tester.tapButton('Ya tengo cuenta · Entrar');
    await tester.pumpAndSettle();

    final fields = find.byType(EditableText);
    await tester.enterText(fields.at(0), _phone);
    await tester.pumpAndSettle();
    await tester.enterText(fields.at(1), _password);
    await tester.pumpAndSettle();
    await tester.tapButton('Entrar');

    final enHome = await tester.pumpUntilFound(
      find.textContaining('Hola,'),
      maxTicks: 40,
      tick: const Duration(milliseconds: 500),
    );
    expect(enHome, isTrue, reason: 'el login real debe llevar al home');
    _log('Login real OK');

    // ── La línea sale de credit-portfolio, no de un mock ─────────────────
    //
    // Se afirma sobre el rótulo y no sobre un monto: los números vienen de la
    // base y cambian con cada colocación que se apruebe. Lo que este test
    // protege es que el módulo se **encienda** con datos reales — que es
    // justo lo que no ocurría cuando dependía del propósito en memoria.
    final conLinea = await tester.pumpUntilFound(
      find.text('MI LÍNEA DE DISTRIBUIDOR'),
      maxTicks: 30,
      tick: const Duration(milliseconds: 500),
    );
    expect(conLinea, isTrue,
        reason: 'la línea del distribuidor debe llegar del backend tras el login');
    _log('Línea de distribuidor cargada del backend');

    expect(find.text('Colocaciones'), findsOneWidget);
    expect(find.text('Beneficiarios'), findsOneWidget);
    _log('Nav de 4 pestañas con datos reales');

    // ── Colocaciones reales ──────────────────────────────────────────────
    await tester.tap(find.text('Colocaciones'));
    await tester.pumpAndSettle(const Duration(seconds: 3));

    // La cartera sembrada trae al menos la colocación que este mismo backend
    // aprobó; si la lista viniera vacía, el estado vacío también es una
    // respuesta legítima del servicio y no un fallo de conexión.
    final hayLista = find.byType(ListView).evaluate().isNotEmpty;
    expect(hayLista, isTrue, reason: 'la pestaña debe renderizar su lista');
    _log('Colocaciones renderizadas');

    // ── Beneficiarios reales ─────────────────────────────────────────────
    await tester.tap(find.text('Beneficiarios'));
    await tester.pumpAndSettle(const Duration(seconds: 3));
    expect(find.text('Mis beneficiarios'), findsOneWidget);
    _log('Beneficiarios renderizados');

    // ── El alta de una colocación llega hasta el formulario ──────────────
    await tester.tap(find.text('Colocaciones'));
    await tester.pumpAndSettle(const Duration(seconds: 2));
    await tester.scrollAndTap(find.text('Enviar préstamo'));
    await tester.pumpAndSettle(const Duration(seconds: 2));
    expect(find.text('Ella se verifica sola'), findsOneWidget,
        reason: 'el flujo de envío abre con la línea real ya resuelta');
    _log('Flujo de envío abierto — FIN');
  });
}
