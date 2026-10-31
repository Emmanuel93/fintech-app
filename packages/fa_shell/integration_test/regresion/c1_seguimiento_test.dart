/// CASO 1 · ACTO 3 — el crédito ya activo: avance tras devengar quincenas y liquidación.
///
/// Antes de este acto el orquestador ya: (1) aprobó la solicitud desde la consola con un
/// analista de verdad, (2) presentó/aceptó/firmó el contrato por API —la app todavía no tiene
/// camino para retomar una oferta después de una aprobación manual, ver PLAN §4— y
/// (3) corrió el reloj N quincenas.
///
/// Aquí se comprueba lo único que le toca a la app: que **se vea**, que el avance del plan se
/// haya movido con el devengo, y que al pagar el adeudo total quede liquidado.
///
///   flutter test integration_test/regresion/c1_seguimiento_test.dart -d <device> \
///     --dart-define=RE2E_PHONE=... --dart-define=RE2E_PASSWORD=...
library;

import 'package:fa_credit/fa_credit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:provider/provider.dart';

import '../helpers/test_helpers.dart';
import 'gestos.dart';
import 'soporte.dart';
import 'package:fa_shell/main_local.dart' as local_app;

Future<void> _refrescarHome(WidgetTester tester) async {
  // El gesto sobre el RefreshIndicator es inestable justo después de una llamada HTTP sin pump
  // intermedio ("Bad state: No element"). Recargar el provider hace lo mismo sin la carrera.
  //
  // Hay que recargar **las dos** cosas: la tarjeta del home se pinta desde `accounts` en cuanto
  // esa lista tiene algo, y sólo cae a `credit` si está vacía (credit_module.dart:212-222).
  // Refrescando sólo `load()` la tarjeta seguía mostrando el objeto viejo —saldo y «AL
  // CORRIENTE» de antes del pago— aunque el backend ya reportara SETTLED con totalDebt 0.
  final ctx = tester.element(find.byType(Scaffold).first);
  final provider = ctx.read<CreditProvider>();
  await provider.load();
  await provider.loadAccounts();
  await tester.pumpAndSettle();
}

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  binding.framePolicy = LiveTestWidgetsFlutterBindingFramePolicy.fullyLive;

  testWidgets('CASO 1 · crédito activo, avance del devengo y liquidación',
      (tester) async {
    final anterior = FlutterError.onError;
    FlutterError.onError = (d) {
      if (d.exception.toString().contains('overflowed by')) return;
      anterior?.call(d);
    };

    expect(rePhone.isNotEmpty, isTrue,
        reason: 'este acto necesita --dart-define=RE2E_PHONE');

    local_app.main();
    await tester.waitSplash();

    // ── Login ───────────────────────────────────────────────────────────────
    await tester.tapButton('Ya tengo cuenta · Entrar');
    await tester.settle();
    await tester.enterField('CELULAR', rePhone);
    await tester.enterField('CONTRASEÑA', rePassword);
    await tester.pump();
    await tester.tapButton('Entrar');
    final enHome = await tester.pumpUntilFound(find.textContaining('Hola,'),
        maxTicks: 40, tick: const Duration(milliseconds: 500));
    expect(enHome, isTrue, reason: 'el login real debe llevar al home');
    paso('🎬 CHECKPOINT — home autenticado');
    await tester.respira(const Duration(seconds: 3));

    // ── El crédito, ya activo ───────────────────────────────────────────────
    tester.volcarPantalla();
    final conCredito = await tester.esperaCualquiera(
      const ['AL CORRIENTE', 'EN MORA', 'PAGO ', 'Saldo pendiente'],
      maxTicks: 40,
    );
    expect(conCredito, isNotNull,
        reason: 'tras la firma el home debe mostrar el crédito, no el estado vacío');
    expect(find.text('Tu solicitud está en revisión'), findsNothing,
        reason: 'ya hay crédito: el estado de revisión no debe seguir ahí');
    paso('🎬 CHECKPOINT — crédito activo en el home');
    await tester.respira(const Duration(seconds: 4));

    // ── El devengo se movió: se comprueba contra el BFF, no contra la pantalla ──
    final token = await loginHttp(rePhone, rePassword);
    final cuenta = await cuentaDeCredito(token);
    expect(cuenta, isNotNull, reason: 'el BFF debe devolver la cuenta activa');
    final interes = (cuenta!['accruedInterestBalance'] as num?)?.toDouble() ?? 0;
    final deuda = (cuenta['totalDebt'] as num?)?.toDouble() ?? 0;
    paso('Interés devengado: $interes · adeudo total: $deuda · estatus ${cuenta['status']}');
    expect(interes, greaterThan(0),
        reason: 'las quincenas devengadas deben haber generado interés');
    expect(deuda, greaterThan(0));

    await _refrescarHome(tester);
    paso('🎬 CHECKPOINT — avance del plan tras las quincenas devengadas');
    await tester.respira(const Duration(seconds: 4));

    if (reDesenlace == 'mora') {
      final marca = await tester.esperaCualquiera(const ['EN MORA', 'venció el'], maxTicks: 30);
      tester.volcarPantalla();
      expect(marca, isNotNull, reason: 'con cuotas vencidas la app debe marcar el atraso');
      paso('🎬 CHECKPOINT — el crédito se ve EN MORA');
      await tester.respira(const Duration(seconds: 4));
      return;
    }

    // ── Liquidación ─────────────────────────────────────────────────────────
    // Por el mismo canal que usa la app (`POST /credit/payment` del BFF), no contra el servicio
    // de dominio: si el cobro se rompe en el canal, esto tiene que enterarse.
    // Se paga cuando el devengo terminó de llegar, no a mitad de la fila (ver `adeudoEstable`).
    final pagado = await liquidar(token);
    expect(pagado, greaterThanOrEqualTo(deuda - 0.01),
        reason: 'se paga por lo menos lo que se debía al leer la cuenta');

    // El cierre de la cuenta es asíncrono: se espera a que cartera lo aplique.
    String? estatus;
    for (var i = 0; i < 15 && estatus != 'SETTLED'; i++) {
      estatus = (await cuentaDeCredito(token))?['status'] as String?;
      if (estatus != 'SETTLED') await Future<void>.delayed(const Duration(seconds: 2));
    }
    expect(estatus, 'SETTLED',
        reason: 'pagado el adeudo total, la cuenta debe quedar SETTLED');
    paso('Cuenta liquidada en el backend');

    await _refrescarHome(tester);
    tester.volcarPantalla();
    final liquidado = await tester.esperaCualquiera(
      const ['LIQUIDADO', 'Liquidaste', 'liquidado'],
      maxTicks: 30,
    );
    expect(liquidado, isNotNull, reason: 'la app debe reflejar la liquidación');
    paso('🎬 CHECKPOINT — crédito liquidado, visible en la app');
    await tester.respira(const Duration(seconds: 5));
  });
}
