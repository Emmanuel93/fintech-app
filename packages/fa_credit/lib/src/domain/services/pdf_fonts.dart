import 'package:flutter/services.dart' show rootBundle;
import 'package:pdf/widgets.dart' as pw;

/// Las tipografías de los documentos.
///
/// El paquete `pdf` usa Helvetica por omisión, que **no tiene soporte Unicode**:
/// un contrato con "amortización", "interés" o "solicitó" saldría con los
/// acentos rotos o comidos. Se embebe Inter —la misma familia de la app— para
/// que el documento se lea como se escribió y además se parezca a la marca.
///
/// Se cachea porque un contrato se regenera en cada trazo del pad de firma:
/// releer 300 KB de fuente por repintado es gratuito de evitar.
abstract final class PdfFonts {
  static pw.ThemeData? _cached;

  static const _regular =
      'packages/fa_design_system/assets/fonts/Inter-Regular.ttf';
  static const _bold = 'packages/fa_design_system/assets/fonts/Inter-Bold.ttf';

  /// Tema con Inter en redonda y negrita. Si por lo que sea las fuentes no
  /// están, se devuelve `null` y el documento cae a Helvetica: preferimos un
  /// PDF con acentos feos a un PDF que no existe.
  static Future<pw.ThemeData?> theme() async {
    if (_cached != null) return _cached;
    try {
      final regular = pw.Font.ttf(await rootBundle.load(_regular));
      final bold = pw.Font.ttf(await rootBundle.load(_bold));
      return _cached = pw.ThemeData.withFont(
        base: regular,
        bold: bold,
        italic: regular,
        boldItalic: bold,
      );
    } catch (_) {
      return null;
    }
  }
}
