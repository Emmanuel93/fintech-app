import 'package:dio/dio.dart';

class WalletMockInterceptor extends Interceptor {
  static const _paths = {'/wallet/balance', '/wallet/transactions', '/wallet/transfer'};

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    if (!_paths.contains(options.path)) {
      handler.next(options);
      return;
    }
    Future.delayed(_delay(options.path), () {
      handler.resolve(Response(
        requestOptions: options,
        data: _resolve(options),
        statusCode: 200,
      ));
    });
  }

  Map<String, dynamic> _resolve(RequestOptions req) {
    switch (req.path) {
      case '/wallet/balance':
        return {
          'available': 13596.00,
          'accountNumber': '6673038098',
          'clabe': '646180557000123456',
          'currency': 'MXN',
        };
      case '/wallet/transactions':
        final d = (int days) =>
            DateTime.now().subtract(Duration(days: days)).toIso8601String();
        return {
          'transactions': [
            {'id': 't1', 'type': 'credit', 'category': 'disposicion', 'description': 'Disposición de crédito', 'amount': 12000.0, 'date': d(0)},
            {'id': 't2', 'type': 'debit', 'category': 'payment', 'description': 'Netflix', 'amount': 199.0, 'date': d(1), 'merchant': 'Netflix'},
            {'id': 't3', 'type': 'credit', 'category': 'deposit', 'description': 'Depósito SPEI', 'amount': 5000.0, 'date': d(2), 'reference': 'SPEI-00842'},
            {'id': 't4', 'type': 'debit', 'category': 'payment', 'description': 'Uber', 'amount': 185.0, 'date': d(2), 'merchant': 'Uber'},
            {'id': 't5', 'type': 'debit', 'category': 'transferOut', 'description': 'Transferencia a Juan P.', 'amount': 1500.0, 'date': d(3)},
            {'id': 't6', 'type': 'credit', 'category': 'transferIn', 'description': 'Transferencia recibida', 'amount': 3200.0, 'date': d(4)},
            {'id': 't7', 'type': 'debit', 'category': 'payment', 'description': 'CFE Luz', 'amount': 720.0, 'date': d(5), 'merchant': 'CFE'},
            {'id': 't8', 'type': 'debit', 'category': 'withdrawal', 'description': 'Retiro cajero BBVA', 'amount': 2000.0, 'date': d(6)},
            {'id': 't9', 'type': 'debit', 'category': 'payment', 'description': 'Pago crédito revolvente', 'amount': 2000.0, 'date': d(12)},
          ],
        };
      case '/wallet/transfer':
        return {'success': true, 'transferId': 'TRF-${DateTime.now().millisecondsSinceEpoch}'};
      default:
        return {'success': true};
    }
  }

  Duration _delay(String path) {
    if (path.contains('/transfer')) return const Duration(milliseconds: 1100);
    if (path.contains('/transactions')) return const Duration(milliseconds: 460);
    return const Duration(milliseconds: 380);
  }
}
