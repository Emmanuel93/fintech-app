import 'package:go_router/go_router.dart';
import 'package:fa_core/fa_core.dart';
import '../home/home_screen.dart';

GoRouter buildRouter(List<IModule> modules) {
  return GoRouter(
    initialLocation: '/splash',
    routes: [
      GoRoute(
        path: '/home',
        builder: (_, __) => HomeScreen(modules: modules),
      ),
      for (final module in modules) ...module.routes,
    ],
  );
}
