import 'dart:typed_data';

import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import 'pdf_fonts.dart';

/// Datos que van al clausulado. Se arman en la capa de presentación a partir
/// de la solicitud y el producto, y este builder no sabe nada de widgets.
class ContractData {
  const ContractData({
    required this.contractNumber,
    required this.holderName,
    required this.curp,
    required this.productName,
    required this.behavior,
    required this.amount,
    required this.annualRate,
    required this.clabe,
    this.term,
    this.periodicPayment,
    this.totalRepayment,
    this.isDistributor = false,
    this.commissionRate,
  });

  final String contractNumber, holderName, curp, productName, clabe;

  /// REVOLVING | INSTALLMENT — decide qué clausulado se imprime.
  final String behavior;

  final double amount, annualRate;
  final int? term;
  final double? periodicPayment, totalRepayment;

  /// Línea de colocación: añade las cláusulas de disposición a tercero.
  final bool isDistributor;
  final double? commissionRate;

  bool get isRevolving => behavior.toUpperCase() == 'REVOLVING';

  /// Cómo se llama el contrato que se está firmando. Es lo primero que lee el
  /// cliente y lo que distingue una línea revolvente de un préstamo a plazo.
  String get contractTitle => isDistributor
      ? 'CONTRATO DE APERTURA DE LÍNEA DE CRÉDITO PARA COLOCACIÓN'
      : isRevolving
          ? 'CONTRATO DE APERTURA DE CRÉDITO EN CUENTA CORRIENTE '
              '(LÍNEA REVOLVENTE)'
          : 'CONTRATO DE CRÉDITO SIMPLE CON INTERÉS (PRÉSTAMO PERSONAL)';

  /// El clausulado, como datos. Vive aquí y no en el builder de PDF para poder
  /// verificarlo sin abrir un documento: lo que se firma es este texto.
  List<(String, String)> get clauses {
    // Sin estimado no se imprime un importe: un "$0.00" en la cláusula de pago
    // se lee como "no debo nada", que es exactamente lo contrario.
    final cuota = periodicPayment != null
        ? 'pagará ${term ?? 0} exhibiciones de '
            '${_money.format(periodicPayment)} cada una'
        : 'pagará ${term ?? 0} exhibiciones por el importe que indique la tabla '
            'de amortización';

    return <(String, String)>[
      (
        'PRIMERA. Objeto',
        isRevolving
            ? 'La Financiera pone a disposición del Acreditado una línea de crédito '
                'revolvente por hasta ${_money.format(amount)}. El Acreditado podrá '
                'disponer de ella total o parcialmente, y el monto dispuesto se '
                'restituirá conforme realice pagos, quedando nuevamente disponible.'
            : 'La Financiera otorga al Acreditado un crédito simple por '
                '${_money.format(amount)}, que se entrega en una sola exhibición '
                'mediante abono a la cuenta señalada en este contrato.',
      ),
      (
        'SEGUNDA. Intereses',
        'El saldo insoluto devengará intereses ordinarios a una tasa anual fija de '
            '${(annualRate * 100).toStringAsFixed(2)}%, calculados sobre saldos '
            'insolutos y con base en un año de 365 días. Los intereses se devengan '
            'diariamente desde la fecha de disposición.',
      ),
      (
        'TERCERA. Forma de pago',
        isRevolving
            ? 'El Acreditado cubrirá, en cada fecha de corte, al menos el pago mínimo '
                'informado en su estado de cuenta. Podrá liquidar anticipadamente, en '
                'todo o en parte, sin penalización alguna.'
            : 'El Acreditado $cuota, conforme a la tabla de amortización que forma '
                'parte integrante de este contrato. Podrá realizar pagos anticipados '
                'sin penalización, aplicándose a capital.',
      ),
      if (isDistributor)
        (
          'CUARTA. Disposiciones a favor de terceros',
          'El Acreditado podrá instruir disposiciones con abono a personas distintas '
              'de él mismo ("beneficiarios"), quienes deberán ser identificadas '
              'previamente. El Acreditado conserva la calidad de único obligado frente '
              'a la Financiera por el total dispuesto, con independencia de quién '
              'reciba los recursos. Por cada colocación, el Acreditado percibirá una '
              'comisión de ${((commissionRate ?? 0) * 100).toStringAsFixed(2)}% sobre '
              'el monto dispuesto.',
        ),
      (
        '${isDistributor ? 'QUINTA' : 'CUARTA'}. Consulta a sociedades de información crediticia',
        'El Acreditado autoriza expresamente a la Financiera a consultar su historial '
            'crediticio ante las sociedades de información crediticia, en términos de '
            'los artículos 13 y 28 de la Ley para Regular las Sociedades de Información '
            'Crediticia, durante la vigencia de la relación jurídica.',
      ),
      (
        '${isDistributor ? 'SEXTA' : 'QUINTA'}. Firma electrónica',
        'Las partes reconocen que la firma autógrafa digitalizada y el código de un '
            'solo uso enviado al número de teléfono registrado producen los mismos '
            'efectos jurídicos que la firma autógrafa, en términos del artículo 89 del '
            'Código de Comercio. La Financiera conservará constancia de fecha, hora y '
            'dirección IP de la firma.',
      ),
    ];
  }

  static final _money =
      NumberFormat.currency(locale: 'es_MX', symbol: '\$', decimalDigits: 2);
}

/// Arma el PDF del contrato de crédito.
///
/// El clausulado cambia con el producto, que es lo que hace flexible al
/// producto sin multiplicar plantillas:
///
/// - **A plazo** (`INSTALLMENT`): monto único, tabla de amortización, pagos
///   fijos. Se imprime el plazo, la cuota y el total a pagar.
/// - **Revolvente** (`REVOLVING`): línea que se dispone y se libera; no hay
///   cuota fija, sí un límite y un corte.
/// - **Colocación** (distribuidor): sobre cualquiera de los dos, añade las
///   cláusulas de disposición a favor de terceros y la comisión del titular.
///
/// La firma se estampa como imagen al final del documento: el PNG del pad
/// entra en [signature] y se dibuja sobre la línea de firma.
abstract final class ContractPdfBuilder {
  static final _money =
      NumberFormat.currency(locale: 'es_MX', symbol: '\$', decimalDigits: 2);
  static final _date = DateFormat("d 'de' MMMM 'de' yyyy", 'es_MX');

  static Future<Uint8List> build(
    ContractData data, {
    Uint8List? signature,
    DateTime? signedAt,
  }) async {
    final theme = await PdfFonts.theme();
    final doc = pw.Document(
      title: 'Contrato ${data.contractNumber}',
      author: 'Kredius, S.A. de C.V., SOFOM, E.N.R.',
      theme: theme,
    );

    final firmadoEl = signedAt ?? DateTime.now();

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.letter,
        margin: const pw.EdgeInsets.fromLTRB(48, 48, 48, 56),
        header: (_) => _header(data),
        footer: (ctx) => _footer(ctx, data),
        build: (_) => [
          _title(data),
          pw.SizedBox(height: 14),
          _partiesTable(data),
          pw.SizedBox(height: 18),
          ..._clauses(data),
          pw.SizedBox(height: 26),
          _signatureBlock(data, signature, firmadoEl),
        ],
      ),
    );

    return doc.save();
  }

  // ── Piezas del documento ───────────────────────────────────────────────

  static pw.Widget _header(ContractData d) => pw.Container(
        padding: const pw.EdgeInsets.only(bottom: 8),
        margin: const pw.EdgeInsets.only(bottom: 14),
        decoration: const pw.BoxDecoration(
          border: pw.Border(
              bottom: pw.BorderSide(color: PdfColor.fromInt(0xFFD3DAE6))),
        ),
        child: pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          crossAxisAlignment: pw.CrossAxisAlignment.end,
          children: [
            pw.Text('KREDIUS',
                style: pw.TextStyle(
                  fontSize: 16,
                  fontWeight: pw.FontWeight.bold,
                  color: const PdfColor.fromInt(0xFF0D47A1),
                  letterSpacing: -0.6,
                )),
            pw.Text('Contrato ${d.contractNumber}',
                style: const pw.TextStyle(
                    fontSize: 9, color: PdfColor.fromInt(0xFF44474E))),
          ],
        ),
      );

  static pw.Widget _footer(pw.Context ctx, ContractData d) => pw.Container(
        alignment: pw.Alignment.centerRight,
        margin: const pw.EdgeInsets.only(top: 10),
        child: pw.Text(
          'Kredius, S.A. de C.V., SOFOM, E.N.R.  ·  '
          'Página ${ctx.pageNumber} de ${ctx.pagesCount}',
          style: const pw.TextStyle(
              fontSize: 8, color: PdfColor.fromInt(0xFF9E9E9E)),
        ),
      );

  static pw.Widget _title(ContractData d) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(d.contractTitle,
            style:
                pw.TextStyle(fontSize: 12.5, fontWeight: pw.FontWeight.bold)),
        pw.SizedBox(height: 5),
        pw.Text(
          'Que celebran, por una parte, Kredius, S.A. de C.V., SOFOM, E.N.R. '
          '(en adelante "la Financiera") y, por la otra, ${d.holderName} '
          '(en adelante "el Acreditado").',
          style: const pw.TextStyle(fontSize: 9.5, lineSpacing: 2),
        ),
      ],
    );
  }

  static pw.Widget _partiesTable(ContractData d) {
    final rows = <List<String>>[
      ['Acreditado', d.holderName],
      ['CURP', d.curp],
      ['Producto', d.productName],
      [
        d.isRevolving ? 'Línea autorizada' : 'Monto del crédito',
        _money.format(d.amount)
      ],
      [
        'Tasa de interés anual ordinaria',
        '${(d.annualRate * 100).toStringAsFixed(2)}%'
      ],
      if (!d.isRevolving && d.term != null) ['Plazo', '${d.term} pagos'],
      if (!d.isRevolving && d.periodicPayment != null)
        ['Pago periódico', _money.format(d.periodicPayment)],
      if (!d.isRevolving && d.totalRepayment != null)
        ['Total a pagar', _money.format(d.totalRepayment)],
      if (d.isDistributor && d.commissionRate != null)
        [
          'Comisión por colocación',
          '${(d.commissionRate! * 100).toStringAsFixed(2)}%'
        ],
      ['Cuenta de abono (CLABE)', _maskClabe(d.clabe)],
    ];

    return pw.Table(
      border: pw.TableBorder.all(
          color: const PdfColor.fromInt(0xFFE0E0E0), width: 0.5),
      columnWidths: const {
        0: pw.FlexColumnWidth(1.1),
        1: pw.FlexColumnWidth(1.4),
      },
      children: [
        for (final r in rows)
          pw.TableRow(children: [
            pw.Padding(
              padding:
                  const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              child: pw.Text(r[0],
                  style: const pw.TextStyle(
                      fontSize: 9, color: PdfColor.fromInt(0xFF44474E))),
            ),
            pw.Padding(
              padding:
                  const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              child: pw.Text(r[1],
                  style: pw.TextStyle(
                      fontSize: 9, fontWeight: pw.FontWeight.bold)),
            ),
          ]),
      ],
    );
  }

  static List<pw.Widget> _clauses(ContractData d) => [
        for (final (titulo, texto) in d.clauses) ...[
          pw.SizedBox(height: 12),
          pw.Text(titulo,
              style:
                  pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 4),
          pw.Text(texto,
              textAlign: pw.TextAlign.justify,
              style: const pw.TextStyle(fontSize: 9, lineSpacing: 2)),
        ],
      ];

  /// Bloque de firma. Si viene el PNG del pad, se dibuja **sobre** la línea.
  static pw.Widget _signatureBlock(
    ContractData d,
    Uint8List? signature,
    DateTime signedAt,
  ) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text('Firmado en Ciudad de México el ${_date.format(signedAt)}.',
            style: const pw.TextStyle(fontSize: 9)),
        pw.SizedBox(height: 26),
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          crossAxisAlignment: pw.CrossAxisAlignment.end,
          children: [
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.center,
              children: [
                // La firma se estampa encima de la línea, no al lado.
                pw.Container(
                  width: 190,
                  height: 62,
                  alignment: pw.Alignment.bottomCenter,
                  child: signature != null
                      ? pw.Image(pw.MemoryImage(signature),
                          fit: pw.BoxFit.contain)
                      : pw.SizedBox(),
                ),
                pw.Container(width: 190, height: 0.8, color: PdfColors.black),
                pw.SizedBox(height: 4),
                pw.Text(d.holderName,
                    style: pw.TextStyle(
                        fontSize: 8.5, fontWeight: pw.FontWeight.bold)),
                pw.Text('El Acreditado',
                    style: const pw.TextStyle(
                        fontSize: 8, color: PdfColor.fromInt(0xFF9E9E9E))),
              ],
            ),
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.center,
              children: [
                pw.SizedBox(width: 190, height: 62),
                pw.Container(width: 190, height: 0.8, color: PdfColors.black),
                pw.SizedBox(height: 4),
                pw.Text('Kredius, S.A. de C.V., SOFOM, E.N.R.',
                    style: pw.TextStyle(
                        fontSize: 8.5, fontWeight: pw.FontWeight.bold)),
                pw.Text('La Financiera',
                    style: const pw.TextStyle(
                        fontSize: 8, color: PdfColor.fromInt(0xFF9E9E9E))),
              ],
            ),
          ],
        ),
      ],
    );
  }

  /// La CLABE va enmascarada, con asteriscos y no con viñetas: la fuente base
  /// del PDF (Helvetica) no tiene glifo para "•" y lo imprimiría en blanco —
  /// una cuenta de abono ilegible en el contrato.
  static String _maskClabe(String clabe) {
    final d = clabe.replaceAll(RegExp(r'\D'), '');
    if (d.length < 4) return clabe;
    return '${'*' * (d.length - 4)}${d.substring(d.length - 4)}';
  }
}
