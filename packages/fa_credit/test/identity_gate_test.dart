import 'package:dio/dio.dart';
import 'package:fa_credit/src/domain/entities/identity_not_verified.dart';
import 'package:fa_credit/src/infrastructure/adapters/credit_repository_impl.dart';
import 'package:flutter_test/flutter_test.dart';

DioException _respuesta(int status, Object? data) {
  final req = RequestOptions(path: '/credit/applications');
  return DioException(
    requestOptions: req,
    response: Response(requestOptions: req, statusCode: status, data: data),
    type: DioExceptionType.badResponse,
  );
}

void main() {
  group('Compuerta de identidad', () {
    test('el 422 de la compuerta se reconoce, con sus estados', () {
      final hold = identityGateOf(_respuesta(422, {
        'type': 'https://fintech.com/errors/ORIGINATION_PERSON_NOT_VERIFIED',
        'status': 422,
        'identityStatus': 'IN_REVIEW',
        'screeningStatus': 'CLEARED',
      }));

      expect(hold, isA<IdentityNotVerified>());
      expect(hold!.identityStatus, 'IN_REVIEW');
      expect(hold.isFinal, isFalse, reason: 'en revisión se espera, no es un no');
    });

    test('identidad rechazada o coincidencia confirmada: esperar no lo cambia', () {
      expect(
        identityGateOf(_respuesta(422, {
          'type': 'https://fintech.com/errors/ORIGINATION_PERSON_NOT_VERIFIED',
          'identityStatus': 'REJECTED',
        }))!.isFinal,
        isTrue,
      );
      expect(
        identityGateOf(_respuesta(422, {
          'type': 'https://fintech.com/errors/ORIGINATION_PERSON_NOT_VERIFIED',
          'identityStatus': 'VERIFIED',
          'screeningStatus': 'CONFIRMED_MATCH',
        }))!.isFinal,
        isTrue,
      );
    });

    test('otro 422 —periodo de espera, monto— no se confunde con la compuerta', () {
      expect(
        identityGateOf(_respuesta(422, {
          'type': 'https://fintech.com/errors/ORIGINATION_COOLDOWN_ACTIVE',
          'status': 422,
        })),
        isNull,
      );
    });

    test('un error que no es 422 o sin cuerpo tampoco', () {
      expect(identityGateOf(_respuesta(500, {'type': 'x'})), isNull);
      expect(identityGateOf(_respuesta(422, 'texto')), isNull);
    });
  });
}
