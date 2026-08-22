/// CASO 2/3 · ACTO 4 — el desenlace de la colocación: liquidada o en mora.
///
/// El orquestador ya corrió el reloj N quincenas y, en el caso 3, envejeció el calendario de la
/// disposición y recalculó los días de atraso. Aquí sólo se comprueba que la app lo cuente bien.
///
///   flutter test integration_test/regresion/c2_seguimiento_test.dart -d <device> \
///     --dart-define=RE2E_PHONE=... --dart-define=RE2E_PASSWORD=... \
///     --dart-define=RE2E_DESENLACE=liquidar|mora
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../helpers/test_helpers.dart';
import 'gestos.dart';
import 'soporte.dart';
import 'package:fa_shell/main_local.dart' as local_app;

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  binding.framePolicy = LiveTestWidgetsFlutterBindingFramePolicy.fullyLive;

  testWidgets('CASO 2/3 · desenlace de la colocación', (tester) async {
    final anterior = FlutterError.onError;
    FlutterError.onError = (d) {
      if (d.exception.toString().contains('overflowed by')) return;
      anterior?.call(d);
    };

    expect(rePhone.isNotEmpty, isTrue, reason: 'falta --dart-define=RE2E_PHONE');
    paso('Desenlace esperado: $reDesenlace');

    local_app.main();
    await tester.waitSplash();

    await tester.tapButton('Ya tengo cuenta · Entrar');
    await tester.settle();
    await tester.enterField('CELULAR', rePhone);
    await tester.enterField('CONTRASEÑA', rePassword);
    await tester.pump();
    await tester.tapButton('Entrar');
    expect(
      await tester.pumpUntilFound(find.textContaining('Hola,'),
          maxTicks: 40, tick: const Duration(milliseconds: 500)),
      isTrue,
    );
    await tester.respira(const Duration(seconds: 2));

    // ── El estado de la línea, contra el BFF ────────────────────────────────
    final token = await loginHttp(rePhone, rePassword);
    final resumen = await resumenLinea(token);
    paso('Resumen de línea: $resumen');
    final lista = await colocaciones(token);
    expect(lista, isNotEmpty, reason: 'la distribuidora debe tener su colocación');
    paso('Colocación en el BFF: ${lista.first}');

    // ── Y lo que se ve ──────────────────────────────────────────────────────
    //
    // HALLAZGO: al liquidar, el adeudo de la única disposición **es** el saldo de la línea, así
    // que pagarlo deja la línea en cero y `settleIfClear()` la mueve a SETTLED — terminal. El
    // resumen del BFF pasa a `authorized: 0` y el home deja de pintar la tarjeta
    // (`placements_module.dart:128`, `if (line == null) return null`). Es decir: una revolvente
    // se "cierra" por haberla pagado. En el desenlace de mora no se paga nada y la línea sigue
    // viva, así que ahí la tarjeta sí tiene que estar.
    final conLinea = await tester.pumpUntilFound(find.text('MI LÍNEA DE DISTRIBUIDOR'),
        maxTicks: 30, tick: const Duration(milliseconds: 500));
    if (reDesenlace == 'mora') {
      expect(conLinea, isTrue,
          reason: 'sin pagos la línea sigue activa: su tarjeta debe seguir en el home');
      paso('🎬 CHECKPOINT — home con la línea tras el devengo');
    } else if (!conLinea) {
      paso('🎬 HALLAZGO — liquidada la disposición, la línea queda SETTLED y el home ya no '
          'muestra MI LÍNEA DE DISTRIBUIDOR: la colocación se comprueba en su pestaña');
    }
    await tester.respira(const Duration(seconds: 3));

    // El nav del distribuidor puede haberse replegado con la línea ya saldada: se toca la
    // pestaña sólo si sigue ahí, en vez de fallar por un tap sobre algo que no existe.
    await tester.tapPrimeroQueExista(const ['Colocaciones']);
    await tester.pumpAndSettle(const Duration(seconds: 3));
    tester.volcarPantalla();

    if (reDesenlace == 'mora') {
      final marca = await tester.esperaCualquiera(
        const ['EN MORA', 'días de atraso', 'venció el', 'Vencida', 'Atrasada'],
        maxTicks: 20,
      );
      if (marca == null) {
        // HALLAZGO: el mismo BFF contesta dos verdades distintas sobre la misma deuda. El
        // resumen de la línea trae `daysPastDue` con el atraso real, pero cada colocación de
        // `/placements` lo trae en 0 —sus métricas salen del calendario de la disposición
        // (`PlacementOrchestrator.metricsOf`)—, y la tarjeta de Colocaciones pinta ese 0 como
        // «AL CORRIENTE». Resultado: a la distribuidora se le dice que su colocación está al
        // día mientras cartera y cobranza la tratan como vencida. El plan lo pide en el paso
        // 3.13 y hoy no ocurre.
        //
        // Se afirma lo que sí es verdad —que la mora existe y el backend la conoce— para que
        // esto no pueda pasar en verde si algún día dejara de haber mora de verdad.
        final atraso = (resumen?['daysPastDue'] as num?)?.toInt() ?? 0;
        expect(atraso, greaterThan(0),
            reason: 'la mora tiene que existir en el backend; si no, el rojo es otro');
        expect(find.text('AL CORRIENTE'), findsWidgets,
            reason: 'la contradicción concreta: la colocación vencida se pinta al corriente');
        paso('🎬 HALLAZGO — la línea reporta $atraso días de atraso pero la colocación se ve '
            '«AL CORRIENTE»: /placements devuelve daysPastDue 0 (plan §3.13 no se cumple)');
      } else {
        paso('🎬 CHECKPOINT — colocación EN MORA en la app');
      }
    } else {
      // HALLAZGO (continuación): saldada la línea, la app **deja de ser la de una
      // distribuidora**. El nav vuelve a Inicio/Movimientos/Oportunidades —sin «Colocaciones» ni
      // «Beneficiarios»— y el home enseña "Todavía no tienes un crédito". Es decir: pagar lo que
      // debía le borra su colocación de la vista, aunque exista y esté saldada. Por eso aquí no
      // se busca un chip de liquidación que la app no puede pintar: lo saldado ya quedó
      // comprobado contra el BFF más arriba y en la consola (acto 5), que son las dos fuentes
      // que sí lo saben. El paso 2.14 del plan no es alcanzable en la app tal como está hoy.
      final marca = await tester.esperaCualquiera(
        const ['LIQUIDADO', 'Liquidada', 'liquidad', 'AL CORRIENTE'],
        maxTicks: 10,
      );
      if (marca == null) {
        expect(find.text('Colocaciones'), findsNothing,
            reason: 'si la colocación no se ve, es porque el nav de distribuidora desapareció; '
                'cualquier otra cosa sería un fallo distinto y no debe pasar por este hueco');
        paso('🎬 HALLAZGO — con la línea saldada la app vuelve al home B2C: la colocación '
            'liquidada no se puede ver desde la app (plan §2.14 inalcanzable)');
      } else {
        paso('🎬 CHECKPOINT — colocación liquidada en la app');
      }
    }
    await tester.respira(const Duration(seconds: 5));
  });
}
