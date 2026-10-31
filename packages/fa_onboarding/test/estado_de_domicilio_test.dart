import 'package:fa_onboarding/src/domain/services/estado_de_domicilio.dart';
import 'package:flutter_test/flutter_test.dart';

/// El estado del domicilio sale de la dirección que trae la INE.
///
/// El caso que lo motivó: el OCR decía «CULIACÁN, SINALOA 80060» y el formulario terminaba con
/// otro estado. Lo que estas pruebas fijan es que se lea el que la credencial dice, que no se
/// confunda uno con otro de nombre parecido, y que ante la duda se deje vacío.
void main() {
  group('estadoDesdeDomicilio', () {
    test('lee Sinaloa de la dirección de Culiacán que devuelve el OCR', () {
      expect(estadoDesdeDomicilio('COL. VILLA UNIVERSIDAD, CULIACÁN, SINALOA 80060'), 'Sinaloa');
    });

    test('devuelve el nombre exacto del selector, con acentos', () {
      expect(estadoDesdeDomicilio('CENTRO, QUERETARO, QRO 76000'), 'Querétaro');
      expect(estadoDesdeDomicilio('MERIDA, YUCATAN 97000'), 'Yucatán');
      expect(estadoDesdeDomicilio('MONTERREY, NUEVO LEON'), 'Nuevo León');
    });

    test('«Baja California Sur» le gana a «Baja California»', () {
      expect(estadoDesdeDomicilio('LA PAZ, BAJA CALIFORNIA SUR 23000'), 'Baja California Sur');
      expect(estadoDesdeDomicilio('TIJUANA, BAJA CALIFORNIA 22000'), 'Baja California');
    });

    test('entiende las abreviaturas de las credenciales', () {
      expect(estadoDesdeDomicilio('AV. INSURGENTES SUR 1602, COL. CRÉDITO CONSTRUCTOR, CDMX 03940'),
          'Ciudad de México');
      expect(estadoDesdeDomicilio('NAUCALPAN, EDO. DE MÉX. 53000'), 'Estado de México');
      expect(estadoDesdeDomicilio('SAN PEDRO, N.L. 66220'), 'Nuevo León');
    });

    test('«México» suelto no es el Estado de México', () {
      expect(estadoDesdeDomicilio('CALLE 5, COL. CENTRO, MÉXICO'), '');
    });

    test('ante la duda, vacío: un estado equivocado prellenado parece confirmado', () {
      expect(estadoDesdeDomicilio(''), '');
      expect(estadoDesdeDomicilio('CALLE SIN NOMBRE 12, COL. CENTRO'), '');
    });

    test('el nombre de un estado dentro de una calle no se confunde con otro más corto', () {
      // «Coahuila de Zaragoza» es Coahuila; no debe quedarse en ningún otro por coincidencia.
      expect(estadoDesdeDomicilio('SALTILLO, COAHUILA DE ZARAGOZA 25000'), 'Coahuila');
    });
  });
}
