import 'dart:math' as math;

import 'package:dio/dio.dart';

/// Mock del flujo de crédito alineado a ADR-001 (persona ≠ crédito).
///
/// Estado inicial: el prospecto NO tiene cuenta de crédito → `/credit/account`
/// responde vacío y el Home muestra el CTA "Solicitar crédito". Tras crear una
/// aplicación y que el scoring la apruebe (polling), `_hasAccount` se enciende y
/// `/credit/account` empieza a devolver la cuenta.
class CreditMockInterceptor extends Interceptor {
  CreditMockInterceptor({this.onEvent});

  /// Aviso de que algo relevante pasó en el crédito, para que quien lo conecte
  /// pueda reaccionar — el shell lo enchufa al mock de notificaciones. No se
  /// importa `fa_notifications` desde aquí: los módulos no se conocen entre sí.
  final void Function(CreditMockEvent event)? onEvent;

  static const _staticPaths = {
    '/credit/account',
    '/credit/payment',
    '/credit/dispose',
    '/credit/products',
    '/credit/applications',
    '/credit/prequalification',
  };

  // Estado en memoria del mock.
  static bool _hasAccount = false;
  static final Map<String, int> _pollCounts = {};

  // ── Crédito otorgado y su devengo ────────────────────────────────────────
  //
  // Lo que se firmó, para que `/credit/account` deje de responder ceros y
  // devuelva el crédito real del usuario.
  static double _principal = 0;
  static int _term = 0;
  static double _annualRate = 0.42;
  static String _productType = 'PERSONAL_LOAN';
  static String _behavior = 'INSTALLMENT';
  static DateTime? _disbursedAt;
  static double _paidPrincipal = 0;
  static int _paymentsMade = 0;

  /// **Reloj de demo**: cada cuántos segundos reales pasa un día.
  ///
  /// Dos segundos por día: el devengo se ve moverse en una demo de minutos y,
  /// a la vez, una corrida completa no cruza sola el primer vencimiento. Que
  /// el crédito caiga en mora tiene que ser una decisión de la prueba —con el
  /// endpoint de soporte— y no un accidente del cronómetro.
  static const int _secondsPerDay = 2;

  /// Cuántos días de devengo vale cada segundo real.
  ///
  /// Sin esto no hay nada que ver — un crédito real mueve su saldo en semanas,
  /// y una demo dura minutos. Sólo afecta al flavor mock: en QA y producción
  /// este interceptor ni se registra.
  ///
  /// Las pruebas lo ponen en 0 para **congelarlo**: con el reloj corriendo, dos
  /// llamadas seguidas caen en días distintos y cualquier aserción sobre días
  /// de atraso se vuelve una carrera contra el segundero. Congelado, el tiempo
  /// sólo avanza cuando la prueba lo pide por el endpoint de soporte.
  static int daysPerRealSecond = 1;

  /// Días transcurridos en el reloj de demo desde el desembolso.
  static int get _elapsedDays {
    final from = _disbursedAt;
    if (from == null) return 0;
    return (DateTime.now().difference(from).inSeconds ~/ _secondsPerDay) *
            daysPerRealSecond +
        _shiftedDays;
  }

  /// La fecha "de hoy" según el reloj de demo.
  ///
  /// Todo lo que dependa del calendario —vencimientos, mora, corte— tiene que
  /// mirar este reloj y no el del teléfono. Si el devengo corre acelerado y los
  /// vencimientos no, el crédito nunca se atrasa y la mora es inobservable.
  static DateTime get _simulatedNow =>
      (_disbursedAt ?? DateTime.now()).add(Duration(days: _elapsedDays));

  /// Interés devengado desde el desembolso, con la tasa diaria del producto.
  static double get _accruedInterest {
    if (_disbursedAt == null || _principal <= 0) return 0;
    final outstanding = (_principal - _paidPrincipal).clamp(0.0, _principal);
    return outstanding * (_annualRate / 365) * _elapsedDays;
  }

  /// Días de atraso del pago que toca. Cero si aún no vence.
  ///
  /// Es lo que en producción calcula cartera; aquí se simula con el mismo
  /// criterio: la mensualidad #n+1 vence a su fecha, y todo día del reloj de
  /// demo posterior a esa fecha es atraso.
  static int get _daysPastDue {
    if (_disbursedAt == null || _liquidado) return 0;
    // Por fecha, no por instante: el vencimiento es un día del calendario, y
    // comparar contra una hora concreta se come un día por redondeo.
    final vence = _dateOnly(_dueDate(_disbursedAt!, _paymentsMade + 1));
    final atraso = _dateOnly(_simulatedNow).difference(vence).inDays;
    return atraso > 0 ? atraso : 0;
  }

  static DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

  /// Días que el soporte de pruebas adelantó el reloj a mano, además de los
  /// que corren solos. Permite saltar a "ya venció" sin esperar.
  static int _shiftedDays = 0;

  (int, dynamic) _testSupport(RequestOptions req) {
    // El query puede venir en `queryParameters` o pegado al path (que es como
    // se arma la URL contra el BFF real). Se aceptan las dos formas para que
    // la misma prueba sirva en los dos flavors.
    final uri = Uri.parse(req.path);
    final path = uri.path;
    final params = {...uri.queryParameters, ...req.queryParameters};
    int? intParam(String k) => switch (params[k]) {
          final num n => n.toInt(),
          final String v => int.tryParse(v),
          _ => null,
        };

    // Devengo diario: adelanta un día (o los que pida `days`).
    if (path.endsWith('/run-daily-accrual')) {
      final days = intParam('days') ?? 1;
      _shiftedDays += days;
      return (200, {'accruedDays': days, 'totalDays': _elapsedDays});
    }

    // Corte del periodo: aquí no hay nada que consolidar, pero se responde
    // para que la prueba use el mismo guion en los dos flavors.
    if (path.endsWith('/run-upcoming-installment-job') ||
        path.endsWith('/run-installment-due-job')) {
      onEvent?.call(CreditMockEvent(
        kind: _daysPastDue > 0
            ? CreditMockEventKind.installmentOverdue
            : CreditMockEventKind.installmentDue,
        amount: _term > 0 ? _monthlyPayment(_principal, _annualRate, _term) : 0,
        paymentsMade: _paymentsMade,
        term: _term,
        daysPastDue: _daysPastDue,
      ));
      return (200, {'triggered': true, 'daysPastDue': _daysPastDue});
    }

    // Mover el vencimiento: `daysFromToday` negativo lo deja en el pasado, que
    // es como se provoca la mora en una prueba.
    if (path.endsWith('/shift-due-date')) {
      final from = intParam('daysFromToday') ?? 0;
      // El vencimiento vive a 30 días por mensualidad desde el desembolso; para
      // dejarlo a `from` días de hoy hay que mover el reloj lo que falte.
      final vence = _dateOnly(
          _dueDate(_disbursedAt ?? DateTime.now(), _paymentsMade + 1));
      final objetivo = _dateOnly(_simulatedNow).add(Duration(days: from));
      _shiftedDays += vence.difference(objetivo).inDays;
      return (200, {'daysPastDue': _daysPastDue});
    }

    return (404, {'error': 'unknown test-support endpoint'});
  }

  /// Reinicia el mock — lo usa el journey de demostración para partir de cero.
  static void reset() {
    _hasAccount = false;
    _pollCounts.clear();
    _principal = 0;
    _term = 0;
    _disbursedAt = null;
    _paidPrincipal = 0;
    _paymentsMade = 0;
    _shiftedDays = 0;
  }

  bool _matches(String path) =>
      _staticPaths.contains(path) ||
      path.startsWith('/credit/applications/') ||
      path.startsWith('/internal/test-support/');

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    if (!_matches(options.path)) {
      handler.next(options);
      return;
    }
    Future.delayed(_delay(options.path), () {
      final result = _resolve(options);
      handler.resolve(Response(
        requestOptions: options,
        data: result.$2,
        statusCode: result.$1,
      ));
    });
  }

  (int, dynamic) _resolve(RequestOptions req) {
    final path = req.path;

    // ── Soporte de pruebas ────────────────────────────────────────────────
    //
    // Mismos paths que expone el BFF (`TestSupportProxyController`), para que
    // una prueba E2E dispare lo mismo contra el mock que contra los servicios
    // reales sin cambiar una línea. Sirven para no esperar en tiempo real a
    // que devengue, venza o entre en mora.
    if (path.startsWith('/internal/test-support/')) return _testSupport(req);

    if (path == '/credit/account') {
      // El BFF devuelve la lista de cuentas activas del cliente.
      return _hasAccount ? (200, [_account()]) : (200, const <dynamic>[]);
    }
    if (path == '/credit/payment') {
      // Un pago baja capital y avanza el contador de mensualidades.
      final body = (req.data as Map?) ?? const {};
      final amount = (body['amount'] as num?)?.toDouble() ?? 0;
      // Un pago cubre intereses del periodo y el resto va a capital: si todo
      // fuera a capital el crédito se liquidaría antes de tiempo y la barra de
      // avance mentiría.
      final aCapital = _term > 0
          ? (_principal / _term).clamp(0.0, _principal - _paidPrincipal)
          : amount;
      _paidPrincipal =
          (_paidPrincipal + math.max(aCapital, 0)).clamp(0.0, _principal);
      _paymentsMade++;
      onEvent?.call(CreditMockEvent(
        // Mismo criterio que reporta la cuenta: si ahí sale liquidado, el aviso
        // que llega tiene que decir lo mismo.
        kind: _liquidado
            ? CreditMockEventKind.creditPaidOff
            : CreditMockEventKind.paymentApplied,
        amount: amount,
        paymentsMade: _paymentsMade,
        term: _term,
      ));
      return (200, {'success': true});
    }
    if (path == '/credit/dispose') return (200, {'success': true});
    if (path == '/credit/products') return (200, {'products': _products()});
    if (path == '/credit/prequalification') {
      return (200, {'products': _products().map(_asPrequalified).toList()});
    }

    if (path == '/credit/applications' && req.method == 'POST') {
      final body = (req.data as Map?) ?? const {};
      final id = 'app_${DateTime.now().millisecondsSinceEpoch}';
      _pollCounts[id] = 0;
      // Se recuerda lo solicitado para poder devolver después una cuenta
      // coherente con lo que el usuario firmó.
      _principal = (body['requestedAmount'] as num?)?.toDouble() ?? 0;
      _term = (body['requestedTerm'] as num?)?.toInt() ?? 0;
      _productType = (body['productType'] as String?) ?? _productType;
      _behavior =
          _productType.contains('REVOLVING') ? 'REVOLVING' : 'INSTALLMENT';
      _annualRate = _rateFor(_productType);
      return (
        201,
        {
          'applicationId': id,
          'prospectId': body['prospectId'],
          'productType': body['productType'],
          'status': 'PENDING_SCORING',
          'requestedAmount': body['requestedAmount'],
          'requestedTerm': body['requestedTerm'],
        }
      );
    }

    // Oferta, aceptación, contrato y firma. Sin esto el flujo se queda
    // esperando en el análisis: el genérico `{success:true}` no trae estado.
    if (path.startsWith('/credit/applications/') && path.endsWith('/offer')) {
      final id = _appId(path, '/offer');
      return (200, _application(id, 'OFFER_PRESENTED'));
    }
    if (path.endsWith('/offer/accept')) {
      final id = _appId(path, '/offer/accept');
      return (200, _application(id, 'OFFER_ACCEPTED'));
    }
    if (path.endsWith('/contract') && req.method == 'POST') {
      final id = _appId(path, '/contract');
      return (200, _application(id, 'PENDING_SIGNATURE'));
    }
    if (path.endsWith('/contract/sign')) {
      final id = _appId(path, '/contract/sign');
      // Firmar es lo que desembolsa y arranca el devengo.
      _hasAccount = true;
      if (_disbursedAt == null) {
        _disbursedAt = DateTime.now();
        onEvent?.call(CreditMockEvent(
          kind: CreditMockEventKind.disbursed,
          amount: _principal,
          term: _term,
        ));
      }
      return (200, _application(id, 'CONTRACT_SIGNED'));
    }

    if (path.startsWith('/credit/applications/')) {
      final id = path.substring('/credit/applications/'.length);
      final count = (_pollCounts[id] ?? 0) + 1;
      _pollCounts[id] = count;
      // Tras 2 consultas, el scoring "decide": aprobado.
      if (count >= 2) {
        _hasAccount = true;
        // El desembolso arranca el reloj del devengo.
        if (_disbursedAt == null) {
          _disbursedAt = DateTime.now();
          onEvent?.call(CreditMockEvent(
            kind: CreditMockEventKind.disbursed,
            amount: _principal,
            term: _term,
          ));
        }
        return (200, _application(id, 'APPROVED'));
      }
      return (200, {'applicationId': id, 'status': 'PENDING_SCORING'});
    }

    return (200, {'success': true});
  }

  // nominalRate en fracción decimal (0.36 = 36%) — misma escala que el backend real
  // (nominalRateAnnual) y que credit_product_dto.dart. Antes estaba en escala de
  // porcentaje (36.0), inofensivo mientras nada renderizaba este campo; ahora que la
  // vista previa de pago (amortization_calculator) sí lo usa, debía coincidir.
  List<Map<String, dynamic>> _products() => [
        {
          'code': 'REV-001',
          'name': 'Línea revolvente',
          'productType': 'REVOLVING_LINE',
          'behavior': 'REVOLVING',
          'description': 'Dispón cuando quieras y paga a tu ritmo.',
          'minAmount': 10000.0,
          'maxAmount': 50000.0,
          'nominalRate': 0.36,
          'amountStep': 5000,
          'defaultPaymentFrequency': 'MONTHLY',
          'targetAudience': 'B2C',
        },
        {
          'code': 'PER-001',
          'name': 'Préstamo personal',
          'productType': 'PERSONAL_LOAN',
          'behavior': 'INSTALLMENT',
          'description': 'Monto fijo a plazos fijos.',
          'minAmount': 5000.0,
          'maxAmount': 100000.0,
          'minTerm': 6,
          'maxTerm': 36,
          'nominalRate': 0.42,
          'defaultPaymentFrequency': 'MONTHLY',
          'targetAudience': 'B2C',
          'amountStep': 1000,
          'defaultTerm': 12,
        },
        {
          'code': 'NOM-001',
          'name': 'Crédito de nómina',
          'productType': 'PAYROLL_LOAN',
          'behavior': 'INSTALLMENT',
          'description': 'Descuento vía nómina con tasa preferente.',
          'minAmount': 3000.0,
          'maxAmount': 80000.0,
          'minTerm': 3,
          'maxTerm': 24,
          'nominalRate': 0.28,
          'defaultPaymentFrequency': 'BIWEEKLY',
          'targetAudience': 'B2C',
          'amountStep': 500,
          'defaultTerm': 12,
        },
        {
          'code': 'PYM-001',
          'name': 'Crédito PyME',
          'productType': 'SME_LOAN',
          'behavior': 'INSTALLMENT',
          'description':
              'Capital de trabajo para tu negocio, evaluado por comité.',
          'minAmount': 50000.0,
          'maxAmount': 800000.0,
          'minTerm': 12,
          'maxTerm': 36,
          'nominalRate': 0.249,
          'defaultPaymentFrequency': 'MONTHLY',
          'targetAudience': 'B2B',
          'amountStep': 5000,
          'defaultTerm': 24,
        },
      ];

  /// Decisión de scoring simulada por producto.
  ///
  /// No todo sale aprobado: los productos de persona se autoaprueban y los de
  /// negocio pasan a comité. Es lo que permite ver en la app las dos secciones
  /// de oportunidades — "aprobadas para ti" y "puedes solicitarlas" — en vez de
  /// una lista uniforme que no distingue nada.
  Map<String, dynamic> _asPrequalified(Map<String, dynamic> product) {
    final type = (product['productType'] as String?) ?? '';
    final aComite = type == 'SME_LOAN' || type == 'DISTRIBUTOR_LINE';
    final riesgo = aComite ? 'MEDIO' : 'BAJO';

    return {
      ...product,
      'evaluated': true,
      'decision': aComite ? 'MANUAL_REVIEW' : 'AUTO_APPROVED',
      'riskLevel': riesgo,
      'skippedReason': null,
      'preOffer': _preOffer(product, riesgo),
    };
  }

  /// La preoferta que el scoring abre sobre el rango del catálogo.
  ///
  /// El catálogo publica el rango comercial del producto; la política de riesgo
  /// decide qué parte de ese rango se le autoriza a esta persona. Riesgo bajo
  /// abre el tope y el plazo completos; riesgo medio recorta el monto y acorta
  /// el plazo máximo, y paga una tasa mayor. Así el configurador nunca deja
  /// armar un préstamo que después se recorta en la resolución.
  static Map<String, dynamic> _preOffer(
      Map<String, dynamic> product, String riesgo) {
    final catMax = (product['maxAmount'] as num?)?.toDouble();
    final catMin = (product['minAmount'] as num?)?.toDouble() ?? 0;
    final catMaxTerm = (product['maxTerm'] as num?)?.toInt();
    final catMinTerm = (product['minTerm'] as num?)?.toInt();
    final step = (product['amountStep'] as num?)?.toInt() ?? 1000;
    final tasa = (product['nominalRate'] as num?)?.toDouble();

    final (factorMonto, factorPlazo, sobretasa) = switch (riesgo) {
      'BAJO' => (1.0, 1.0, 0.0),
      'MEDIO' => (0.6, 0.75, 0.04),
      _ => (0.35, 0.5, 0.09),
    };

    // Sólo se acota lo que el catálogo define. Un revolvente no publica plazo:
    // inventarle uno haría que el configurador pidiera elegir mensualidades de
    // una línea que no las tiene.
    double? maxAmount;
    if (catMax != null) {
      // Se redondea al escalón del slider: una preoferta de $92.400 con paso
      // de $5.000 es un tope que el control no puede alcanzar.
      final bruto = catMax * factorMonto;
      maxAmount =
          ((bruto / step).floor() * step).toDouble().clamp(catMin, catMax);
    }

    int? maxTerm;
    if (catMaxTerm != null) {
      maxTerm =
          (catMaxTerm * factorPlazo).round().clamp(catMinTerm ?? 1, catMaxTerm);
    }

    return {
      if (product['minAmount'] != null) 'minAmount': catMin,
      if (maxAmount != null) 'maxAmount': maxAmount,
      if (catMinTerm != null) 'minTerm': catMinTerm,
      if (maxTerm != null) 'maxTerm': maxTerm,
      // Se abre en un plazo cómodo dentro de lo autorizado, no en el tope.
      if (maxTerm != null)
        'defaultTerm': ((maxTerm + (catMinTerm ?? 1)) / 2).round(),
      if (tasa != null) 'nominalRate': tasa + sobretasa,
    };
  }

  static String _appId(String path, String suffix) {
    final withoutSuffix = path.substring(0, path.length - suffix.length);
    return withoutSuffix.substring('/credit/applications/'.length);
  }

  /// Aplicación en el estado pedido, con la oferta que corresponde a lo
  /// solicitado — el mock aprueba el monto completo.
  Map<String, dynamic> _application(String id, String status) => {
        'applicationId': id,
        'status': status,
        'decision': 'AUTO_APPROVED',
        'riskLevel': 'BAJO',
        'offeredAmount': _principal,
        'offeredTerm': _term,
        'contractNumber': 'KRD-${id.hashCode.abs() % 1000000}',
      };

  static double _rateFor(String productType) => switch (productType) {
        'REVOLVING_LINE' => 0.36,
        'PAYROLL_LOAN' => 0.28,
        _ => 0.42,
      };

  /// Cuenta de crédito con el saldo devengado al momento de la consulta.
  ///
  /// Cada refresco del home vuelve a llamar aquí, así que el saldo pendiente
  /// crece y el avance de pagos se mueve — que es justo lo que hay que poder
  /// ver en una demo.
  /// El crédito está saldado: se cubrieron todas las mensualidades o ya no
  /// queda capital vivo. Una sola definición para la cuenta y para el aviso.
  static bool get _liquidado {
    if (_principal <= 0) return false;
    final outstanding = (_principal - _paidPrincipal).clamp(0.0, _principal);
    return (_term > 0 && _paymentsMade >= _term) || outstanding <= 0.5;
  }

  Map<String, dynamic> _account() {
    final outstanding = (_principal - _paidPrincipal).clamp(0.0, _principal);
    final liquidado = _liquidado;
    final pending = liquidado ? 0.0 : outstanding + _accruedInterest;
    final monthly = _term > 0
        ? _monthlyPayment(_principal, _annualRate, _term)
        : outstanding * 0.05;

    // El vencimiento avanza con los pagos: quedarse clavado en una fecha fija
    // haría que la tarjeta del home dijera lo mismo después de pagar, que es
    // justo lo que el usuario mira para saber que su pago entró.
    final desde = _disbursedAt ?? DateTime.now();
    final siguiente = _dueDate(desde, _paymentsMade + 1);
    final corte = siguiente.subtract(const Duration(days: 5));
    final atraso = _daysPastDue;

    // Moratorios: sólo corren sobre lo vencido y sólo mientras hay atraso.
    final moratorios =
        atraso > 0 ? monthly * (_annualRate * 1.5 / 365) * atraso : 0.0;

    return {
      'creditLimit': _behavior == 'REVOLVING' ? 50000.0 : _principal,
      'usedAmount': _principal,
      'principalBalance': outstanding,
      'pendingBalance': pending + (atraso > 0 ? moratorios : 0.0),
      'minimumPayment': monthly,
      'noInterestPayment': pending,
      'principalPaid': _paidPrincipal,
      'paymentsMade': _paymentsMade,
      'assignedTerm': _term > 0 ? _term : null,
      'remainingPayments':
          _term > 0 ? (_term - _paymentsMade).clamp(0, _term) : null,
      'cutoffDate': corte.toIso8601String(),
      'paymentDueDate': siguiente.toIso8601String(),
      'noInterestDeadline': siguiente.toIso8601String(),
      'annualRate': _annualRate,
      'cat': _annualRate * 100 * 1.18,
      'accountNumber': '•••• •••• •••• 4821',
      'productType': _productType,
      'productBehavior': _behavior,
      // La mora la reporta cartera, no la deduce la app comparando fechas.
      'daysPastDue': atraso,
      'overdueAmount': atraso > 0 ? monthly + moratorios : 0.0,
      'status': liquidado
          ? 'PAID_OFF'
          : atraso > 0
              ? 'PAST_DUE'
              : 'ACTIVE',
    };
  }

  /// Vencimiento del pago [n] (1-based) contado desde el desembolso. Se acota
  /// al último día del mes para no desbordar a marzo desde un 31 de enero.
  static DateTime _dueDate(DateTime from, int n) {
    final month = from.month + n;
    final year = from.year + (month - 1) ~/ 12;
    final normalized = (month - 1) % 12 + 1;
    final lastDay = DateTime(year, normalized + 1, 0).day;
    return DateTime(year, normalized, math.min(from.day, lastDay));
  }

  /// Cuota de un préstamo francés: P·i / (1 − (1+i)^−n).
  static double _monthlyPayment(double principal, double annualRate, int term) {
    if (principal <= 0 || term <= 0) return 0;
    final i = annualRate / 12;
    if (i == 0) return principal / term;
    return principal * i / (1 - math.pow(1 + i, -term));
  }

  Duration _delay(String path) {
    if (path.startsWith('/credit/applications/')) {
      return const Duration(milliseconds: 600);
    }
    if (path == '/credit/applications')
      return const Duration(milliseconds: 700);
    if (path.contains('/payment')) return const Duration(milliseconds: 850);
    if (path.contains('/dispose')) return const Duration(milliseconds: 680);
    return const Duration(milliseconds: 420);
  }
}

/// Qué acaba de pasar con el crédito, en el flavor mock.
enum CreditMockEventKind {
  disbursed,
  paymentApplied,
  creditPaidOff,
  installmentDue,
  installmentOverdue,
}

class CreditMockEvent {
  const CreditMockEvent({
    required this.kind,
    this.amount = 0,
    this.paymentsMade = 0,
    this.term = 0,
    this.daysPastDue = 0,
  });

  final CreditMockEventKind kind;
  final double amount;
  final int paymentsMade;
  final int daysPastDue;
  final int term;
}
