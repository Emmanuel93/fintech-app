import 'dart:convert';
import 'package:http/http.dart' as http;

/// Sonda inteligente del BFF, a través del gateway.
///
/// Apunta al gateway y no al BFF directo: desde que existe la capa de entrada, el
/// BFF ya no publica puerto al host, así que sondear :8085 respondía siempre que no
/// hay backend y el caso conectado se saltaba en silencio.
///
/// No basta con que el servicio responda — valida que el flujo OTP
/// devuelva `preAuthToken`. Esto detecta containers con imagen vieja
/// que no tienen el contrato actualizado (backend "up pero stale").
///
/// Resultado:
///   [BackendMode.local]  → BFF up + OTP retorna preAuthToken correctamente
///   [BackendMode.mock]   → BFF caído, sin preAuthToken, o configuración incorrecta
class BackendProbe {
  static const _bffUrl = 'http://mobile.localhost:8090';
  static const _gatewayHealthUrl = 'http://localhost:8090/health';
  static const _timeout = Duration(seconds: 4);

  // Teléfono de prueba exclusivo del probe (distinto a los tests)
  static const _probePhone = '5500000000';

  static BackendMode? _cachedMode;
  static String? _cachedReason;

  static Future<BackendMode> detect() async {
    if (_cachedMode != null) return _cachedMode!;

    try {
      // 1 — Health check básico
      // El health del gateway, no el del BFF: `/actuator/**` va por el catch-all y exige JWT,
      // así que sondearlo devolvía 401 y el probe concluía «no hay backend» con el stack arriba.
      final health = await http
          .get(Uri.parse(_gatewayHealthUrl))
          .timeout(_timeout);
      if (health.statusCode != 200) {
        return _miss('El gateway retornó ${health.statusCode}');
      }

      // 2 — Enviar OTP al teléfono del probe
      final send = await http.post(
        Uri.parse('$_bffUrl/otp/send'),
        headers: const {'Content-Type': 'application/json'},
        body: jsonEncode({'phone': _probePhone}),
      ).timeout(_timeout);

      // 429 = OTP activo previo (aceptable — el código dev sigue válido)
      if (send.statusCode != 200 && send.statusCode != 429) {
        return _miss('OTP send retornó ${send.statusCode}');
      }

      // 3 — Verificar con código dev (123456)
      final verify = await http.post(
        Uri.parse('$_bffUrl/otp/verify'),
        headers: const {'Content-Type': 'application/json'},
        body: jsonEncode({'phone': _probePhone, 'code': '123456'}),
      ).timeout(_timeout);

      if (verify.statusCode != 200) {
        return _miss('OTP verify retornó ${verify.statusCode}');
      }

      final body = jsonDecode(verify.body) as Map<String, dynamic>;
      final verified = body['verified'] as bool? ?? false;
      final preAuthToken = body['preAuthToken'] as String?;

      if (!verified || preAuthToken == null || preAuthToken.isEmpty) {
        return _miss(
          'OTP verify no retornó preAuthToken '
          '(verified=$verified, preAuthToken=$preAuthToken). '
          'Posible imagen Docker vieja — reconstruye con docker compose build.',
        );
      }

      _cachedReason = 'BFF up + OTP flow OK';
      _cachedMode = BackendMode.local;
      return BackendMode.local;
    } catch (e) {
      return _miss('Excepción: $e');
    }
  }

  static BackendMode _miss(String reason) {
    _cachedReason = reason;
    _cachedMode = BackendMode.mock;
    return BackendMode.mock;
  }

  static String get reason => _cachedReason ?? 'no detectado';

  static void reset() {
    _cachedMode = null;
    _cachedReason = null;
  }
}

enum BackendMode {
  local('LOCAL — gateway en mobile.localhost:8090'),
  mock('MOCK — interceptores Dio (sin backend)');

  const BackendMode(this.label);
  final String label;
}
