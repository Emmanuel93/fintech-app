/// El ciclo que se demuestra: se otorga, devenga, vence, cae en mora y se cura
/// pagando. Contra el mock, con los mismos endpoints de soporte que expone el
/// BFF — si el guion sirve aquí, sirve conectado.
library;

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fa_credit/src/infrastructure/mock/credit_mock_interceptor.dart';

late Dio _dio;
final _eventos = <CreditMockEvent>[];

Future<Map<String, dynamic>> _post(String path,
    {Object? data, Map<String, dynamic>? query}) async {
  final res = await _dio.post<dynamic>(path, data: data ?? {},
      queryParameters: query);
  return Map<String, dynamic>.from(res.data as Map);
}

Future<Map<String, dynamic>> _cuenta() async {
  final res = await _dio.get<dynamic>('/credit/account');
  final list = res.data as List;
  return Map<String, dynamic>.from(list.first as Map);
}

/// Otorga un crédito a plazo: la firma es la que desembolsa.
Future<void> _otorgar({int term = 12, double amount = 60000}) async {
  final app = await _post('/credit/applications', data: {
    'requestedAmount': amount,
    'requestedTerm': term,
    'productType': 'PERSONAL_LOAN',
  });
  await _post('/credit/applications/${app['applicationId']}/contract/sign',
      data: {'signatureProof': '123456'});
}

/// Empuja el reloj de demo para que el pago que toca venza hace [dias].
Future<void> _vencerHace(int dias) => _post(
      '/internal/test-support/accounts/acc-1/installments/1/shift-due-date',
      query: {'daysFromToday': -dias},
    );

void main() {
  tearDownAll(() => CreditMockInterceptor.daysPerRealSecond = 1);

  setUp(() {
    CreditMockInterceptor.reset();
    // Reloj congelado: el tiempo sólo avanza cuando la prueba lo pide.
    CreditMockInterceptor.daysPerRealSecond = 0;
    _eventos.clear();
    _dio = Dio()
      ..interceptors.add(CreditMockInterceptor(onEvent: _eventos.add));
  });

  test('recién otorgado está al corriente y sin atraso', () async {
    await _otorgar();
    final c = await _cuenta();

    expect(c['status'], 'ACTIVE');
    expect(c['daysPastDue'], 0);
    expect(c['overdueAmount'], 0);
    expect(c['paymentsMade'], 0);
    expect(c['assignedTerm'], 12);
  });

  test('devengar sin pagar hasta pasar el vencimiento deja EN MORA', () async {
    await _otorgar();
    await _vencerHace(5);

    final c = await _cuenta();
    expect(c['status'], 'PAST_DUE',
        reason: 'pasado el vencimiento sin pagar, el estado no es al corriente');
    expect(c['daysPastDue'], 5);
    expect((c['overdueAmount'] as num).toDouble(),
        greaterThan((c['minimumPayment'] as num).toDouble()),
        reason: 'lo vencido incluye la mensualidad más los moratorios');
  });

  test('los moratorios corren con los días de atraso', () async {
    await _otorgar();
    await _vencerHace(3);
    final tres = (await _cuenta())['overdueAmount'] as num;

    await _vencerHace(30);
    final treinta = (await _cuenta())['overdueAmount'] as num;

    expect(treinta, greaterThan(tres),
        reason: 'más días de mora, más moratorios');
  });

  test('pagar cura la mora y mueve el vencimiento al siguiente', () async {
    await _otorgar();
    await _vencerHace(4);
    expect((await _cuenta())['status'], 'PAST_DUE');

    await _post('/credit/payment', data: {'amount': 6000});

    final c = await _cuenta();
    expect(c['status'], 'ACTIVE', reason: 'pagar pone al corriente');
    expect(c['daysPastDue'], 0);
    expect(c['paymentsMade'], 1);
  });

  test('el corte avisa distinto según haya vencido o no', () async {
    await _otorgar();

    await _post('/internal/test-support/run-installment-due-job');
    expect(_eventos.last.kind, CreditMockEventKind.installmentDue,
        reason: 'sin atraso, el aviso es de vencimiento próximo');

    await _vencerHace(2);
    await _post('/internal/test-support/run-installment-due-job');
    expect(_eventos.last.kind, CreditMockEventKind.installmentOverdue);
    expect(_eventos.last.daysPastDue, 2);
  });

  test('el devengo diario mueve el saldo sin esperar en tiempo real', () async {
    await _otorgar();
    final antes = (await _cuenta())['pendingBalance'] as num;

    await _post('/internal/test-support/run-daily-accrual',
        query: {'days': 20});

    final despues = (await _cuenta())['pendingBalance'] as num;
    expect(despues, greaterThan(antes),
        reason: 'veinte días de interés tienen que verse');
  });

  test('liquidado no puede caer en mora aunque el reloj siga', () async {
    await _otorgar(term: 3, amount: 30000);
    for (var i = 0; i < 3; i++) {
      await _post('/credit/payment', data: {'amount': 10500});
    }
    expect((await _cuenta())['status'], 'PAID_OFF');

    await _post('/internal/test-support/run-daily-accrual',
        query: {'days': 90});

    final c = await _cuenta();
    expect(c['status'], 'PAID_OFF', reason: 'ya no se debe nada');
    expect(c['daysPastDue'], 0);
  });
}
