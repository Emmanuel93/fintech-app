/// Gestos tolerantes para la regresión.
///
/// Un journey que cruza tres procesos no puede caerse porque una pantalla intermedia cambió de
/// CTA: el fallo diría "no encontré el botón" cuando lo que se está probando es si el analista
/// mueve la solicitud. Estos helpers separan lo que *debe* estar (y falla si no) de lo que
/// *puede* estar (y se salta en silencio, dejando rastro en el log).
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'soporte.dart';

extension GestosRegresion on WidgetTester {
  /// Toca la primera etiqueta de la lista que exista. Devuelve la que tocó, o `null`.
  Future<String?> tapPrimeroQueExista(List<String> etiquetas) async {
    for (final etiqueta in etiquetas) {
      final f = find.text(etiqueta);
      if (f.evaluate().isEmpty) continue;
      try {
        await ensureVisible(f.first);
      } catch (_) {/* ya visible o sin scrollable */}
      await pump();
      await tap(f.first, warnIfMissed: false);
      await pump(const Duration(milliseconds: 600));
      paso('Toqué «$etiqueta»');
      return etiqueta;
    }
    paso('Ninguna de $etiquetas estaba en pantalla — sigo');
    return null;
  }

  /// Espera a que aparezca cualquiera de los textos. Devuelve el que apareció, o `null`.
  Future<String?> esperaCualquiera(
    List<String> textos, {
    int maxTicks = 60,
    Duration tick = const Duration(milliseconds: 500),
  }) async {
    for (var i = 0; i < maxTicks; i++) {
      for (final t in textos) {
        if (find.textContaining(t).evaluate().isNotEmpty) return t;
      }
      await pump(tick);
    }
    return null;
  }

  /// Pausa visible. El video es parte del entregable: sin esto los pasos se atropellan y la
  /// grabación no sirve para revisar nada con nadie.
  Future<void> respira([Duration d = const Duration(seconds: 2)]) => pump(d);

  /// Vuelca a stdout los textos visibles. Se llama justo antes de cada `expect` que puede fallar,
  /// para que el log diga en qué pantalla se quedó en vez de sólo que no encontró algo.
  void volcarPantalla() {
    final textos = find
        .byType(Text)
        .evaluate()
        .map((e) => (e.widget as Text).data)
        .where((t) => t != null && t.trim().isNotEmpty)
        .take(25)
        .toList();
    paso('Pantalla: $textos');
  }
}
