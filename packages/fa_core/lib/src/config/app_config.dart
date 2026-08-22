enum AppFlavor { mock, local, qa, prod }

class AppConfig {
  final AppFlavor flavor;
  final String bffUrl;

  const AppConfig._({required this.flavor, required this.bffUrl});

  static late AppConfig current;

  static void setup({required AppFlavor flavor, String? bffUrl}) {
    current = AppConfig._(
      flavor: flavor,
      bffUrl: bffUrl ??
          switch (flavor) {
            AppFlavor.mock  => 'https://mock.kredius.mx',
            // El gateway (OpenResty) enruta por subdominio al BFF móvil.
            // mobile.localhost resuelve a 127.0.0.1 sin tocar /etc/hosts.
            //
            // El puerto es 8090 y no 8080 porque en esta máquina el 8080 lo
            // ocupa un port-forward ajeno al proyecto; el compose publica el
            // gateway ahí para no pelearse con él.
            AppFlavor.local => 'http://mobile.localhost:8090',
            AppFlavor.qa    => 'https://api-qa.kredius.mx/mobile/v1',
            AppFlavor.prod  => 'https://api.kredius.mx/mobile/v1',
          },
    );
  }

  bool get isMock => flavor == AppFlavor.mock;

  String get label => switch (flavor) {
        AppFlavor.mock  => 'MOCK',
        AppFlavor.local => 'LOCAL',
        AppFlavor.qa    => 'QA',
        AppFlavor.prod  => 'PROD',
      };
}
