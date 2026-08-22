/// La preoferta es lo que el scoring le autorizó a **esta** persona. Si el
/// configurador se mueve sobre el rango del catálogo, el usuario arma un
/// préstamo que después se recorta en la resolución.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:fa_credit/src/domain/entities/credit_product.dart';
import 'package:fa_credit/src/domain/entities/prequalified_product.dart';
import 'package:fa_credit/src/infrastructure/dtos/prequalified_product_dto.dart';

const _catalogo = CreditProduct(
  code: 'PL',
  name: 'Préstamo personal',
  productType: 'PERSONAL_LOAN',
  behavior: 'INSTALLMENT',
  minAmount: 5000,
  maxAmount: 150000,
  minTerm: 6,
  maxTerm: 48,
  nominalRate: 0.42,
  defaultPaymentFrequency: 'MONTHLY',
  amountStep: 5000,
  defaultTerm: 24,
);

void main() {
  test('la preoferta recorta el rango del catálogo', () {
    const item = PrequalifiedProduct(
      product: _catalogo,
      evaluated: true,
      decision: 'AUTO_APPROVED',
      approvedMaxAmount: 90000,
      approvedMaxTerm: 36,
      approvedDefaultTerm: 21,
      approvedRate: 0.46,
    );

    final offer = item.offer;
    expect(offer.maxAmount, 90000, reason: 'manda el scoring, no el catálogo');
    expect(offer.maxTerm, 36);
    expect(offer.defaultTerm, 21);
    expect(offer.nominalRate, 0.46);
    // Lo que el scoring no acota se queda como está.
    expect(offer.minAmount, 5000);
    expect(offer.amountStep, 5000);
    expect(offer.code, 'PL');
    expect(item.hasPreOffer, isTrue);
  });

  test('sin preoferta el producto queda intacto', () {
    const item = PrequalifiedProduct(product: _catalogo, evaluated: true);
    expect(item.hasPreOffer, isFalse);
    expect(item.offer.maxAmount, 150000);
    expect(item.offer.maxTerm, 48);
  });

  test('el DTO lee el bloque preOffer que manda el BFF', () {
    final item = PrequalifiedProductDto.fromJson({
      'code': 'PL',
      'name': 'Préstamo personal',
      'productType': 'PERSONAL_LOAN',
      'behavior': 'INSTALLMENT',
      'minAmount': 5000,
      'maxAmount': 150000,
      'minTerm': 6,
      'maxTerm': 48,
      'nominalRate': 0.42,
      'evaluated': true,
      'decision': 'AUTO_APPROVED',
      'riskLevel': 'MEDIO',
      'preOffer': {
        'minAmount': 5000,
        'maxAmount': 90000,
        'minTerm': 6,
        'maxTerm': 36,
        'defaultTerm': 21,
        'nominalRate': 0.46,
      },
    }).toDomain();

    expect(item.approvedMaxAmount, 90000);
    expect(item.approvedMaxTerm, 36);
    expect(item.approvedRate, closeTo(0.46, 1e-9));
    expect(item.offer.maxAmount, 90000);
  });

  test('un producto sin preOffer no revienta el parseo', () {
    final item = PrequalifiedProductDto.fromJson({
      'code': 'RL',
      'name': 'Línea revolvente',
      'productType': 'REVOLVING_LINE',
      'behavior': 'REVOLVING',
      'evaluated': false,
      'skippedReason': 'NO_BUREAU_REPORT',
    }).toDomain();

    expect(item.hasPreOffer, isFalse);
    expect(item.approvedMaxAmount, isNull);
    expect(item.isAutoApproved, isFalse);
  });
}
