import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fa_design_system/fa_design_system.dart';

/// Utilidades compartidas para los tests de integración E2E.
extension TestExtensions on WidgetTester {
  // ── Pump helpers ─────────────────────────────────────────────────────────

  /// Pump que evita colgar con Timer.periodic (e.g. el OTP screen).
  /// Avanza el reloj en ticks cortos hasta que el texto esperado aparezca
  /// o se agote el número de intentos.
  Future<bool> pumpUntilFound(
    Finder finder, {
    int maxTicks = 30,
    Duration tick = const Duration(milliseconds: 300),
  }) async {
    for (int i = 0; i < maxTicks; i++) {
      await pump(tick);
      if (finder.evaluate().isNotEmpty) return true;
    }
    return false;
  }

  /// Pump estándar + settle en pantallas sin Timer.periodic.
  Future<void> settle({Duration extra = const Duration(milliseconds: 300)}) async {
    await pump(extra);
    await pump(extra);
  }

  // ── Navegación ───────────────────────────────────────────────────────────

  /// Espera a que el splash termine (~2.5 s) y el router lleve al login.
  Future<void> waitSplash() async {
    await pump(const Duration(seconds: 3));
    await settle();
  }

  /// Toca un botón por su label de texto.
  ///
  /// Intenta hacer el widget visible con [ensureVisible] antes de tapear.
  /// Esto evita el warning "would not hit test" cuando el botón está al
  /// borde inferior de la pantalla (y > safe area).
  Future<void> tapButton(String label, {bool mustFind = true}) async {
    final btn = find.text(label);
    if (mustFind) {
      expect(btn, findsAtLeastNWidgets(1), reason: 'Botón "$label" no encontrado');
    }
    if (btn.evaluate().isEmpty) return;
    // Intentar hacer scroll hasta el widget si está off-screen
    try {
      await ensureVisible(btn.first);
      await pump(const Duration(milliseconds: 200));
    } catch (_) {
      // ensureVisible puede fallar en pantallas sin scroll — ignoramos
    }
    await tap(btn.first, warnIfMissed: false);
    await pump();
  }

  // ── Formularios ──────────────────────────────────────────────────────────

  /// Escribe en el EditableText descendiente del widget que contiene [label].
  ///
  /// Usa `showKeyboard` (focusNode.requestFocus() directo) en vez de `tap()`
  /// para enfocar el campo — igual que `enterOtp`. Evita los falsos
  /// "would not hit test" que aparecen con formularios largos donde el
  /// scroll deja al widget en una posición borde justo antes del tap
  /// (offset calculado en un frame, tap entregado en el siguiente).
  Future<void> enterField(String label, String value) async {
    final scrollable = find.byType(SingleChildScrollView);

    // Estrategia 1 — campos del design system Kredius, por su key estable.
    //
    // Va primero porque es la única que funciona cuando la etiqueta no se pinta
    // (`DsFormField(showLabel: false)`, como en la tarjeta de contacto del
    // alta, donde el rótulo visible es "NÚMERO CELULAR" en mayúsculas).
    // Tampoco se busca "la Column que contiene al label": ese finder queda
    // atado a una instancia de widget que desaparece en el siguiente rebuild y
    // revienta con "Bad state: No element" justo al escribir.
    Finder editable = find.descendant(
      of: find.byKey(ValueKey(dsFieldKey(label))),
      matching: find.byType(EditableText),
    );
    if (editable.evaluate().isNotEmpty && scrollable.evaluate().isNotEmpty) {
      try {
        await scrollUntilVisible(editable, 80, scrollable: scrollable.first);
        await pump(const Duration(milliseconds: 200));
      } catch (_) {}
    }

    if (editable.evaluate().isEmpty) {
      // Estrategias 2 y 3 — campos con la etiqueta dentro del
      // `InputDecoration` (`DsTextField` y los de Material).
      if (scrollable.evaluate().isNotEmpty) {
        try {
          await scrollUntilVisible(find.text(label), 80,
              scrollable: scrollable.first);
          await pump(const Duration(milliseconds: 200));
        } catch (_) {}
      }
      final labelWidget = find.text(label);
      if (labelWidget.evaluate().isEmpty) {
        fail('Campo "$label" no encontrado en pantalla');
      }
      editable =
          find.ancestor(of: labelWidget, matching: find.byType(EditableText));
      if (editable.evaluate().isEmpty) {
        final formField = find.ancestor(
            of: labelWidget, matching: find.byType(TextFormField));
        if (formField.evaluate().isNotEmpty) {
          editable = find.descendant(
              of: formField.first, matching: find.byType(EditableText));
        }
      }
    }

    if (editable.evaluate().isEmpty) {
      fail('Campo "$label": no se encontró el EditableText asociado');
    }

    await showKeyboard(editable.first);
    await pump(const Duration(milliseconds: 150));
    await enterText(editable.first, value);
    await pump(const Duration(milliseconds: 150));
  }

  /// Elige [option] en el selector cuya etiqueta es [label].
  ///
  /// Se localiza por la key del design system, no por "el primer selector que
  /// siga diciendo Seleccionar": después del prefill por OCR unos vienen
  /// llenos y otros no, y ese criterio posicional elige el selector equivocado.
  /// Si ya tiene valor, no hace nada.
  Future<void> selectDropdown(String label, String option) async {
    final scrollable = find.byType(SingleChildScrollView);
    if (scrollable.evaluate().isNotEmpty) {
      try {
        await scrollUntilVisible(find.text(label), 80,
            scrollable: scrollable.first);
        await pump(const Duration(milliseconds: 200));
      } catch (_) {}
    }

    final field = find.byKey(ValueKey(dsFieldKey(label)));
    if (field.evaluate().isEmpty) {
      fail('Selector "$label" no encontrado en pantalla');
    }
    // Ya tiene valor elegido → nada que hacer.
    final dropdown = state<FormFieldState<String>>(field);
    if (dropdown.value != null && dropdown.value!.isNotEmpty) return;

    try {
      await ensureVisible(field);
      await pump(const Duration(milliseconds: 200));
    } catch (_) {}
    await tap(field, warnIfMissed: false);
    await pump(const Duration(milliseconds: 600));

    // La opción se busca DENTRO de la hoja: detrás puede haber otro campo con el mismo texto
    // —el estado de nacimiento ya trae «Sinaloa» del OCR— y tocarlo no elige nada.
    Finder enLaHoja() => find.descendant(
        of: find.byType(Scrollbar), matching: find.text(option));

    // La lista es perezosa y sólo construye lo visible: Sinaloa es la #25 de 32. Si no está a la
    // vista se usa el buscador de la hoja, que es el arreglo que la hizo alcanzable.
    if (enLaHoja().evaluate().isEmpty) {
      final buscador = find.byType(TextField);
      if (buscador.evaluate().isNotEmpty) {
        await enterText(buscador.last, option);
        await pump(const Duration(milliseconds: 600));
      }
    }

    final item = enLaHoja().evaluate().isNotEmpty ? enLaHoja().first : find.text(option).last;
    if (item.evaluate().isEmpty) {
      fail('Opción "$option" no está en el selector "$label"');
    }
    await tap(item, warnIfMissed: false);
    await pump(const Duration(milliseconds: 600));
  }

  /// Teclea un código en las cajas de OTP.
  ///
  /// Las cajas son el diseño; debajo hay un campo real invisible que recibe el
  /// teclado del dispositivo (`DsPinInput`), para poder aprovechar el
  /// autorrelleno del SMS. El teclado dibujado del prototipo ya no existe.
  Future<void> enterPinCode(String code) async {
    final input = find.byType(DsPinInput);
    if (input.evaluate().isEmpty) {
      fail('No hay cajas de código (DsPinInput) para teclear "$code"');
    }
    final field =
        find.descendant(of: input, matching: find.byType(EditableText));
    await tap(field.first, warnIfMissed: false);
    await pump(const Duration(milliseconds: 200));
    await enterText(field.first, code);
    // El último dígito dispara la verificación tras ~420ms.
    await pump(const Duration(milliseconds: 900));
  }

  /// Ingresa los 6 dígitos del OTP y dispara la verificación.
  ///
  /// ## Por qué NO usar `enterText(field.at(i), digit)` directamente:
  ///
  /// En `LiveTestWidgetsFlutterBindingFramePolicy.fullyLive` (integration_test
  /// en iOS), `enterText` llama internamente a `showKeyboard(finder)` → `tap(finder)`.
  /// Ese re-tap puede restablecer la conexión de text input al mismo cliente que
  /// ya estaba, perdiéndose el cambio de foco que `_onDigitEntered` hizo al campo
  /// siguiente. El resultado: los dígitos van al campo 0 repetidamente.
  ///
  /// ## Solución:
  ///
  /// 1. `tap` solo el **primer campo** para establecer la conexión de text input.
  /// 2. Para cada dígito: `testTextInput.enterText(digit)` — actualiza el campo
  ///    que ACTUALMENTE tiene foco (que va avanzando por el auto-focus de DsOtpField).
  /// 3. Fallback explícito al botón "Verificar" si onCompleted no disparó.
  ///
  /// **No usa pumpAndSettle**: el `Timer.periodic` de la cuenta regresiva del
  /// OTP screen impide que pumpAndSettle se resuelva; usamos `pump(Duration)`.
  Future<void> enterOtp(String otp) async {
    assert(otp.length == 6, 'OTP debe tener 6 dígitos');

    // Estabilizar la pantalla y dejar que el teclado / animaciones terminen
    await pump(const Duration(milliseconds: 600));

    // Enfocar el primer campo con showKeyboard (llama focusNode.requestFocus()
    // directamente, sin generar un tap gesture que puede fallar cuando el teclado
    // iOS o una animación de transición cubre el widget).
    final firstField = find.byType(TextFormField).first;
    await showKeyboard(firstField);
    await pump(const Duration(milliseconds: 400));

    // Enviar cada dígito directamente al campo con foco actual.
    // _onDigitEntered mueve el foco al siguiente campo tras cada dígito.
    for (final digit in otp.split('')) {
      testTextInput.enterText(digit);
      // Tiempo para que setState(_currentValue) + requestFocus(next) se procesen
      await pump(const Duration(milliseconds: 350));
    }

    // Esperar que onCompleted → _verify() → HTTP (mock < 600ms, local < 1s)
    await pump(const Duration(milliseconds: 1000));

    // ── Fallback ─────────────────────────────────────────────────────────────
    // Si seguimos en la pantalla de OTP, el botón "Verificar" está visible.
    // Solo funciona si _code.length == 6 (onPressed != null).
    if (find.text('Verificar').evaluate().isNotEmpty) {
      await tap(find.text('Verificar').first);
      await pump(const Duration(milliseconds: 1000));
    }
  }

  /// Abre el date picker con el ícono de calendario y confirma la fecha
  /// actualmente seleccionada (acepta la pre-llenada o la del calendario).
  ///
  /// Usa pump(Duration) — NO pumpAndSettle — para evitar que animaciones
  /// internas del picker bloqueen los widgets que vienen después.
  Future<void> pickDate(int year, int month, int day) async {
    await tap(find.byIcon(Icons.calendar_today_outlined), warnIfMissed: false);
    // Dejar que el diálogo aparezca
    await pump(const Duration(milliseconds: 400));
    await pump(const Duration(milliseconds: 400));

    // Confirmar sin cambiar la fecha (OK en en-US, ACEPTAR en es-MX)
    for (final label in ['OK', 'Aceptar', 'ACEPTAR']) {
      final btn = find.text(label);
      if (btn.evaluate().isNotEmpty) {
        await tap(btn.last, warnIfMissed: false);
        // Esperar que cierre la animación del diálogo
        await pump(const Duration(milliseconds: 300));
        await pump(const Duration(milliseconds: 300));
        return;
      }
    }
    // Si el diálogo no abrió no hay nada que cerrar
  }

  /// Scroll hacia abajo en el primer SingleChildScrollView.
  Future<void> scrollDown({double amount = 300}) async {
    // Cae a cualquier Scrollable: no todas las pantallas usan
    // SingleChildScrollView — el aprobado y la contraoferta son CustomScrollView,
    // y con el finder específico el drag no hacía nada en silencio.
    var scrollable = find.byType(SingleChildScrollView);
    if (scrollable.evaluate().isEmpty) scrollable = find.byType(Scrollable);
    if (scrollable.evaluate().isEmpty) return;
    await drag(scrollable.first, Offset(0, -amount));
    await settle();
  }

  /// Arrastra hasta que [target] entre al viewport y lo toca.
  ///
  /// Necesario en las pantallas con slivers: sus hijos fuera de pantalla ni
  /// siquiera existen como Element, así que `find.text` no los ve hasta que se
  /// hace scroll de verdad.
  Future<void> scrollAndTap(Finder target, {double step = 250}) async {
    var scrollable = find.byType(SingleChildScrollView);
    if (scrollable.evaluate().isEmpty) scrollable = find.byType(Scrollable);
    if (scrollable.evaluate().isNotEmpty) {
      try {
        await scrollUntilVisible(target, step, scrollable: scrollable.first);
        await pump(const Duration(milliseconds: 250));
      } catch (_) {}
    }
    expect(target, findsAtLeastNWidgets(1),
        reason: 'no se encontró el objetivo ni haciendo scroll');
    await ensureVisible(target.first);
    await pump(const Duration(milliseconds: 200));
    await tap(target.first, warnIfMissed: false);
    await pump(const Duration(milliseconds: 300));
  }

  /// Encuentra [target] arrastrando un [Scrollable] real si hace falta.
  ///
  /// Cualquier lista/carrusel (incl. `ListView(children:)`, no solo
  /// `.builder`) solo monta como Element los items dentro de su viewport +
  /// cacheExtent — los que quedan fuera son invisibles para los finders sin
  /// importar cuánto se espere con `pumpUntilFound`. Mismo comportamiento ya
  /// visto en el menú de un `DropdownButtonFormField` con `menuMaxHeight`.
  /// Por defecto arrastra verticalmente hacia abajo; para un carrusel
  /// horizontal usar `delta: Offset(-300, 0)`.
  Future<bool> findScrolling(
    Finder target, {
    Finder? scrollable,
    Offset delta = const Offset(0, -300),
    int maxIteration = 30,
  }) async {
    if (target.evaluate().isNotEmpty) return true;
    try {
      await dragUntilVisible(
        target,
        scrollable ?? find.byType(Scrollable).first,
        delta,
        maxIteration: maxIteration,
      );
    } catch (_) {
      // Se agotó maxIteration sin encontrarlo — se resuelve con el chequeo
      // final de abajo, igual que si nunca hubiera hecho falta scroll.
    }
    await pump(const Duration(milliseconds: 300));
    return target.evaluate().isNotEmpty;
  }
}

/// Imprime en la consola de prueba el modo de backend detectado.
void printBackendMode(String mode) {
  // ignore: avoid_print
  print('\n╔════════════════════════════════════════╗');
  // ignore: avoid_print
  print('║  MODO: $mode');
  // ignore: avoid_print
  print('╚════════════════════════════════════════╝\n');
}
