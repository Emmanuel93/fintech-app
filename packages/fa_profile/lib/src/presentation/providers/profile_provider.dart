import 'package:flutter/material.dart';
import '../../application/use_cases/get_profile_use_case.dart';
import '../../domain/entities/user_profile.dart';
import 'package:fa_core/fa_core.dart';

class ProfileProvider extends ChangeNotifier with SafeNotifier {
  ProfileProvider({required GetProfileUseCase getProfile}) : _getProfile = getProfile;

  final GetProfileUseCase _getProfile;

  UserProfile? profile;
  bool isLoading = false;
  String? error;

  /// Vuelve a pedir el perfil aunque ya haya uno en memoria. Es lo que hace el
  /// botón de reintentar: si la carga anterior falló a medias, `load` se
  /// saldría de inmediato al ver que ya hay algo.
  Future<void> reload() {
    profile = null;
    return load();
  }

  Future<void> load() async {
    if (profile != null) return;
    isLoading = true;
    error = null;
    notificar();
    try {
      profile = await _getProfile();
    } catch (_) {
      // p.ej. 404 cuando el party aún no existe para la cuenta.
      error = 'No pudimos cargar tu perfil.';
      profile = null;
    } finally {
      isLoading = false;
      notificar();
    }
  }
}
