/// Contrato de navegación para módulos.
/// Usar `abstract interface class` permite mockearlo en tests.
abstract interface class INavigationCallbacks {
  void onLoginSuccess(String userId);
  void onLogout();
  void onOnboardingComplete();
  void onCreditDetail(String creditId);
  void onWalletTransfer();
  void onSupportRequest();
}

/// Implementación concreta via callbacks. El shell la construye al inicio.
class NavigationCallbacks implements INavigationCallbacks {
  const NavigationCallbacks({
    required void Function(String userId) onLoginSuccess,
    required void Function() onLogout,
    required void Function() onOnboardingComplete,
    required void Function(String creditId) onCreditDetail,
    required void Function() onWalletTransfer,
    required void Function() onSupportRequest,
  })  : _onLoginSuccess = onLoginSuccess,
        _onLogout = onLogout,
        _onOnboardingComplete = onOnboardingComplete,
        _onCreditDetail = onCreditDetail,
        _onWalletTransfer = onWalletTransfer,
        _onSupportRequest = onSupportRequest;

  final void Function(String userId) _onLoginSuccess;
  final void Function() _onLogout;
  final void Function() _onOnboardingComplete;
  final void Function(String creditId) _onCreditDetail;
  final void Function() _onWalletTransfer;
  final void Function() _onSupportRequest;

  @override
  void onLoginSuccess(String userId) => _onLoginSuccess(userId);
  @override
  void onLogout() => _onLogout();
  @override
  void onOnboardingComplete() => _onOnboardingComplete();
  @override
  void onCreditDetail(String creditId) => _onCreditDetail(creditId);
  @override
  void onWalletTransfer() => _onWalletTransfer();
  @override
  void onSupportRequest() => _onSupportRequest();
}
