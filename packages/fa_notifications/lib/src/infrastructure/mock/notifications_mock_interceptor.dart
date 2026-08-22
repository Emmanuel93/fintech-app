import 'package:dio/dio.dart';

class NotificationsMockInterceptor extends Interceptor {
  final _readIds = <String>{};

  // ── Notificaciones del ciclo de vida del crédito ─────────────────────────
  //
  // El catálogo fijo de abajo existe siempre; éstas se **agregan** cuando algo
  // pasa de verdad en la sesión (se firmó un crédito, se hizo un pago), para
  // que en una demo se vea llegar el aviso justo después del hecho.
  static final List<Map<String, dynamic>> _live = [];

  /// Registra un aviso nuevo, que aparecerá en el siguiente `GET /notifications`.
  static void push({
    required String id,
    required String type,
    required String title,
    required String body,
    String? actionRoute,
  }) {
    // Sin duplicados: el home refresca varias veces y el aviso es uno solo.
    if (_live.any((n) => n['id'] == id)) return;
    _live.insert(0, {
      'id': id,
      'type': type,
      'title': title,
      'body': body,
      'date': DateTime.now().toIso8601String(),
      'isRead': false,
      if (actionRoute != null) 'actionRoute': actionRoute,
    });
  }

  static void reset() => _live.clear();

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    final path = options.path;
    final method = options.method.toUpperCase();

    if (!path.startsWith('/notifications')) {
      handler.next(options);
      return;
    }

    Future.delayed(const Duration(milliseconds: 310), () {
      handler.resolve(Response(
        requestOptions: options,
        data: _resolve(options, path, method),
        statusCode: 200,
      ));
    });
  }

  Map<String, dynamic> _resolve(RequestOptions req, String path, String method) {
    if (path == '/notifications' && method == 'GET') return _notificationsMock();
    if (path == '/notifications/read-all') {
      _readIds.addAll(['n1', 'n2', 'n3', 'n4', 'n5', 'n6', 'n7', 'n8', 'n9', 'n10']);
      return {'success': true};
    }
    if (path.startsWith('/notifications/') && path.endsWith('/read')) {
      final id = path.split('/')[2];
      _readIds.add(id);
      return {'success': true};
    }
    return {'success': true};
  }

  Map<String, dynamic> _notificationsMock() {
    final now = DateTime.now();
    final items = [
      // Primero lo que acaba de pasar en esta sesión.
      ..._live.map((n) => {...n, 'isRead': _readIds.contains(n['id'])}),
      _n('n1', 'marketing', '🎁 2% cashback en compras este mes',
         'Usa tu crédito en comercios afiliados y recibe 2% de reembolso.',
         now.subtract(const Duration(minutes: 20)), '/home/credit'),
      _n('n2', 'paymentDue', 'Tu pago vence en 5 días',
         'Realiza al menos el pago mínimo de \$520 antes del 15 jun.',
         now.subtract(const Duration(hours: 2)), '/home/credit'),
      _n('n3', 'transferIn', 'Recibiste \$3,200',
         'Depósito SPEI acreditado. Ref: SPEI-00842.',
         now.subtract(const Duration(hours: 5)), '/home/movements', isRead: true),
    ];
    return {
      'notifications': items.map((n) {
        if (_readIds.contains(n['id'])) return {...n, 'isRead': true};
        return n;
      }).toList(),
    };
  }

  Map<String, dynamic> _n(String id, String type, String title, String body,
      DateTime date, String? actionRoute, {bool isRead = false}) =>
      {
        'id': id,
        'type': type,
        'title': title,
        'body': body,
        'date': date.toIso8601String(),
        'isRead': isRead,
        if (actionRoute != null) 'actionRoute': actionRoute,
      };
}
