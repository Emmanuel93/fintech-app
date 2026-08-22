/// El mock es lo que se demuestra y lo que se prueba: si su preoferta no es
/// coherente, el configurador deja armar préstamos que el scoring no autorizó.
library;

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fa_credit/src/infrastructure/mock/credit_mock_interceptor.dart';

Future<Map<String, dynamic>> _get(String path, {Object? data}) async {
  final dio = Dio()..interceptors.add(CreditMockInterceptor());
  final res = await dio.request<dynamic>(
    path,
    data: data,
    options: Options(method: data == null ? 'GET' : 'POST'),
  );
  return Map<String, dynamic>.from(res.data as Map);
}

void main() {
  setUp(CreditMockInterceptor.reset);

  test('cada producto precalificado trae su preoferta', () async {
    final res = await _get('/credit/prequalification');
    final products = (res['products'] as List).cast<Map<String, dynamic>>();
    expect(products, isNotEmpty);

    for (final p in products) {
      final offer = p['preOffer'] as Map<String, dynamic>?;
      expect(offer, isNotNull, reason: '${p['code']} sin preoferta');
      expect(offer!['maxAmount'], isNotNull,
          reason: '${p['code']} sin monto autorizado');
    }
  });

  test('un revolvente no recibe un plazo inventado', () async {
    // El catálogo no le publica plazo: fabricarle uno haría que el
    // configurador pidiera elegir mensualidades de una línea que no las tiene.
    final res = await _get('/credit/prequalification');
    final revolvente = (res['products'] as List)
        .cast<Map<String, dynamic>>()
        .firstWhere((p) => p['behavior'] == 'REVOLVING');

    expect(revolvente['maxTerm'], isNull, reason: 'premisa del catálogo');
    final offer = revolvente['preOffer'] as Map<String, dynamic>;
    expect(offer.containsKey('maxTerm'), isFalse);
    expect(offer.containsKey('defaultTerm'), isFalse);
    expect(offer['maxAmount'], isNotNull,
        reason: 'sí tiene línea autorizada, aunque no plazo');
  });

  test('la preoferta nunca excede el rango del catálogo', () async {
    final res = await _get('/credit/prequalification');
    for (final p in (res['products'] as List).cast<Map<String, dynamic>>()) {
      final offer = p['preOffer'] as Map<String, dynamic>;
      final catMax = (p['maxAmount'] as num).toDouble();

      expect((offer['maxAmount'] as num).toDouble(), lessThanOrEqualTo(catMax),
          reason: '${p['code']} ofrece más de lo que el producto permite');
      expect((offer['maxAmount'] as num).toDouble(),
          greaterThanOrEqualTo((p['minAmount'] as num).toDouble()));

      final catMaxTerm = (p['maxTerm'] as num?)?.toInt();
      if (catMaxTerm != null) {
        expect((offer['maxTerm'] as num).toInt(), lessThanOrEqualTo(catMaxTerm));
      }
    }
  });

  test('el tope cae en un escalón del slider', () async {
    // Un tope de \$92.400 con paso de \$5.000 no lo puede alcanzar el control.
    final res = await _get('/credit/prequalification');
    for (final p in (res['products'] as List).cast<Map<String, dynamic>>()) {
      final step = (p['amountStep'] as num?)?.toInt();
      if (step == null) continue;
      final max = (p['preOffer'] as Map)['maxAmount'] as num;
      expect(max % step, 0,
          reason: '${p['code']}: \$$max no cae en pasos de \$$step');
    }
  });

  test('más riesgo, menos monto y más tasa', () async {
    final res = await _get('/credit/prequalification');
    final products = (res['products'] as List).cast<Map<String, dynamic>>();

    final bajo = products.firstWhere((p) => p['riskLevel'] == 'BAJO');
    final medio = products.firstWhere((p) => p['riskLevel'] == 'MEDIO');

    // A riesgo bajo se abre el producto completo.
    expect((bajo['preOffer'] as Map)['maxAmount'], bajo['maxAmount']);
    expect((bajo['preOffer'] as Map)['nominalRate'], bajo['nominalRate']);

    // A riesgo medio se recorta y se encarece.
    final offerMedio = medio['preOffer'] as Map;
    expect((offerMedio['maxAmount'] as num).toDouble(),
        lessThan((medio['maxAmount'] as num).toDouble()));
    expect((offerMedio['nominalRate'] as num).toDouble(),
        greaterThan((medio['nominalRate'] as num).toDouble()));
  });

  /// Solicita y firma un crédito a plazo — es la firma la que desembolsa y
  /// deja la cuenta viva.
  Future<void> otorgarCredito({int term = 12, double amount = 60000}) async {
    final app = await _get('/credit/applications', data: {
      'requestedAmount': amount,
      'requestedTerm': term,
      'productType': 'PERSONAL_LOAN',
    });
    await _get('/credit/applications/${app['applicationId']}/contract/sign',
        data: {'signatureProof': '123456'});
  }

  test('los pagos avanzan el contador y liquidan sin pasarse', () async {
    await otorgarCredito();

    for (var i = 0; i < 12; i++) {
      await _get('/credit/payment', data: {'amount': 6000});
    }

    final dio = Dio()..interceptors.add(CreditMockInterceptor());
    final res = await dio.get<dynamic>('/credit/account');
    final account = Map<String, dynamic>.from((res.data as List).first as Map);

    expect(account['paymentsMade'], 12);
    expect(account['remainingPayments'], 0);
    expect(account['status'], 'PAID_OFF');
    expect((account['pendingBalance'] as num).toDouble(), 0,
        reason: 'liquidado significa que ya no se debe nada');
    expect((account['principalPaid'] as num).toDouble(), closeTo(60000, 0.01),
        reason: 'no se amortiza más capital del prestado');
  });

  test('el vencimiento se recorre con cada pago', () async {
    await otorgarCredito();

    final dio = Dio()..interceptors.add(CreditMockInterceptor());
    Future<DateTime> vence() async {
      final res = await dio.get<dynamic>('/credit/account');
      final account = Map<String, dynamic>.from((res.data as List).first as Map);
      return DateTime.parse(account['paymentDueDate'] as String);
    }

    final antes = await vence();
    await _get('/credit/payment', data: {'amount': 6000});
    final despues = await vence();

    // Quedarse en la misma fecha después de pagar hace dudar de que el pago
    // haya entrado — es lo primero que el usuario mira en el home.
    expect(despues.isAfter(antes), isTrue);
  });
}
