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

/// Marca el inicio de un momento de la historia del video comercial.
///
/// El orquestador lee estas líneas mientras el test corre y anota cuándo ocurrió cada una
/// respecto al inicio de la grabación; con eso el panel del video ilumina el paso correcto en el
/// momento correcto. Las claves son fijas por acto y el texto que ve el cliente vive en
/// `une-video.sh`, no aquí: el copy se ajusta sin tocar las pruebas.
void historia(String clave) {
  // ignore: avoid_print
  print('##HISTORIA## $clave');
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

/// El adeudo cuando deja de moverse: dos lecturas iguales con 4 s de diferencia (tope 2 min).
///
/// Los días de devengo que adelanta el reloj de prueba llegan a cartera por Kafka uno a uno; con
/// las JVM en frío entran a ~1 por segundo. Pagar el adeudo leído a mitad de esa fila deja
/// remanente y la cuenta no se liquida —la corrida del 2026-10-31 quedó ACTIVE tras pagar—.
Future<double> adeudoEstable(String token) async {
  double? previo;
  double actual = 0;
  for (var i = 0; i < 30; i++) {
    final cuenta = await cuentaDeCredito(token);
    actual = (cuenta?['totalDebt'] as num?)?.toDouble() ?? 0;
    if (previo != null && (actual - previo).abs() < 0.005) return actual;
    previo = actual;
    await Future<void>.delayed(const Duration(seconds: 4));
  }
  return actual;
}

/// Paga la cuenta hasta dejarla en cero, por el canal de la app, y devuelve cuánto se pagó.
///
/// Se paga lo que se debe cuando el devengo ya terminó de llegar, y se vuelve a leer por si algo
/// entró después: el pago tampoco es instantáneo en cartera.
Future<double> liquidar(String token) async {
  var pagado = 0.0;
  for (var intento = 0; intento < 5; intento++) {
    final deuda = await adeudoEstable(token);
    if (deuda <= 0.009) break;
    await pagar(token, deuda);
    pagado += deuda;
    paso('Pago ${intento + 1} por el canal de la app: \$${deuda.toStringAsFixed(2)}');
  }
  return pagado;
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
