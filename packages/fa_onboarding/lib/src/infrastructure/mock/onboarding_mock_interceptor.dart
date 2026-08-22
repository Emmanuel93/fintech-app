import 'package:dio/dio.dart';

class OnboardingMockInterceptor extends Interceptor {
  static const _paths = {'/otp/send', '/otp/verify', '/otp/resend', '/kyc/submit', '/ocr/extract'};

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    if (!_paths.contains(options.path)) {
      handler.next(options);
      return;
    }
    Future.delayed(_delay(options.path), () {
      try {
        handler.resolve(Response(
          requestOptions: options,
          data: _resolve(options),
          statusCode: 200,
        ));
      } catch (e) {
        handler.reject(DioException(
          requestOptions: options,
          error: e.toString(),
          type: DioExceptionType.badResponse,
        ));
      }
    });
  }

  Map<String, dynamic> _resolve(RequestOptions req) {
    switch (req.path) {
      case '/otp/send':
      case '/otp/resend':
        return {'success': true, 'message': 'OTP enviado'};
      case '/otp/verify':
        final code = (req.data as Map?)?['code'] as String? ?? '';
        final ok = code == '123456';
        return {
          'success': ok,
          'verified': ok,
          if (ok) 'preAuthToken': 'mock_preauth_token',
        };
      case '/kyc/submit':
        return {
          'success': true,
          'folioKyc': 'KYC-${DateTime.now().millisecondsSinceEpoch.toString().substring(6)}',
        };
      case '/ocr/extract':
        return _ocrMock();
      default:
        return {'success': true};
    }
  }

  Map<String, dynamic> _ocrMock() => {
        'success': true,
        'nombres': 'EMMANUEL FRANCISCO',
        'apellidoPaterno': 'RAMÍREZ',
        'apellidoMaterno': 'HERNÁNDEZ',
        'curp': 'RAHE930326HSMLRM09',
        'fechaNacimiento': '26/03/1993',
        'domicilio': 'COL. VILLA UNIVERSIDAD, CULIACÁN, SINALOA 80060',
        'clave': '9300326SL0001234',
        'vigencia': '2031',
        'genero': 'H',
        'estadoNacimiento': 'Sinaloa',
        'folio': 'IDMX${DateTime.now().millisecondsSinceEpoch.toString().substring(6)}',
      };

  Duration _delay(String path) {
    if (path.contains('/kyc')) return const Duration(milliseconds: 1400);
    if (path.contains('/ocr')) return const Duration(milliseconds: 900);
    return const Duration(milliseconds: 500);
  }
}
