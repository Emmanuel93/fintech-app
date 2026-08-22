import 'dart:typed_data';

import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import 'amortization_calculator.dart';
import 'pdf_fonts.dart';

/// La tabla de amortización, como documento.
///
/// El contrato la declara "parte integrante" y la casilla de firma pide
/// aceptarla, pero hasta ahora no se mostraba en ningún lado: se aceptaba un
/// anexo invisible. Esto la imprime cuota por cuota —fecha, pago, cuánto va a
/// intereses, cuánto a capital y qué saldo queda— para que se pueda leer antes
/// de firmar y guardar después.
abstract final class AmortizationPdfBuilder {
  static final _money =
      NumberFormat.currency(locale: 'es_MX', symbol: '\$', decimalDigits: 2);
  static final _short = DateFormat('dd/MM/yyyy');

  static Future<Uint8List> build({
    required List<AmortizationRow> rows,
    required double amount,
    required double annualRate,
    required String periodAdjective,
    String? contractNumber,
    String? holderName,
  }) async {
    final theme = await PdfFonts.theme();
    final doc = pw.Document(
      title:
          'Tabla de amortización${contractNumber == null ? '' : ' $contractNumber'}',
      author: 'Kredius, S.A. de C.V., SOFOM, E.N.R.',
      theme: theme,
    );

    final totalPagos = rows.fold<double>(0, (a, r) => a + r.payment);
    final totalIntereses = rows.fold<double>(0, (a, r) => a + r.interest);

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.letter,
        margin: const pw.EdgeInsets.fromLTRB(40, 44, 40, 48),
        footer: (ctx) => pw.Container(
          alignment: pw.Alignment.centerRight,
          margin: const pw.EdgeInsets.only(top: 10),
          child: pw.Text(
            'Kredius, S.A. de C.V., SOFOM, E.N.R.  ·  '
            'Página ${ctx.pageNumber} de ${ctx.pagesCount}',
            style: const pw.TextStyle(
                fontSize: 8, color: PdfColor.fromInt(0xFF9E9E9E)),
          ),
        ),
        build: (_) => [
          pw.Text('TABLA DE AMORTIZACIÓN',
              style:
                  pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 4),
          pw.Text(
            [
              if (holderName != null) holderName,
              if (contractNumber != null) 'Contrato $contractNumber',
              'Crédito por ${_money.format(amount)}',
              '${rows.length} pagos $periodAdjective${rows.length == 1 ? '' : 'es'}',
              'Tasa anual ${(annualRate * 100).toStringAsFixed(2)}%',
            ].join('  ·  '),
            style: const pw.TextStyle(
                fontSize: 9, color: PdfColor.fromInt(0xFF44474E)),
          ),
          pw.SizedBox(height: 14),
          _table(rows),
          pw.SizedBox(height: 14),
          _totals(totalPagos, totalIntereses, amount),
          pw.SizedBox(height: 12),
          pw.Text(
            'Las fechas son las pactadas al firmar. Los pagos anticipados se '
            'aplican a capital y reducen los intereses de los periodos '
            'siguientes, por lo que las cifras posteriores pueden disminuir.',
            style: const pw.TextStyle(
                fontSize: 8,
                color: PdfColor.fromInt(0xFF9E9E9E),
                lineSpacing: 2),
          ),
        ],
      ),
    );

    return doc.save();
  }

  static pw.Widget _table(List<AmortizationRow> rows) {
    pw.Widget cell(String text, {bool head = false, bool right = false}) =>
        pw.Padding(
          padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 4.5),
          child: pw.Text(
            text,
            textAlign: right ? pw.TextAlign.right : pw.TextAlign.left,
            style: pw.TextStyle(
              fontSize: 8.5,
              fontWeight: head ? pw.FontWeight.bold : pw.FontWeight.normal,
              color:
                  head ? const PdfColor.fromInt(0xFF44474E) : PdfColors.black,
            ),
          ),
        );

    return pw.Table(
      border: pw.TableBorder.all(
          color: const PdfColor.fromInt(0xFFE0E0E0), width: 0.5),
      columnWidths: const {
        0: pw.FlexColumnWidth(0.55),
        1: pw.FlexColumnWidth(1.1),
        2: pw.FlexColumnWidth(1.1),
        3: pw.FlexColumnWidth(1.1),
        4: pw.FlexColumnWidth(1.1),
        5: pw.FlexColumnWidth(1.2),
      },
      children: [
        pw.TableRow(
          decoration:
              const pw.BoxDecoration(color: PdfColor.fromInt(0xFFF2F5FA)),
          children: [
            cell('#', head: true),
            cell('Vencimiento', head: true),
            cell('Pago', head: true, right: true),
            cell('Interés', head: true, right: true),
            cell('Capital', head: true, right: true),
            cell('Saldo', head: true, right: true),
          ],
        ),
        for (final r in rows)
          pw.TableRow(children: [
            cell('${r.number}'),
            cell(_short.format(r.dueDate)),
            cell(_money.format(r.payment), right: true),
            cell(_money.format(r.interest), right: true),
            cell(_money.format(r.principal), right: true),
            cell(_money.format(r.balance), right: true),
          ]),
      ],
    );
  }

  static pw.Widget _totals(double pagos, double intereses, double capital) {
    pw.Widget row(String label, String value, {bool bold = false}) =>
        pw.Padding(
          padding: const pw.EdgeInsets.symmetric(vertical: 2),
          child: pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(label,
                  style: pw.TextStyle(
                      fontSize: 9,
                      fontWeight:
                          bold ? pw.FontWeight.bold : pw.FontWeight.normal)),
              pw.Text(value,
                  style: pw.TextStyle(
                      fontSize: 9,
                      fontWeight:
                          bold ? pw.FontWeight.bold : pw.FontWeight.normal)),
            ],
          ),
        );

    return pw.Container(
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        color: const PdfColor.fromInt(0xFFF2F5FA),
        borderRadius: pw.BorderRadius.circular(6),
      ),
      child: pw.Column(children: [
        row('Capital', _money.format(capital)),
        row('Intereses', _money.format(intereses)),
        row('Total a pagar', _money.format(pagos), bold: true),
      ]),
    );
  }
}
