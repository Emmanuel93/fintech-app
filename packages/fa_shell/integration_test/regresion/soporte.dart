/// Soporte común de la regresión E2E multi-proceso.
///
/// Un journey de punta a punta cruza tres procesos —simulador, Chromium y el reloj del backend—
/// y ninguno puede correr dentro de otro. El orquestador (`fintech-services/tools/regresion-e2e`)
/// los encadena en actos, y necesita recuperar datos de cada acto para preparar el siguiente.
///
/// El canal de vuelta es **stdout**: el simulador vive en su propio sandbox y no comparte disco
/// con la Mac, así que un archivo temporal no sirve. Cada test imprime `##HANDOFF## clave=valor`
/// y el orquestador lo lee con `grep`.
library;

import 'dart:convert';
import 'package:http/http.dart' as http;

const bffUrl = String.fromEnvironment(
  'RE2E_BFF_URL',
  defaultValue: 'http://mobile.localhost:8090',
);

/// Credenciales que inyecta el orquestador en los actos posteriores al alta.
const rePhone = String.fromEnvironment('RE2E_PHONE');
const rePassword = String.fromEnvironment('RE2E_PASSWORD');

/// `liquidar` o `mora` — decide el desenlace del acto de seguimiento.
const reDesenlace = String.fromEnvironment('RE2E_DESENLACE', defaultValue: 'liquidar');

void handoff(String clave, String valor) {
  // ignore: avoid_print
  print('##HANDOFF## $clave=$valor');
}

void paso(String mensaje) {
  // ignore: avoid_print
  print('[RE2E] $mensaje');
}

// ── Cliente HTTP contra el BFF ───────────────────────────────────────────────
//
// Sesión aparte de la de la app, a propósito: sirve para *comprobar* lo que la pantalla dice,
// no para producirlo. Si el saldo de la app y el del BFF discrepan, esta segunda sesión es la
// que lo revela.

Future<String> loginHttp(String phone, String password) async {
  final r = await http.post(
    Uri.parse('$bffUrl/auth/login'),
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode({'phone': phone, 'password': password, 'deviceId': 're2e'}),
  );
  if (r.statusCode != 200) {
    throw StateError('login HTTP ${r.statusCode}: ${r.body}');
  }
  final token = (jsonDecode(r.body) as Map<String, dynamic>)['token'] as String?;
  if (token == null || token.isEmpty) throw StateError('login sin token: ${r.body}');
  return token;
}

Map<String, String> _auth(String token) => {'Authorization': 'Bearer $token'};

Future<List<dynamic>> solicitudes(String token) async {
  final r = await http.get(Uri.parse('$bffUrl/credit/applications'), headers: _auth(token));
  if (r.statusCode != 200) return const [];
  return _lista(jsonDecode(r.body));
}

/// El BFF a veces devuelve una lista y a veces una página. Normalizar aquí evita repetir el
/// mismo `if` en cada test — y que uno se olvide.
List<dynamic> _lista(dynamic cuerpo) {
  if (cuerpo is List) return cuerpo;
  if (cuerpo is Map) {
    for (final k in const ['content', 'applications', 'items', 'placements', 'data']) {
      final v = cuerpo[k];
      if (v is List) return v;
    }
  }
  return const [];
}

Future<Map<String, dynamic>?> cuentaDeCredito(String token) async {
  final r = await http.get(Uri.parse('$bffUrl/credit/account'), headers: _auth(token));
  if (r.statusCode != 200) return null;
  final cuerpo = jsonDecode(r.body);
  final lista = cuerpo is List ? cuerpo : [cuerpo];
  return lista.isEmpty ? null : lista.first as Map<String, dynamic>;
}

Future<List<dynamic>> colocaciones(String token) async {
  final r = await http.get(Uri.parse('$bffUrl/placements'), headers: _auth(token));
  if (r.statusCode != 200) return const [];
  return _lista(jsonDecode(r.body));
}

Future<Map<String, dynamic>?> resumenLinea(String token) async {
  final r = await http.get(Uri.parse('$bffUrl/distributor/line-summary'), headers: _auth(token));
  if (r.statusCode != 200) return null;
  return jsonDecode(r.body) as Map<String, dynamic>;
}

Future<void> pagar(String token, double monto) async {
  final r = await http.post(
    Uri.parse('$bffUrl/credit/payment'),
    headers: {..._auth(token), 'Content-Type': 'application/json'},
    body: jsonEncode({'amount': monto}),
  );
  if (r.statusCode >= 300) throw StateError('pago HTTP ${r.statusCode}: ${r.body}');
}

/// Empuja los datos de identificación del journey a stdout.
/// Se llama al final de cada acto de alta, con la sesión HTTP recién creada.
Future<void> publicarIdentificadores({
  required String phone,
  required String password,
}) async {
  handoff('PHONE', phone);
  handoff('PASSWORD', password);

  final token = await loginHttp(phone, password);
  final apps = await solicitudes(token);
  if (apps.isEmpty) {
    paso('⚠️ el BFF no devolvió solicitudes — el orquestador no podrá continuar');
    return;
  }
  final ultima = apps.first as Map<String, dynamic>;
  final id = ultima['applicationId'] ?? ultima['id'];
  final prospect = ultima['prospectId'];
  if (id != null) handoff('APPLICATION_ID', '$id');
  if (prospect != null) handoff('PROSPECT_ID', '$prospect');
  paso('Solicitud $id · prospecto $prospect · estado ${ultima['status']}');
}
