import 'package:provider/provider.dart';
import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

import 'package:fa_core/fa_core.dart';
import 'src/application/use_cases/login_use_case.dart';
import 'src/infrastructure/adapters/auth_repository_impl.dart';
import 'src/presentation/providers/auth_provider.dart';
import 'src/presentation/screens/splash_screen.dart';
import 'src/presentation/screens/login_screen.dart';

class AuthModule extends IModule {
  late ApiClient _apiClient;
  late NavigationCallbacks _navigation;

  @override
  String get moduleId => 'fa_auth';

  @override
  String get version => '1.0.0';

  @override
  void configure({required ApiClient apiClient, required NavigationCallbacks navigation}) {
    _apiClient = apiClient;
    _navigation = navigation;
  }

  @override
  List<Widget> get providers => [
        ChangeNotifierProvider<AuthProvider>(
          create: (_) => AuthProvider(
            loginUseCase: LoginUseCase(AuthRepositoryImpl(apiClient: _apiClient)),
          ),
        ),
      ];

  @override
  List<RouteBase> get routes => [
        GoRoute(
          path: '/splash',
          builder: (_, __) => const SplashScreen(),
        ),
        GoRoute(
          path: '/login',
          builder: (_, __) => LoginScreen(
            onLoginSuccess: (userId) => _navigation.onLoginSuccess(userId),
          ),
        ),
      ];

  @override
  Widget? buildHomeCard(BuildContext context) => null;
}
