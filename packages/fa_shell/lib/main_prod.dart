import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:fa_core/fa_core.dart';
import 'main.dart' show KrediusApp;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  AppConfig.setup(flavor: AppFlavor.prod);
  await initializeDateFormatting('es_MX', null);
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  runApp(const KrediusApp());
}
