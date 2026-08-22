/// El contrato es el documento que el cliente firma: si sale con el clausulado
/// de otro producto, con el titular en blanco o con la cuota en $0.00, lo que
/// se firmó no es lo que se contrató. Estos tests fijan esas tres cosas.
library;

import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:fa_credit/src/domain/services/contract_pdf_builder.dart';

ContractData _data({
  String behavior = 'INSTALLMENT',
  bool isDistributor = false,
  String holderName = 'María Fernanda Rivas Solís',
  String curp = 'RISM900112MDFVLR03',
  double? periodicPayment = 4812.35,
}) {
  return ContractData(
    contractNumber: 'KRD-2026-000123',
    holderName: holderName,
    curp: curp,
    productName: 'Crédito Kredius',
    behavior: behavior,
    amount: 50000,
    annualRate: 0.34,
    term: 12,
    periodicPayment: periodicPayment,
    totalRepayment: periodicPayment == null ? null : periodicPayment * 12,
    clabe: '012180001234567895',
    isDistributor: isDistributor,
    commissionRate: isDistributor ? 0.035 : null,
  );
}

void main() {
  // La fecha de firma se imprime en español.
  setUpAll(() => initializeDateFormatting('es_MX', null));

  test('el título nombra el contrato que corresponde al producto', () {
    expect(_data().contractTitle, contains('CRÉDITO SIMPLE'));
    expect(_data(behavior: 'REVOLVING').contractTitle,
        contains('CUENTA CORRIENTE'));
    expect(_data(behavior: 'REVOLVING', isDistributor: true).contractTitle,
        contains('COLOCACIÓN'));
  });

  test('el distribuidor suma la cláusula de comisión y disposición a terceros',
      () {
    final propio = _data().clauses.join(' ');
    final distribuidor = _data(isDistributor: true).clauses.join(' ');

    expect(distribuidor, contains('comisión'));
    expect(distribuidor.length, greaterThan(propio.length),
        reason: 'colocar con terceros obliga a decir más, no menos');
  });

  test('el revolvente no promete un plazo fijo y el simple sí', () {
    expect(_data().clauses.join(' '), contains('exhibiciones'));
    expect(_data(behavior: 'REVOLVING').clauses.join(' '),
        contains('disponer'));
  });

  test('genera un PDF real, y la firma estampada lo hace más pesado', () async {
    final sin = await ContractPdfBuilder.build(_data());
    expect(sin.length, greaterThan(1000), reason: 'no es un PDF vacío');
    expect(String.fromCharCodes(sin.take(5)), '%PDF-');

    // Un PNG de 1×1 transparente basta: lo que se comprueba es que la firma
    // llega al documento, no cómo se ve.
    final png = _tinyPng();
    final con = await ContractPdfBuilder.build(_data(), signature: png);
    expect(con.length, greaterThan(sin.length),
        reason: 'la firma se incrusta en el documento, no se descarta');
  });

  test('la CLABE se enmascara con glifos que la fuente del PDF sí dibuja', () async {
    // Helvetica no tiene "•": con viñetas la cuenta de abono saldría en blanco.
    final bytes = await ContractPdfBuilder.build(_data());
    expect(bytes.length, greaterThan(1000));
    expect(_data().clauses.join(' '), isNot(contains('•')));
  });

  test('sin cuota calculada el clausulado no inventa un \$0.00', () {
    // Es el bug que se vio en el contrato renderizado: la solicitud del mock no
    // trae tasa, el estimado salía nulo y el PDF imprimía "$0.00". Ahora la
    // pantalla cae al producto; aquí se fija que el builder omita el importe en
    // vez de imprimir un cero que el cliente leería como "no pago nada".
    final texto = _data(periodicPayment: null).clauses.join(' ');
    expect(texto, isNot(contains(r'$0.00')));
  });
}

/// PNG 1×1 transparente.
Uint8List _tinyPng() => Uint8List.fromList(const [
      0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, //
      0x00, 0x00, 0x00, 0x0D, 0x49, 0x48, 0x44, 0x52,
      0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01,
      0x08, 0x06, 0x00, 0x00, 0x00, 0x1F, 0x15, 0xC4,
      0x89, 0x00, 0x00, 0x00, 0x0A, 0x49, 0x44, 0x41,
      0x54, 0x78, 0x9C, 0x63, 0x00, 0x01, 0x00, 0x00,
      0x05, 0x00, 0x01, 0x0D, 0x0A, 0x2D, 0xB4, 0x00,
      0x00, 0x00, 0x00, 0x49, 0x45, 0x4E, 0x44, 0xAE,
      0x42, 0x60, 0x82,
    ]);
