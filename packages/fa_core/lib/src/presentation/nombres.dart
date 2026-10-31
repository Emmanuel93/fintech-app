/// Presentación de nombres de persona.
extension NombrePropio on String {
  /// "LAURA MÉNDEZ SOTO" → "Laura Méndez Soto".
  ///
  /// Los nombres llegan **en mayúsculas** porque así los guarda la INE y así
  /// los devuelve el expediente. Gritarle el nombre al usuario en cada pantalla
  /// es de formulario de gobierno, no de una app; y en un saludo —"Hola,
  /// LAURA"— se lee como un regaño.
  ///
  /// Las partículas de los apellidos compuestos se quedan en minúscula, que es
  /// como se escriben en español: "JUAN DE LA CRUZ" → "Juan de la Cruz". No se
  /// aplica a la primera palabra, para no dejar un nombre empezando en
  /// minúscula si alguien se llama "Del Toro".
  static const _particulas = {
    'de', 'del', 'la', 'las', 'los', 'y', 'e', 'da', 'do', 'dos', 'van', 'von'
  };

  String get comoNombrePropio {
    final palabras = trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty);
    if (palabras.isEmpty) return '';

    final salida = <String>[];
    for (final (i, palabra) in palabras.indexed) {
      final minuscula = palabra.toLowerCase();
      if (i > 0 && _particulas.contains(minuscula)) {
        salida.add(minuscula);
        continue;
      }
      // Los nombres con guion o apóstrofo llevan mayúscula en cada parte:
      // "JEAN-PAUL" → "Jean-Paul", "D'ANGELO" → "D'Angelo".
      salida.add(minuscula.splitMapJoin(
        RegExp(r"[-']"),
        onMatch: (m) => m[0]!,
        onNonMatch: (t) =>
            t.isEmpty ? t : '${t[0].toUpperCase()}${t.substring(1)}',
      ));
    }
    return salida.join(' ');
  }
}
