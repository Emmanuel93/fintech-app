import 'dart:math' as math;

import 'package:dio/dio.dart';
import 'package:fa_core/fa_core.dart';

import '../../domain/services/placement_quote.dart';

/// Hechos del mock que el shell traduce a notificaciones.
enum PlacementMockEventKind {
  /// Se mandó la liga al beneficiario.
  inviteSent,

  /// El beneficiario terminó su verificación y ya hay buró que leer.
  bureauReady,

  /// El distribuidor aprobó y el dinero salió.
  disbursed,

  /// La liga venció sin que la completara.
  inviteExpired,
}

class PlacementMockEvent {
  const PlacementMockEvent({
    required this.kind,
    required this.placementId,
    required this.beneficiaryName,
    this.amount = 0,
  });

  final PlacementMockEventKind kind;
  final String placementId, beneficiaryName;
  final double amount;
}

/// Mock del dominio de colocación (flavor `mock`).
///
/// Espeja **path por path y campo por campo** el contrato propuesto en
/// `docs/KREDIUS_COLOCACION_PLAN.md` §6, que es el que el BFF va a exponer.
/// Conectar contra el backend real será sacar este interceptor de
/// `ShellInjection`, sin tocar repositorio, use cases ni pantallas.
///
/// No es una lista de respuestas fijas: mantiene la **máquina de estados** de
/// cada colocación y la hace avanzar con el reloj, porque el punto entero del
/// flujo es la espera — se manda una liga y se espera a que alguien más, en
/// otro teléfono, termine su verificación. Un mock que devolviera todo
/// aprobado escondería justo la parte que hay que diseñar bien.
class PlacementsMockInterceptor extends Interceptor {
  PlacementsMockInterceptor({this.onEvent});

  final void Function(PlacementMockEvent)? onEvent;

  /// Cuánto tarda el beneficiario en abrir la liga y terminar su KYC, en
  /// segundos de demo. En la vida real son horas; aquí tienen que caber en una
  /// corrida del journey sin volverse instantáneos —que sería mentir sobre la
  /// espera— ni eternos.
  static const int _secondsToKyc = 6;
  static const int _secondsToBureau = 14;

  /// La liga vive 7 días (L2066). En la demo se compara contra este mismo
  /// reloj acelerado sólo si la prueba lo fuerza con test-support.
  static const Duration inviteLifetime = Duration(days: 7);

  static final List<_MockPlacement> _placements = [];
  static bool _seeded = false;
  static final Set<String> _notified = {};

  /// Estado inicial de la línea, antes de descontar lo colocado (L711–L718).
  static const double _authorized = 250000;

  /// Reinicia el mock — lo usan los tests para no heredar estado entre casos.
  static void reset() {
    _placements.clear();
    _seeded = false;
    _notified.clear();
  }

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    final path = options.path;
    if (!_matches(path)) {
      handler.next(options);
      return;
    }
    _seed();
    Future.delayed(const Duration(milliseconds: 280), () {
      final (status, data) = _resolve(options);
      final response = Response(
        requestOptions: options,
        data: data,
        statusCode: status,
      );
      // Un 4xx tiene que **fallar** igual que fallaría contra el BFF: si el
      // mock lo resolviera como éxito, la capa de datos intentaría parsear un
      // `{message: …}` como colocación y el error saldría como un cast raro en
      // vez de como el mensaje que hay que enseñar.
      if (status >= 400) {
        handler.reject(DioException(
          requestOptions: options,
          response: response,
          type: DioExceptionType.badResponse,
          message: (data is Map ? data['message'] as String? : null) ??
              'Error $status',
        ));
        return;
      }
      handler.resolve(response);
    });
  }

  bool _matches(String p) =>
      p.startsWith('/placements') ||
      p.startsWith('/beneficiaries') ||
      p.startsWith('/distributor/');

  (int, dynamic) _resolve(RequestOptions req) {
    final path = req.path;
    final method = req.method.toUpperCase();
    _advanceClock();

    if (path == '/distributor/line-summary') return (200, _lineSummary());
    if (path == '/beneficiaries') return (200, _beneficiaries());

    if (path == '/placements') {
      if (method == 'POST') return _create(req);
      return (200, {'placements': _placements.map(_toJson).toList()});
    }

    final segments = path.split('/').where((s) => s.isNotEmpty).toList();
    if (segments.first != 'placements' || segments.length < 2) {
      return (404, {'message': 'No encontrado'});
    }
    final id = segments[1];
    final placement = _placements.where((p) => p.id == id).firstOrNull;
    if (placement == null) {
      return (404, {'message': 'Colocación no encontrada'});
    }

    final action = segments.length > 2 ? segments[2] : null;
    switch (action) {
      case null:
        return (200, _toJson(placement));
      case 'bureau':
        if (placement.status != 'bureauReady') {
          // El reporte no existe hasta que el beneficiario autorizó y se
          // consultó: devolver uno vacío haría creer que salió limpio.
          return (409, {
            'message': 'La verificación de ${placement.name} sigue en curso',
          });
        }
        return (200, _bureau(placement));
      case 'approve':
        placement.status = 'active';
        placement.placedOn = DateTime.now();
        _emit(PlacementMockEventKind.disbursed, placement);
        return (200, _toJson(placement));
      case 'reject':
        placement.status = 'declined';
        return (200, _toJson(placement));
      case 'resend':
        placement.createdAt = DateTime.now();
        placement.status = 'invited';
        return (200, _toJson(placement));
      case 'cancel':
        placement.status = 'cancelled';
        return (200, _toJson(placement));
      default:
        return (404, {'message': 'No encontrado'});
    }
  }

  // ── Creación ───────────────────────────────────────────────────────────────

  (int, dynamic) _create(RequestOptions req) {
    final body = (req.data as Map?)?.cast<String, dynamic>() ?? {};
    final beneficiary =
        (body['beneficiary'] as Map?)?.cast<String, dynamic>() ?? {};
    final name = (beneficiary['fullName'] as String? ?? '').trim();
    final phone = (beneficiary['phone'] as String? ?? '').trim();
    final amount = (body['amount'] as num?)?.toDouble() ?? 0;
    final term = (body['termFortnights'] as num?)?.toInt() ?? 24;

    if (name.isEmpty || phone.length < 10) {
      return (400, {'message': 'Faltan el nombre o el celular del beneficiario'});
    }
    if (amount > _available()) {
      return (409, {'message': 'El monto supera tu línea disponible'});
    }

    final placement = _MockPlacement(
      id: 'pl-${DateTime.now().millisecondsSinceEpoch}',
      name: name,
      phone: phone,
      relationship: body['beneficiary']?['relationship'] as String? ?? '',
      amount: amount,
      term: term,
      status: 'invited',
      createdAt: DateTime.now(),
    );
    _placements.insert(0, placement);
    _emit(PlacementMockEventKind.inviteSent, placement);
    return (201, _toJson(placement));
  }

  // ── Reloj: el beneficiario avanza solo ─────────────────────────────────────

  /// Mueve las colocaciones pendientes según el tiempo transcurrido desde que
  /// se mandó la liga. Se llama en cada request: no hay timers vivos, así que
  /// el mock no gotea si la pantalla se cierra.
  void _advanceClock() {
    final now = DateTime.now();
    for (final p in _placements) {
      if (p.status != 'invited' && p.status != 'kycInProgress') continue;
      final elapsed = now.difference(p.createdAt).inSeconds;
      if (elapsed >= _secondsToBureau) {
        if (p.status != 'bureauReady') {
          p.status = 'bureauReady';
          _emit(PlacementMockEventKind.bureauReady, p);
        }
      } else if (elapsed >= _secondsToKyc) {
        p.status = 'kycInProgress';
      }
    }
  }

  void _emit(PlacementMockEventKind kind, _MockPlacement p) {
    final key = '${kind.name}-${p.id}';
    if (!_notified.add(key)) return;
    onEvent?.call(PlacementMockEvent(
      kind: kind,
      placementId: p.id,
      beneficiaryName: p.name,
      amount: p.amount,
    ));
  }

  // ── Respuestas ─────────────────────────────────────────────────────────────

  static double _available() => math.max(0, _authorized - _placed());

  static double _placed() => _placements
      .where((p) => p.status == 'active' || p.status == 'approved')
      .fold<double>(0, (acc, p) => acc + p.amount);

  Map<String, dynamic> _lineSummary() {
    // Quien acaba de darse de alta **todavía no tiene línea**: la de colocación pasa por comité,
    // y el backend real responde `authorized: 0` hasta que se aprueba. El mock tiene que decir lo
    // mismo, o el home enseñaría una línea disponible encima de un "tu solicitud está en revisión".
    //
    // La señal es haber pasado por el alta en esta corrida (`prospectId`): quien entra con su
    // usuario es la distribuidora establecida de la semilla, que sí tiene línea.
    if (AppSession.instance.hasProspect) return _noLine();

    final vivas = _placements.where((p) => p.status == 'active').toList();
    final toCollect =
        vivas.fold<double>(0, (acc, p) => acc + p.quote.fortnightlyPayment);
    final commission = vivas.fold<double>(
        0,
        (acc, p) => acc +
            CommissionPolicy.onPayment(p.quote.fortnightlyPayment,
                    daysLate: p.daysPastDue) *
                p.paymentsMade);

    return {
      'authorized': _authorized,
      'placed': _placed(),
      'available': _available(),
      'toCollect': toCollect,
      // Lo que el distribuidor le debe a Kredius es lo cobrado menos su
      // bonificación: no se le cobra aparte, se le descuenta de lo que entrega.
      'dueToKredius': math.max(0, toCollect - (toCollect * CommissionPolicy.onTimeRate)),
      'commissionAccrued': commission,
      'nextDueDate': _nextFifth().toIso8601String(),
      'daysPastDue': 0,
    };
  }

  /// Sin línea autorizada. Mismo shape que el real: 200 con ceros, no un 404.
  static Map<String, dynamic> _noLine() => {
        'authorized': 0,
        'placed': 0,
        'available': 0,
        'toCollect': 0,
        'dueToKredius': 0,
        'commissionAccrued': 0,
        'nextDueDate': null,
        'daysPastDue': 0,
      };

  static DateTime _nextFifth() {
    final now = DateTime.now();
    return now.day < 5
        ? DateTime(now.year, now.month, 5)
        : DateTime(now.year, now.month + 1, 5);
  }

  Map<String, dynamic> _toJson(_MockPlacement p) => {
        'placementId': p.id,
        'beneficiaryName': p.name,
        'beneficiaryPhoneMask': _mask(p.phone),
        'beneficiaryPartyId':
            p.status == 'invited' || p.status == 'kycInProgress'
                ? null
                : 'party-${p.id}',
        'relationship': p.relationship,
        'amount': p.amount,
        'termFortnights': p.term,
        'fortnightlyPayment': p.quote.fortnightlyPayment,
        'status': p.status,
        'commissionAccrued': CommissionPolicy.onPayment(
                p.quote.fortnightlyPayment,
                daysLate: p.daysPastDue) *
            p.paymentsMade,
        'paymentsMade': p.paymentsMade,
        'daysPastDue': p.daysPastDue,
        'placedOn': p.placedOn?.toIso8601String(),
        'inviteExpiresAt': p.createdAt.add(inviteLifetime).toIso8601String(),
      };

  /// "5541829037" → "55 •• •• 90 37". Igual que la firma del contrato.
  static String _mask(String phone) {
    final d = phone.replaceAll(RegExp(r'\D'), '');
    if (d.length < 10) return phone;
    return '${d.substring(0, 2)} •• •• ${d.substring(6, 8)} ${d.substring(8)}';
  }

  /// Reporte del prototipo (L2016–L2032). El score se deriva del nombre para
  /// que cada beneficiario tenga el suyo y sea estable entre llamadas: un score
  /// que cambia al refrescar es un reporte en el que nadie confía.
  Map<String, dynamic> _bureau(_MockPlacement p) {
    final seed = p.name.codeUnits.fold<int>(0, (a, c) => a + c);
    final score = 520 + (seed % 280);
    final (band, label, title, description) = switch (score) {
      < 620 => (
          'low',
          'RIESGO ALTO',
          'Se ha atrasado seguido',
          'Trae dos créditos vencidos y varios atrasos mayores a 60 días en los '
              'últimos dos años. Colocarle es apostar tu línea.',
        ),
      < 700 => (
          'medium',
          'RIESGO MEDIO',
          'Paga, pero se ha atrasado',
          'Cumple con sus dos créditos actuales y trae un atraso de 29 días en '
              'los últimos dos años. No es un historial limpio ni uno malo.',
        ),
      _ => (
          'high',
          'RIESGO BAJO',
          'Paga puntual y sin sobresaltos',
          'Sus créditos están al corriente y no registra atrasos relevantes en '
              'los últimos dos años.',
        ),
    };

    return {
      'score': score,
      'band': band,
      'bandLabel': label,
      'title': title,
      'description': description,
      'facts': [
        {
          'label': 'Peor atraso en 24 meses',
          'value': band == 'high' ? 'Ninguno' : (band == 'medium' ? '29 días' : '94 días'),
          'tone': band == 'high' ? 'ok' : (band == 'medium' ? 'warn' : 'bad'),
        },
        {
          'label': 'Créditos vigentes',
          'value': band == 'low' ? '3, dos vencidos' : '2, ambos al corriente',
          'tone': band == 'low' ? 'bad' : 'ok',
        },
        {
          'label': 'Deuda contra su ingreso',
          'value': band == 'low' ? '71%' : '38%',
          'tone': band == 'low' ? 'bad' : 'ok',
        },
        {'label': 'Consultas en 6 meses', 'value': '2', 'tone': 'ok'},
        {
          'label': 'Recomendación de Kredius',
          'value': switch (band) {
            'high' => 'Colocar',
            'medium' => 'Colocar con reserva',
            _ => 'No colocar',
          },
          'tone': band == 'high' ? 'ok' : (band == 'medium' ? 'warn' : 'bad'),
        },
      ],
    };
  }

  Map<String, dynamic> _beneficiaries() {
    // Los que ya terminaron su KYC **en esta sesión** se suman al directorio
    // sembrado: es la prueba de que colocar deja ficha. Las colocaciones de la
    // semilla se excluyen porque su ficha ya está en `_seedBeneficiaries` con
    // el historial completo — incluirlas otra vez duplicaría a cada persona.
    final live = _placements
        .where((p) => !p.id.startsWith('pl-seed-'))
        .where((p) => !['invited', 'kycInProgress', 'cancelled', 'expired']
            .contains(p.status))
        .map((p) => {
              'partyId': 'party-${p.id}',
              'fullName': p.name,
              'phoneMask': _mask(p.phone),
              'summary': p.status == 'bureauReady' || p.status == 'declined'
                  ? 'Nueva · terminando su alta contigo'
                  : 'Colocación activa · ${p.term} quincenas',
              'status': switch (p.status) {
                'active' => 'active',
                'paidOff' => 'paidOff',
                _ => 'onboarding',
              },
              'placementsCount': 1,
              'facts': [
                {'label': 'Le has prestado', 'value': _money(p.amount)},
                {
                  'label': 'Saldo hoy',
                  'value': p.status == 'active' ? _money(p.amount) : '—',
                },
                {
                  'label': 'Te generaría',
                  'value': _money(p.quote.commissionIfAllOnTime),
                  'good': true,
                },
                {'label': 'Puntualidad', 'value': 'sin historial'},
              ],
            })
        .toList();

    return {'beneficiaries': [...live, ..._seedBeneficiaries]};
  }

  static String _money(double v) =>
      '\$${v.round().toString().replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+$)'), (m) => '${m[1]},')}';

  // ── Semilla ────────────────────────────────────────────────────────────────

  /// Cartera de arranque: sin ella la pestaña de Colocaciones nace vacía y no
  /// se puede ver cómo se comporta con atrasos y comisiones distintas.
  /// Son los mismos casos del prototipo (L2140–L2150).
  void _seed() {
    if (_seeded) return;
    _seeded = true;
    final now = DateTime.now();
    _placements.addAll([
      _MockPlacement(
        id: 'pl-seed-1',
        name: 'María Luisa Cortés',
        phone: '5541829037',
        relationship: 'Clienta de mi tienda desde 2023',
        amount: 45000,
        term: 24,
        status: 'active',
        createdAt: now.subtract(const Duration(days: 26)),
        placedOn: now.subtract(const Duration(days: 25)),
        paymentsMade: 18,
      ),
      _MockPlacement(
        id: 'pl-seed-2',
        name: 'Abarrotes La Luz',
        phone: '5539104488',
        relationship: 'Negocio vecino desde 2024',
        amount: 60000,
        term: 36,
        status: 'active',
        createdAt: now.subtract(const Duration(days: 46)),
        placedOn: now.subtract(const Duration(days: 45)),
        paymentsMade: 30,
      ),
      _MockPlacement(
        id: 'pl-seed-3',
        name: 'Ramiro Ocampo',
        phone: '5588213390',
        relationship: 'Cliente desde 2025',
        amount: 18000,
        term: 24,
        status: 'active',
        createdAt: now.subtract(const Duration(days: 15)),
        placedOn: now.subtract(const Duration(days: 14)),
        paymentsMade: 2,
        daysPastDue: 2,
      ),
      _MockPlacement(
        id: 'pl-seed-4',
        name: 'Carmen Alicia Ponce',
        phone: '5512094771',
        relationship: 'Clienta de mostrador',
        amount: 9000,
        term: 12,
        status: 'active',
        createdAt: now.subtract(const Duration(days: 9)),
        placedOn: now.subtract(const Duration(days: 8)),
        paymentsMade: 2,
      ),
      _MockPlacement(
        id: 'pl-seed-5',
        name: 'Julio César Manzo',
        phone: '5512760455',
        relationship: 'Cliente desde 2024',
        amount: 30000,
        term: 24,
        status: 'active',
        createdAt: now.subtract(const Duration(days: 20)),
        placedOn: now.subtract(const Duration(days: 19)),
        daysPastDue: 5,
      ),
    ]);
  }

  static const List<Map<String, dynamic>> _seedBeneficiaries = [
    {
      'partyId': 'party-seed-1',
      'fullName': 'María Luisa Cortés',
      'phoneMask': '55 •• •• 90 37',
      'summary': 'Clienta desde 2023 · 2 préstamos contigo',
      'status': 'active',
      'placementsCount': 2,
      'facts': [
        {'label': 'Le has prestado', 'value': '\$63,000'},
        {'label': 'Saldo hoy', 'value': '\$45,000'},
        {'label': 'Te ha generado', 'value': '\$3,240', 'good': true},
        {'label': 'Puntualidad', 'value': '100%', 'good': true},
      ],
    },
    {
      'partyId': 'party-seed-2',
      'fullName': 'Abarrotes La Luz',
      'phoneMask': '55 •• •• 44 88',
      'summary': 'Negocio · desde 2024 · 3 préstamos',
      'status': 'active',
      'placementsCount': 3,
      'facts': [
        {'label': 'Le has prestado', 'value': '\$140,000'},
        {'label': 'Saldo hoy', 'value': '\$60,000'},
        {'label': 'Te ha generado', 'value': '\$8,400', 'good': true},
        {'label': 'Puntualidad', 'value': '96%', 'good': true},
      ],
    },
    {
      'partyId': 'party-seed-3',
      'fullName': 'Ramiro Ocampo',
      'phoneMask': '55 •• •• 33 90',
      'summary': 'Cliente desde 2025 · 1 préstamo',
      'status': 'overdue',
      'placementsCount': 1,
      'facts': [
        {'label': 'Le has prestado', 'value': '\$18,000'},
        {'label': 'Saldo hoy', 'value': '\$18,000'},
        {'label': 'Te ha generado', 'value': '\$266'},
        {'label': 'Puntualidad', 'value': '78%', 'bad': true},
      ],
    },
    {
      'partyId': 'party-seed-5',
      'fullName': 'Julio César Manzo',
      'phoneMask': '55 •• •• 04 55',
      'summary': 'Liquidó en jun 2026 · 1 préstamo',
      'status': 'paidOff',
      'placementsCount': 1,
      'facts': [
        {'label': 'Le prestaste', 'value': '\$9,000'},
        {'label': 'Saldo hoy', 'value': '\$0'},
        {'label': 'Te generó', 'value': '\$1,800', 'good': true},
        {'label': 'Puntualidad', 'value': '100%', 'good': true},
      ],
    },
  ];
}

/// Estado mutable de una colocación dentro del mock.
class _MockPlacement {
  _MockPlacement({
    required this.id,
    required this.name,
    required this.phone,
    required this.relationship,
    required this.amount,
    required this.term,
    required this.status,
    required this.createdAt,
    this.placedOn,
    this.paymentsMade = 0,
    this.daysPastDue = 0,
  });

  final String id, name, phone, relationship;
  final double amount;
  final int term;
  String status;
  DateTime createdAt;
  DateTime? placedOn;
  int paymentsMade;
  int daysPastDue;

  PlacementQuote get quote =>
      PlacementQuote(amount: amount, termFortnights: term);
}
