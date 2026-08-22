import 'package:flutter/material.dart';
import '../../application/use_cases/get_credit_use_case.dart';
import '../../application/use_cases/list_credit_accounts_use_case.dart';
import '../../application/use_cases/make_payment_use_case.dart';
import '../../application/use_cases/run_test_support_use_case.dart';
import '../../application/use_cases/dispose_credit_use_case.dart';
import '../../domain/entities/credit_account.dart';
import 'package:fa_core/fa_core.dart';

class CreditProvider extends ChangeNotifier with SafeNotifier {
  CreditProvider({
    required GetCreditUseCase getCredit,
    required ListCreditAccountsUseCase listCreditAccounts,
    required MakePaymentUseCase makePayment,
    required RunTestSupportUseCase runTestSupport,
    required DisposeCreditUseCase disposeCredit,
  })  : _getCredit = getCredit,
        _listCreditAccounts = listCreditAccounts,
        _makePayment = makePayment,
        _runTestSupport = runTestSupport,
        _disposeCredit = disposeCredit;

  final GetCreditUseCase _getCredit;
  final ListCreditAccountsUseCase _listCreditAccounts;
  final MakePaymentUseCase _makePayment;
  final RunTestSupportUseCase _runTestSupport;
  final DisposeCreditUseCase _disposeCredit;

  CreditAccount? credit;
  bool isLoading = false;
  bool loaded = false;
  bool isProcessing = false;
  String? error;

  // ── Tab "Créditos": historial completo (vigentes + liquidados) ──────────
  List<CreditAccount> accounts = const [];
  bool isLoadingAccounts = false;

  Future<void> loadAccounts() async {
    isLoadingAccounts = true;
    notificar();
    try {
      accounts = await _listCreditAccounts();
    } catch (_) {
      accounts = const [];
    } finally {
      isLoadingAccounts = false;
      notificar();
    }
  }

  /// El prospecto no tiene crédito todavía (debe solicitarlo). Distingue el
  /// estado vacío del estado de carga inicial.
  bool get hasNoCredit => loaded && credit == null;

  Future<void> load() async {
    isLoading = true;
    error = null;
    notificar();
    try {
      credit = await _getCredit();
    } catch (_) {
      error = 'Error al cargar la información del crédito.';
    } finally {
      isLoading = false;
      loaded = true;
      notificar();
    }
  }

  /// Carga esperando a que la cuenta exista.
  ///
  /// Firmar el contrato responde 200, pero la cuenta la crea cartera al
  /// consumir el evento — llega medio segundo después. Consultar de inmediato
  /// devuelve vacío y el home diría "todavía no tienes créditos" al usuario
  /// que **acaba de firmar**, que es la peor pantalla posible en ese momento.
  /// Se reintenta un poco antes de aceptar el vacío como respuesta.
  Future<void> loadAfterDisbursement({
    int intentos = 6,
    Duration espera = const Duration(milliseconds: 500),
  }) async {
    for (var i = 0; i < intentos; i++) {
      await load();
      if (credit != null) return;
      if (i < intentos - 1) await Future<void>.delayed(espera);
    }
  }

  /// Atajo para las pruebas E2E: dispara un endpoint de soporte del BFF.
  Future<bool> testSupport(String path, {Map<String, dynamic>? query}) =>
      _runTestSupport(path, query: query);

  Future<bool> makePayment({required double amount}) async {
    isProcessing = true;
    notificar();
    try {
      final ok = await _makePayment(amount: amount);
      if (ok && credit != null) {
        credit = credit!.applyPayment(amount);
      }
      return ok;
    } catch (_) {
      return false;
    } finally {
      isProcessing = false;
      notificar();
    }
  }

  /// Performs a disposition: increases usedAmount and pendingBalance.
  /// Caller should then invoke WalletProvider.applyDisposition(amount).
  Future<bool> disposeToWallet({required double amount}) async {
    if (credit == null) return false;
    if (amount <= 0 || amount > credit!.availableCredit) return false;
    isProcessing = true;
    notificar();
    try {
      final ok = await _disposeCredit(amount: amount);
      if (ok) {
        credit = credit!.applyDisposition(amount);
      }
      return ok;
    } catch (_) {
      return false;
    } finally {
      isProcessing = false;
      notificar();
    }
  }
}
