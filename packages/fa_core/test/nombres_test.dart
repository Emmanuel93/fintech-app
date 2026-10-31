/// Cómo se muestran los nombres de persona.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:fa_core/fa_core.dart';

void main() {
  group('comoNombrePropio', () {
    test('baja las mayúsculas de la INE', () {
      expect('LAURA MÉNDEZ SOTO'.comoNombrePropio,
          'Laura Méndez Soto');
    });

    test('deja las partículas de los apellidos en minúscula', () {
      expect('JUAN DE LA CRUZ'.comoNombrePropio, 'Juan de la Cruz');
      expect('ANA DEL TORO Y RÍOS'.comoNombrePropio, 'Ana del Toro y Ríos');
    });

    test('pero no si la partícula abre el nombre', () {
      expect('DEL TORO'.comoNombrePropio, 'Del Toro',
          reason: 'un nombre no puede empezar en minúscula');
    });

    test('respeta guiones y apóstrofos', () {
      expect('JEAN-PAUL SARTRE'.comoNombrePropio, 'Jean-Paul Sartre');
      expect("D'ANGELO".comoNombrePropio, "D'Angelo");
    });

    test('no rompe con lo que ya viene bien escrito', () {
      expect('Laura Méndez'.comoNombrePropio, 'Laura Méndez');
    });

    test('tolera espacios de más y cadenas vacías', () {
      expect('  ANA   SOSA '.comoNombrePropio, 'Ana Sosa');
      expect(''.comoNombrePropio, '');
      expect('   '.comoNombrePropio, '');
    });
  });
}
