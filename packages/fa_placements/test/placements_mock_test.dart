import 'package:dio/dio.dart';
import 'package:fa_placements/fa_placements.dart';
import 'package:flutter_test/flutter_test.dart';

/// Ejercita el mock por su interfaz real (un `Dio` con el interceptor puesto),
/// no llamando a métodos privados: lo que hay que proteger es el contrato que
/// consume el repositorio, que es exactamente lo que el BFF va a tener que
/// cumplir.
void main() {
  late Dio dio;
  late List<PlacementMockEvent> events;

  setUp(() {
    PlacementsMockInterceptor.reset();
    events = [];
    dio = Dio(BaseOptions(baseUrl: 'http://mock'))
      ..interceptors.add(PlacementsMockInterceptor(onEvent: events.add));
  });

  /// El status de un request que debe fallar. El mock rechaza los 4xx como lo
  /// haría el BFF, así que aquí se verifica la excepción, no un código de
  /// retorno.
  Future<int?> statusOfFailure(Future<void> Function() call) async {
    try {
      await call();
      return null;
    } on DioException catch (e) {
      return e.response?.statusCode;
    }
  }

  group('línea del distribuidor', () {
    test('arranca con la línea sembrada y descuenta lo colocado', () async {
      final res = await dio.get('/distributor/line-summary');
      final body = res.data as Map<String, dynamic>;

      expect(body['authorized'], 250000);
      expect(body['placed'], greaterThan(0));
      expect(body['available'], body['authorized'] - body['placed']);
    });

    test('lo que se le debe a Kredius nunca es negativo', () async {
      final res = await dio.get('/distributor/line-summary');
      expect((res.data as Map)['dueToKredius'], greaterThanOrEqualTo(0));
    });
  });

  group('crear colocación', () {
    test('nace invitada, sin partyId y sin tocar la línea', () async {
      final before =
          (await dio.get('/distributor/line-summary')).data['available'] as num;

      final res = await dio.post('/placements', data: {
        'beneficiary': {
          'fullName': 'Rosa Elena Díaz',
          'phone': '5549029037',
          'relationship': 'Clienta de mi tienda',
        },
        'amount': 18000,
        'termFortnights': 24,
      });

      expect(res.statusCode, 201);
      final body = res.data as Map<String, dynamic>;
      expect(body['status'], 'invited');
      // Todavía no es un Party: no ha hecho su KYC.
      expect(body['beneficiaryPartyId'], isNull);
      expect(body['beneficiaryPhoneMask'], '55 •• •• 90 37');

      final after =
          (await dio.get('/distributor/line-summary')).data['available'] as num;
      expect(after, before,
          reason: 'invitar no debe apartar línea (Journey App L1375)');
    });

    test('rechaza un celular incompleto', () async {
      final status = await statusOfFailure(() => dio.post('/placements', data: {
            'beneficiary': {'fullName': 'Alguien', 'phone': '55490'},
            'amount': 5000,
            'termFortnights': 12,
          }));
      expect(status, 400);
    });

    test('rechaza un monto mayor a la línea disponible', () async {
      final status = await statusOfFailure(() => dio.post('/placements', data: {
            'beneficiary': {
              'fullName': 'Rosa Elena Díaz',
              'phone': '5549029037'
            },
            'amount': 900000,
            'termFortnights': 24,
          }));
      expect(status, 409);
    });

    test('avisa que la liga salió', () async {
      await dio.post('/placements', data: {
        'beneficiary': {'fullName': 'Rosa Elena Díaz', 'phone': '5549029037'},
        'amount': 18000,
        'termFortnights': 24,
      });
      expect(events.map((e) => e.kind),
          contains(PlacementMockEventKind.inviteSent));
    });
  });

  group('buró y decisión', () {
    test('el reporte no existe mientras el beneficiario no termina', () async {
      final created = await dio.post('/placements', data: {
        'beneficiary': {'fullName': 'Rosa Elena Díaz', 'phone': '5549029037'},
        'amount': 18000,
        'termFortnights': 24,
      });
      final id = created.data['placementId'] as String;

      final status = await statusOfFailure(() => dio.get('/placements/$id/bureau'));
      expect(status, 409,
          reason: 'un reporte vacío se leería como historial limpio');
    });

    test('aprobar descuenta la línea y avisa del depósito', () async {
      // La semilla ya trae colocaciones vivas; se aprueba una nueva sobre ellas.
      final created = await dio.post('/placements', data: {
        'beneficiary': {'fullName': 'Rosa Elena Díaz', 'phone': '5549029037'},
        'amount': 18000,
        'termFortnights': 24,
      });
      final id = created.data['placementId'] as String;
      final before =
          (await dio.get('/distributor/line-summary')).data['available'] as num;

      final approved = await dio.post('/placements/$id/approve',
          data: {'riskAcknowledged': true});

      expect(approved.data['status'], 'active');
      final after =
          (await dio.get('/distributor/line-summary')).data['available'] as num;
      expect(after, before - 18000);
      expect(events.map((e) => e.kind),
          contains(PlacementMockEventKind.disbursed));
    });

    test('no colocar cierra la colocación sin tocar la línea', () async {
      final created = await dio.post('/placements', data: {
        'beneficiary': {'fullName': 'Rosa Elena Díaz', 'phone': '5549029037'},
        'amount': 18000,
        'termFortnights': 24,
      });
      final id = created.data['placementId'] as String;
      final before =
          (await dio.get('/distributor/line-summary')).data['available'] as num;

      final res = await dio.post('/placements/$id/reject');

      expect(res.data['status'], 'declined');
      final after =
          (await dio.get('/distributor/line-summary')).data['available'] as num;
      expect(after, before);
    });
  });

  group('listas', () {
    test('las colocaciones sembradas incluyen atrasos de distinta gravedad',
        () async {
      final res = await dio.get('/placements');
      final list = (res.data['placements'] as List).cast<Map<String, dynamic>>();

      expect(list, isNotEmpty);
      expect(list.any((p) => (p['daysPastDue'] as int) == 0), isTrue);
      expect(list.any((p) => (p['daysPastDue'] as int) > 0), isTrue);
    });

    test('quien lleva 5 días de atraso no devenga comisión', () async {
      final res = await dio.get('/placements');
      final list = (res.data['placements'] as List).cast<Map<String, dynamic>>();
      final quemado =
          list.firstWhere((p) => (p['daysPastDue'] as int) >= 5);

      expect(quemado['commissionAccrued'], 0);
    });

    test('el directorio de beneficiarios responde con fichas completas',
        () async {
      final res = await dio.get('/beneficiaries');
      final list =
          (res.data['beneficiaries'] as List).cast<Map<String, dynamic>>();

      expect(list, isNotEmpty);
      for (final b in list) {
        expect(b['fullName'], isNotEmpty);
        expect(b['facts'], isNotEmpty);
      }
    });
  });

  test('una colocación inexistente responde 404, no un objeto vacío', () async {
    expect(await statusOfFailure(() => dio.get('/placements/no-existe')), 404);
  });
}
