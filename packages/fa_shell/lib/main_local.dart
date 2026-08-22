import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:fa_core/fa_core.dart';
import 'main.dart' show KrediusApp;

// Apunta al gateway local (mobile.localhost:8090 por default — el 8080 lo ocupa un
// port-forward ajeno al proyecto en esta máquina). Override opcional:
//   flutter run -t lib/main_local.dart --dart-define=BFF_URL=http://mobile.localhost:8080
const _bffUrlOverride = String.fromEnvironment('BFF_URL');

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  AppConfig.setup(
    flavor: AppFlavor.local,
    bffUrl: _bffUrlOverride.isEmpty ? null : _bffUrlOverride,
  );
  await initializeDateFormatting('es_MX', null);
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  runApp(const KrediusApp());
}
