/// El estado del domicilio, leído del domicilio que trae la INE.
///
/// El OCR devuelve la dirección como una sola línea —«COL. VILLA UNIVERSIDAD, CULIACÁN, SINALOA
/// 80060»— y la app sólo tomaba de ella… nada: el estado del domicilio llegaba vacío aunque la
/// credencial lo dijera, y quien llenaba el formulario tenía que buscar Sinaloa a mano en una lista
/// de 32. Peor: en la regresión el campo quedaba con un estado que no tenía nada que ver con
/// Culiacán, y nadie lo notaba porque el formulario se veía completo.
///
/// Devuelve el nombre **tal como lo lista el selector**, o vacío si la dirección no menciona ninguno
/// con certeza. Vacío es preferible a adivinar: un estado equivocado prellenado parece confirmado.
library;

/// Las 32 entidades, con el mismo texto que el selector de la pantalla de datos.
const estadosDeMexico = <String>[
  'Aguascalientes', 'Baja California', 'Baja California Sur',
  'Campeche', 'Chiapas', 'Chihuahua', 'Ciudad de México', 'Coahuila',
  'Colima', 'Durango', 'Estado de México', 'Guanajuato', 'Guerrero',
  'Hidalgo', 'Jalisco', 'Michoacán', 'Morelos', 'Nayarit',
  'Nuevo León', 'Oaxaca', 'Puebla', 'Querétaro', 'Quintana Roo',
  'San Luis Potosí', 'Sinaloa', 'Sonora', 'Tabasco', 'Tamaulipas',
  'Tlaxcala', 'Veracruz', 'Yucatán', 'Zacatecas',
];

/// Cómo aparecen en las credenciales cuando no se escriben completos. Las llaves van ya
/// normalizadas: «N.L.» llega como «N L», porque los puntos se vuelven espacios.
const _abreviaturas = <String, String>{
  'CDMX': 'Ciudad de México',
  'D F': 'Ciudad de México',
  'EDOMEX': 'Estado de México',
  'EDO MEX': 'Estado de México',
  'EDO DE MEX': 'Estado de México',
  'MEX': 'Estado de México',
  'BCS': 'Baja California Sur',
  'B C S': 'Baja California Sur',
  'BC': 'Baja California',
  'B C': 'Baja California',
  'NL': 'Nuevo León',
  'N L': 'Nuevo León',
  'QROO': 'Quintana Roo',
  'Q ROO': 'Quintana Roo',
  'SLP': 'San Luis Potosí',
  'S L P': 'San Luis Potosí',
  'COAHUILA DE ZARAGOZA': 'Coahuila',
  'MICHOACAN DE OCAMPO': 'Michoacán',
  'VERACRUZ DE IGNACIO DE LA LLAVE': 'Veracruz',
};

String _normaliza(String s) {
  const acentos = {'Á': 'A', 'É': 'E', 'Í': 'I', 'Ó': 'O', 'Ú': 'U', 'Ü': 'U', 'Ñ': 'N'};
  final mayus = s.toUpperCase().split('').map((c) => acentos[c] ?? c).join();
  // Puntos y comas fuera, espacios colapsados: «EDO. DE MÉX.» y «EDO DE MEX» son lo mismo.
  return ' ${mayus.replaceAll(RegExp(r'[^A-Z0-9]+'), ' ').trim()} ';
}

String estadoDesdeDomicilio(String domicilio) {
  if (domicilio.trim().isEmpty) return '';
  final texto = _normaliza(domicilio);

  // Primero los nombres completos, del más largo al más corto: «Baja California Sur» tiene que
  // ganarle a «Baja California», y «Estado de México» a cualquier «México» suelto.
  final completos = [...estadosDeMexico]..sort((a, b) => b.length.compareTo(a.length));
  for (final estado in completos) {
    if (texto.contains(_normaliza(estado))) return estado;
  }
  final abreviadas = _abreviaturas.keys.toList()..sort((a, b) => b.length.compareTo(a.length));
  for (final abreviatura in abreviadas) {
    if (texto.contains(' $abreviatura ')) return _abreviaturas[abreviatura]!;
  }
  return '';
}
