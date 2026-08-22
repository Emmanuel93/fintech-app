import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:nested/nested.dart' show SingleChildWidget;
import 'package:intl/date_symbol_data_local.dart';
import 'package:fa_core/fa_core.dart';
import 'package:fa_design_system/fa_design_system.dart';
import 'src/brand/brand_bar_host.dart';
import 'src/di/shell_injection.dart';
import 'src/router/shell_router.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  AppConfig.setup(flavor: AppFlavor.mock);
  await initializeDateFormatting('es_MX', null);
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  runApp(const KrediusApp());
}

class KrediusApp extends StatefulWidget {
  const KrediusApp({super.key});

  @override
  State<KrediusApp> createState() => _KrediusAppState();
}

class _KrediusAppState extends State<KrediusApp> {
  late final GoRouter _router;
  late final List<IModule> _modules;

  @override
  void initState() {
    super.initState();
    final apiClient = ShellInjection.buildApiClient();
    final navigation = NavigationCallbacks(
      onLoginSuccess: (userId) => _router.go('/home'),
      onLogout: () => _router.go('/login'),
      onOnboardingComplete: () => _router.go('/login'),
      onCreditDetail: (creditId) => _router.go('/credit'),
      onWalletTransfer: () => _router.go('/wallet/send'),
      onSupportRequest: () {},
    );
    _modules = ShellInjection.buildModules(
      apiClient: apiClient,
      navigation: navigation,
    );
    _router = buildRouter(_modules);
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: _modules
          .expand((m) => m.providers)
          .cast<SingleChildWidget>()
          .toList(),
      child: MaterialApp.router(
        title: 'Kredius',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        routerConfig: _router,
        // La barra de marca va por encima de todas las pantallas, no dentro de
        // cada una: es la firma que el diseño mantiene fija en el recorrido.
        builder: (context, child) => BrandBarHost(
          router: _router,
          modules: _modules,
          child: child ?? const SizedBox.shrink(),
        ),
      ),
    );
  }
}
