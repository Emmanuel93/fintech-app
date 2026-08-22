/// Journey de demostración — otorgamiento del crédito, devengo y notificaciones.
///
/// Recorre el camino completo en el flavor mock y se detiene lo suficiente en
/// cada pantalla como para que la grabación se pueda ver:
///
///   welcome → alta (celular → privacidad → OTP → documentos → datos → contraseña)
///   → home **sin créditos** → oportunidades → configurador → buró → análisis
///   → aprobado → resumen → firma → desembolso
///   → home **con crédito**: el saldo devenga entre refrescos
///   → notificaciones: llegan los avisos de lo que acaba de pasar
///
/// El mock devenga interés con un reloj acelerado (un segundo real ≈ un día),
/// así que el saldo pendiente sube de forma visible al refrescar el home. Es
/// comportamiento exclusivo del flavor mock.
library;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:fa_credit/fa_credit.dart';
import 'package:fa_notifications/fa_notifications.dart';
import 'package:fa_design_system/fa_design_system.dart';
import 'package:fa_core/fa_core.dart';

import 'helpers/test_helpers.dart';
import 'helpers/onboarding_steps.dart';
import 'helpers/image_picker_mock.dart';
import 'package:fa_shell/main.dart' as mock_app;

/// Pausa para que la grabación muestre la pantalla antes de seguir.
Future<void> _beat(WidgetTester tester,
    [Duration d = const Duration(milliseconds: 1400)]) async {
  await tester.pump(d);
}

void _log(String msg) {
  // ignore: avoid_print
  print('🎬 $msg');
}

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  binding.framePolicy = LiveTestWidgetsFlutterBindingFramePolicy.fullyLive;

  setUpAll(() async {
    await FakeImagePickerPlatform.setup();
    // Cada corrida parte de cero: sin crédito y sin avisos previos.
    CreditMockInterceptor.reset();
    NotificationsMockInterceptor.reset();
  });

  testWidgets('Journey de otorgamiento: devengo del saldo y notificaciones',
      (tester) async {
    mock_app.main();
    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();

    // ── Alta ─────────────────────────────────────────────────────────────
    _log('Bienvenida');
    await _beat(tester);
    await tester.goToIdentityStep();
    _log('Identidad — documentos');
    await _beat(tester);

    await tester.captureDocumentsOnly();
    expect(find.text('EXTRAÍDO'), findsOneWidget,
        reason: 'el OCR debe haber leído el INE');
    _log('OCR extraído');
    await _beat(tester);

    await tester.tapButton('Leer mis documentos');
    await tester.pumpAndSettle();
    await tester.fillIdentityData();
    await tester.tapButton('Todo está correcto');
    await tester.pumpAndSettle();
    // "Crear cuenta" lanza el análisis del alta: creando cuenta → buró →
    // círculo → capacidad de pago. De ahí salen las oportunidades.
    _log('Análisis del alta');
    await tester.completePasswordStep();
    _log('Oportunidades — resultado del análisis');
    await _beat(tester, const Duration(seconds: 2));

    // Con "Para mí" sólo se evalúan productos de persona, y todos salen
    // aprobados: no hay sección de comité. El caso del distribuidor —que sí la
    // tiene— lo cubre create_account_e2e_test.
    expect(find.text('APROBADAS PARA TI'), findsOneWidget);
    expect(find.text('PUEDES SOLICITARLAS'), findsNothing,
        reason: 'los productos de negocio no aplican a uso propio');
    await _beat(tester, const Duration(seconds: 2));

    // Se toma un producto a plazo: es el que amortiza y el que deja ver el
    // devengo moverse en el home.
    await tester.scrollAndTap(find.text('Préstamo personal'));
    await tester.pumpAndSettle(const Duration(seconds: 1));
    _log('Oportunidades — préstamo a plazo');
    await _beat(tester, const Duration(seconds: 2));

    final continuar = find.textContaining('Continuar con');
    expect(continuar, findsOneWidget);
    await tester.tap(continuar);
    await tester.pumpAndSettle(const Duration(seconds: 2));

    expect(find.text('Arma tu préstamo'), findsOneWidget,
        reason: 'un producto a plazo sí abre el configurador');
    // El compromiso no es sólo la cuota: cuántas son y cuándo empieza.
    expect(find.textContaining('el primero el'), findsOneWidget,
        reason: 'el resumen debe decir cuántos pagos y cuándo vence el primero');
    _log('Configurador — cuota, plazos y primera fecha');
    await _beat(tester, const Duration(seconds: 2));

    // La tabla de amortización se puede leer antes de aceptarla.
    await tester.scrollAndTap(find.text('Ver tabla de amortización'));
    await tester.pumpAndSettle(const Duration(seconds: 3));
    expect(find.text('Tabla de amortización'), findsOneWidget);
    _log('Tabla de amortización');
    await _beat(tester, const Duration(seconds: 3));
    await tester.tap(find.bySemanticsLabel('Cerrar'));
    await tester.pumpAndSettle(const Duration(seconds: 2));

    // "Revisar solicitud" resuelve: ya no manda a autorizar buró otra vez.
    await tester.scrollAndTap(find.text('Revisar solicitud'));
    await tester.pump(const Duration(milliseconds: 600));
    expect(find.textContaining('Consultando buró'), findsNothing,
        reason: 'buró y círculo ya se consultaron en el alta');

    // ── Análisis ─────────────────────────────────────────────────────────
    //
    // Ojo: de aquí a "Aprobado" NO se puede usar `pumpAndSettle`. El anillo
    // `kr-spin` del análisis y el punto que late en el badge de aprobado son
    // animaciones en bucle: pumpAndSettle esperaría a que el árbol quede
    // quieto y eso nunca ocurre. Se avanza con `pump` acotado.
    _log('Resolución — sin reconsultar SIC');
    // Se espera por algo del **encabezado** de la pantalla de aprobado: el CTA
    // vive al final de un SliverList y no existe en el árbol hasta que se hace
    // scroll, así que no sirve como señal de llegada.
    final aprobado = await tester.pumpUntilFound(
      find.text('SÍ CUMPLES LOS CRITERIOS'),
      maxTicks: 60,
      tick: const Duration(milliseconds: 500),
    );
    expect(aprobado, isTrue, reason: 'el análisis debe terminar en aprobado');

    // ── Aprobado → firma → desembolso ────────────────────────────────────
    _log('Aprobado');
    await tester.pump(const Duration(seconds: 2));
    await tester.scrollAndTap(find.text('Aceptar y continuar'));
    // El contrato ya no tiene animaciones en bucle.
    await tester.pumpAndSettle(const Duration(seconds: 3));

    _log('Resumen y destino del depósito');
    // Si el cliente ya tiene CLABE registrada (la wallet la trae), el resumen
    // abre en "Ya tengo cuenta" y no hay nada que escribir.
    const clabeLabel = 'CLABE interbancaria (18 dígitos)';
    if (find.byKey(const ValueKey('ds-field:$clabeLabel')).evaluate().isNotEmpty) {
      await tester.enterField(clabeLabel, '012180000000000000');
      await tester.pumpAndSettle();
    } else {
      _log('Cuenta ya registrada — sin captura de CLABE');
    }
    await tester.scrollAndTap(find.textContaining('Acepto el contrato de crédito'));
    await tester.pumpAndSettle();
    await _beat(tester);
    await tester.scrollAndTap(find.text('Leer y firmar contrato'));
    await tester.pumpAndSettle(const Duration(seconds: 3));

    // ── Contrato en PDF + firma autógrafa ────────────────────────────────
    _log('Contrato — lectura del PDF');
    expect(find.text('Tu contrato'), findsOneWidget);
    // El clausulado debe llevar al titular real, no el nombre de respaldo.
    expect(AppSession.instance.holderName.isNotEmpty, isTrue,
        reason: 'el alta debe dejar al titular en la sesión para el contrato');
    expect(AppSession.instance.holderCurp.isNotEmpty, isTrue);
    await _beat(tester, const Duration(seconds: 3));

    // Se firma con el dedo sobre el pad; el trazo se estampa en el documento.
    final pad = find.byType(DsSignaturePad);
    expect(pad, findsOneWidget, reason: 'debe haber pad de firma');
    final box = tester.getRect(pad);
    final gesture = await tester.startGesture(
        Offset(box.left + box.width * 0.25, box.center.dy));
    for (final dx in [0.35, 0.45, 0.55, 0.65, 0.75]) {
      await gesture.moveTo(Offset(
          box.left + box.width * dx,
          box.center.dy + (dx * 100 % 30) - 15));
      await tester.pump(const Duration(milliseconds: 60));
    }
    await gesture.up();
    await tester.pumpAndSettle();
    _log('Firma autógrafa trazada');
    await _beat(tester, const Duration(seconds: 2));

    await tester.tapButton('Estampar firma y continuar');
    await tester.pumpAndSettle(const Duration(seconds: 3));

    _log('Firma electrónica');
    // Las cajas del diseño sobre el teclado del dispositivo: no hay teclado
    // dibujado en ninguna de las dos pantallas de código del journey.
    expect(find.byType(DsPinInput), findsOneWidget,
        reason: 'la firma usa el teclado del dispositivo, sin teclado dibujado');
    await tester.enterPinCode('123456');
    await tester.pumpAndSettle(const Duration(seconds: 3));

    _log('Desembolso');
    await _beat(tester, const Duration(seconds: 3));
    await tester.tapButton('Ir a mi crédito');
    await tester.pumpAndSettle(const Duration(seconds: 3));

    // ── Home con crédito: el devengo ─────────────────────────────────────
    expect(find.text('CRÉDITO ACTIVO'), findsOneWidget,
        reason: 'el home ya debe mostrar el crédito otorgado');
    _log('Home — crédito activo');
    await _beat(tester, const Duration(seconds: 2));

    final saldoInicial = _saldoPendiente(tester);
    _log('Saldo pendiente inicial: $saldoInicial');

    // El mock devenga con reloj acelerado: se espera y se refresca para que el
    // saldo suba de forma observable.
    for (var i = 0; i < 3; i++) {
      await tester.pump(const Duration(seconds: 3));
      await tester.fling(
          find.byType(RefreshIndicator), const Offset(0, 320), 1000);
      await tester.pumpAndSettle(const Duration(seconds: 3));
      _log('Refresco ${i + 1} — saldo: ${_saldoPendiente(tester)}');
      await _beat(tester);
    }

    final saldoFinal = _saldoPendiente(tester);
    expect(saldoFinal, isNot(saldoInicial),
        reason: 'el saldo pendiente debe devengar interés entre refrescos');
    _log('Saldo devengado: $saldoInicial → $saldoFinal');

    // ── Pagos: del primero hasta liquidar ────────────────────────────────
    //
    // El punto de la demo es ver el contador avanzar y la barra llenarse: se
    // paga hasta que el crédito queda liquidado, no una vez.
    expect(find.textContaining('PAGO 0 DE'), findsOneWidget,
        reason: 'arranca sin pagos hechos');
    expect(find.textContaining('Tu próximo pago de'), findsOneWidget,
        reason: 'la tarjeta debe decir cuánto y cuándo vence');
    expect(find.text('AL CORRIENTE'), findsOneWidget,
        reason: 'recién otorgado, sin nada vencido');
    await _beat(tester, const Duration(seconds: 2));

    // ── Devengar sin pagar: el crédito cae en mora ────────────────────────
    //
    // Es el caso que el estado de cuenta llama "en mora" y que la app no debe
    // disfrazar de "al corriente". Se usa el endpoint de soporte —el mismo que
    // expone el BFF— para no esperar 30 días en tiempo real.
    _log('Devengando sin pagar hasta pasar el vencimiento');
    await _soporte(
      tester,
      '/internal/test-support/accounts/acc-1/installments/1/shift-due-date',
      query: {'daysFromToday': -6},
    );
    await _refrescarHome(tester);

    expect(find.textContaining('EN MORA'), findsOneWidget,
        reason: 'pasado el vencimiento sin pagar, no está al corriente');
    expect(find.text('AL CORRIENTE'), findsNothing);
    expect(find.textContaining('venció el'), findsOneWidget,
        reason: 'se dice que venció, no "tu próximo pago"');
    _log('Home — EN MORA');
    await _beat(tester, const Duration(seconds: 3));

    // El corte genera el aviso de mora, con el número de pago y los días.
    await _soporte(tester, '/internal/test-support/run-installment-due-job');
    await _refrescarHome(tester);

    // Ojo: aquí tampoco se puede usar `pumpAndSettle`. Mientras la tarjeta se
    // recarga, su barra de avance queda indeterminada —animación en bucle— y
    // el árbol nunca se queda quieto. Se avanza con `pump` acotado.
    var pagos = 0;
    while (pagos < 14) {
      // Volver de notificaciones deja el home repintándose: se le da margen
      // antes de concluir que ya no hay nada que pagar.
      final hayCta = await tester.pumpUntilFound(
        find.textContaining('Pagar \$'),
        maxTicks: 12,
        tick: const Duration(milliseconds: 300),
      );
      if (!hayCta) break;
      final cta = find.textContaining('Pagar \$');

      await tester.scrollAndTap(cta.first);
      await tester.pump(const Duration(milliseconds: 700));

      // La hoja dice qué se va a cobrar antes de cobrarlo.
      final confirmar = find.textContaining('Confirmar pago de');
      if (confirmar.evaluate().isEmpty) {
        fail('La hoja de confirmación no abrió en el pago ${pagos + 1}');
      }
      if (pagos == 0) {
        expect(find.text('Confirma tu pago'), findsOneWidget);
        _log('Confirmación de pago');
        await _beat(tester, const Duration(seconds: 2));
      }

      await tester.tap(confirmar.first);
      // El cobro, la relectura del BFF y el repintado de la tarjeta.
      for (var i = 0; i < 8; i++) {
        await tester.pump(const Duration(milliseconds: 400));
      }
      pagos++;
      _log('Pago $pagos aplicado — ${_avancePagos(tester)}');

      // Cada pago tiene que llegar a notificaciones: aplicar el cobro sin
      // avisar deja al usuario sin constancia de que su dinero entró.
      final aviso = await _buscarAviso(tester, 'Recibimos tu pago de');
      expect(aviso, isTrue, reason: 'el pago $pagos no generó su notificación');
      _log('  ✓ notificación del pago $pagos confirmada');

      if (pagos <= 2) await _beat(tester, const Duration(seconds: 2));
    }

    // Curada la mora al pagar.
    expect(find.textContaining('EN MORA'), findsNothing,
        reason: 'pagar pone al corriente');

    expect(pagos, greaterThan(1), reason: 'debe poder pagarse más de una vez');
    // Lo dice el chip de estado y la franja de avance: liquidado se anuncia
    // en los dos sitios donde antes decía "al corriente" y "vence".
    expect(find.text('LIQUIDADO'), findsWidgets,
        reason: 'pagando todas las mensualidades el crédito queda liquidado');
    _log('Crédito liquidado en $pagos pagos');
    await _beat(tester, const Duration(seconds: 3));

    // ── Notificaciones ───────────────────────────────────────────────────
    await tester.tap(find.bySemanticsLabel(RegExp('Notificaciones')));
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 400));
    }

    expect(find.text('Notificaciones'), findsOneWidget);
    _log('Notificaciones');
    await _beat(tester, const Duration(seconds: 2));

    // Los avisos de lo que acaba de pasar en esta sesión.
    expect(find.text('¡Liquidaste tu crédito!'), findsOneWidget,
        reason: 'liquidar merece su propio aviso');
    await _beat(tester, const Duration(seconds: 2));

    // El resto del historial vive más abajo: la lista creció con cada pago.
    for (final titulo in const [
      'Tu buen historial abre otra línea',
      'Tu dinero va en camino',
      'Tu contrato ya está firmado',
    ]) {
      final aviso = find.text(titulo);
      await tester.scrollUntilVisible(aviso, 220,
          scrollable: find.byType(Scrollable).first);
      await tester.pumpAndSettle();
      expect(aviso, findsOneWidget, reason: 'falta el aviso "$titulo"');
      _log('Aviso: $titulo');
    }
    await _beat(tester, const Duration(seconds: 2));

    // Filtro por categoría.
    await tester.tap(find.text('Mi crédito'));
    await tester.pumpAndSettle();
    _log('Notificaciones — filtro "Mi crédito"');
    await _beat(tester, const Duration(seconds: 2));

    await tester.tap(find.text('Seguridad'));
    await tester.pumpAndSettle();
    _log('Notificaciones — filtro "Seguridad"');
    await _beat(tester, const Duration(seconds: 2));

    await tester.tap(find.text('Todas'));
    await tester.pumpAndSettle();
    await _beat(tester, const Duration(seconds: 2));

    _log('✅ Journey completo');
  });
}

/// Dispara un endpoint de soporte por el mismo cliente HTTP de la app.
///
/// Son los que expone el BFF (`TestSupportProxyController`) y que el mock
/// espeja, así que este guion sirve igual conectado a fintech-services: correr
/// el devengo, disparar el corte o mover un vencimiento sin esperar en tiempo
/// real.
Future<void> _soporte(WidgetTester tester, String path,
    {Map<String, dynamic>? query}) async {
  final context = tester.element(find.byType(Scaffold).first);
  final ok = await Provider.of<CreditProvider>(context, listen: false)
      .testSupport(path, query: query);
  // Si el soporte no responde, el resto del guion afirmaría sobre un estado
  // que nadie provocó: mejor fallar aquí, donde se ve la causa.
  expect(ok, isTrue, reason: 'el endpoint de soporte no respondió: $path');
  await tester.pump(const Duration(milliseconds: 400));
}

/// Refresca el home con el gesto real de pull-to-refresh.
///
/// Tiene que asentarse: el `RefreshIndicator` dispara su `onRefresh` cuando la
/// animación del gesto termina, así que con `pump` acotado el gesto se ve pero
/// no recarga nada — y la pantalla sigue mostrando lo de antes.
Future<void> _refrescarHome(WidgetTester tester) async {
  // El gesto, para que se vea en la grabación...
  await tester.fling(find.byType(RefreshIndicator), const Offset(0, 320), 1000);
  await tester.pumpAndSettle(const Duration(seconds: 2));
  // ...y la recarga explícita, porque el `RefreshIndicator` sólo dispara su
  // `onRefresh` si el gesto arranca con la lista pegada arriba, y una prueba
  // no puede depender de dónde quedó el scroll.
  final context = tester.element(find.byType(Scaffold).first);
  await Provider.of<CreditProvider>(context, listen: false).load();
  await tester.pumpAndSettle(const Duration(seconds: 1));
}

/// Abre notificaciones, busca el aviso y regresa al home.
Future<bool> _buscarAviso(WidgetTester tester, String titulo) async {
  await tester.tap(find.bySemanticsLabel(RegExp('Notificaciones')));
  for (var i = 0; i < 8; i++) {
    await tester.pump(const Duration(milliseconds: 350));
  }
  final encontrado = find.textContaining(titulo).evaluate().isNotEmpty;
  // La pantalla marca su botón de regreso con semántica, que es lo estable:
  // el ícono concreto cambió una vez y dejó la prueba atrapada aquí dentro.
  final volver = find.bySemanticsLabel('Volver');
  if (volver.evaluate().isNotEmpty) {
    await tester.tap(volver.first, warnIfMissed: false);
    // De vuelta al home y esperando a que la tarjeta esté montada otra vez.
    await tester.pumpUntilFound(
      find.textContaining('PAGO '),
      maxTicks: 14,
      tick: const Duration(milliseconds: 300),
    );
  }
  return encontrado;
}

/// "PAGO 3 DE 12" tal como lo muestra la tarjeta del home.
String _avancePagos(WidgetTester tester) {
  final match = find
      .byType(Text)
      .evaluate()
      .map((e) => (e.widget as Text).data)
      .whereType<String>()
      .where((t) => t.startsWith('PAGO ') || t == 'LIQUIDADO');
  return match.isEmpty ? '—' : match.first;
}

/// Lee el saldo pendiente que muestra la tarjeta de crédito del home.
String _saldoPendiente(WidgetTester tester) {
  final label = find.text('Saldo pendiente');
  if (label.evaluate().isEmpty) return '—';
  // El monto es el Text hermano, dentro de la misma Column.
  final column = find.ancestor(of: label, matching: find.byType(Column)).first;
  final texts = find
      .descendant(of: column, matching: find.byType(Text))
      .evaluate()
      .map((e) => (e.widget as Text).data)
      .whereType<String>()
      .where((t) => t.startsWith('\$'))
      .toList();
  return texts.isEmpty ? '—' : texts.first;
}
