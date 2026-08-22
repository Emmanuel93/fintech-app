import 'package:dio/dio.dart';

class AuthMockInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    final path = options.path;
    if (path == '/auth/login' ||
        path == '/auth/logout' ||
        path == '/auth/register') {
      Future.delayed(_delay(path), () {
        handler.resolve(Response(
          requestOptions: options,
          data: _resolve(options),
          statusCode: 200,
        ));
      });
      return;
    }
    handler.next(options);
  }

  Map<String, dynamic> _resolve(RequestOptions req) {
    final path = req.path;
    if (path == '/auth/login') return _login(req.data as Map?);
    if (path == '/auth/logout') return {'success': true};
    if (path == '/auth/register') {
      return {
        'success': true,
        'prospectId': 'prs_emf_001',
        'message': 'Prospecto creado',
      };
    }
    return {'success': true};
  }

  Map<String, dynamic> _login(Map? body) {
    final phone = body?['phone'] as String? ?? '';
    final password = body?['password'] as String? ?? '';
    if (phone.isNotEmpty && password.length >= 6) {
      return {
        'success': true,
        'accessToken': 'mock_jwt_token_emf_001',
        'token': 'mock_jwt_token_emf_001',
        'refreshToken': 'mock_refresh_token_emf_001',
        'tokenType': 'Bearer',
        'userId': 'usr_emf_001',
        'expiresIn': 3600,
      };
    }
    throw Exception('Credenciales inválidas');
  }

  Duration _delay(String path) {
    if (path.contains('/auth/login')) return const Duration(milliseconds: 700);
    return const Duration(milliseconds: 200);
  }
}
