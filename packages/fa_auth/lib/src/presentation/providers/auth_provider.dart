import 'package:flutter/material.dart';
import '../../application/use_cases/login_use_case.dart';
import '../../domain/entities/auth_user.dart';
import 'package:fa_core/fa_core.dart';

class AuthProvider extends ChangeNotifier with SafeNotifier {
  AuthProvider({required LoginUseCase loginUseCase}) : _loginUseCase = loginUseCase;
  final LoginUseCase _loginUseCase;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _error;
  String? get error => _error;

  AuthUser? _currentUser;
  AuthUser? get currentUser => _currentUser;

  Future<bool> login({required String phone, required String password}) async {
    _isLoading = true;
    _error = null;
    notificar();
    try {
      final user = await _loginUseCase(phone: phone, password: password);
      _currentUser = user;
      if (user == null) _error = 'Credenciales incorrectas. Verifica e intenta de nuevo.';
      return user != null;
    } catch (_) {
      _error = 'Error de conexión. Intenta de nuevo.';
      return false;
    } finally {
      _isLoading = false;
      notificar();
    }
  }

  void clearError() {
    _error = null;
    notificar();
  }
}
