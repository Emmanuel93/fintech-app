# fa_shell

La aplicación. Ensambla los nueve módulos y **no conoce a ninguno**.

Es el único paquete con `main`, con proyecto iOS/Android y con las suites E2E.
También el único que puede importar todos los `fa_*` — y aun así sólo lo hace en
un archivo, `ShellInjection`, para instanciarlos y guardarlos como `IModule`.

## Qué ensambla

```dart
// src/di/shell_injection.dart — el único lugar que nombra los módulos
_modules = [
  AuthModule(), OnboardingModule(), WalletModule(), CreditModule(),
  PlacementsModule(), NotificationsModule(), ProfileModule(),
];
```

De ahí salen tres cosas, todas por contrato:

| El shell pide | El módulo responde | Se ve en |
|---|---|---|
| `routes` | sus `GoRoute` | el router |
| `providers` | sus `ChangeNotifier` | el `MultiProvider` raíz |
| `ownedTabs` + `areTabsVisible` | qué tabs reclama, y si hoy tocan | el bottom nav |
| `buildHomeCard` + `homeCardOrder` | su tarjeta y su prelación | el tab Inicio |
| `getHeaderDisplayName` / `getHeaderBadgeCount` | nombre y no leídas | la barra de marca |

Quitar un módulo de esa lista deja la app compilando, sin su funcionalidad y
entera. Es la prueba de que el desacoplamiento es real y no un diagrama.

## Lo que el shell sí posee

- **El home** (`src/home/`) — saludo, tabs y el tab Inicio, que sólo apila lo
  que los módulos aportan, ordenado por `homeCardOrder`.
- **La barra de marca** (`src/brand/brand_bar_host.dart`) — se monta **encima
  de todas las pantallas**, como en el diseño, colgada del `MaterialApp` y no de
  cada pantalla, para que no parpadee entre navegaciones. Decide por ruta si va
  clara u oscura y si muestra avatar y campana.
- **El router** y los cuatro `main_*` (mock, local, qa, prod).

## Los flavors

| Entrada | Backend |
|---|---|
| `main.dart` | mock — interceptores en memoria, sin red |
| `main_local.dart` | gateway en `mobile.localhost:8090` |
| `main_qa.dart` / `main_prod.dart` | `api-qa` / `api` |

```sh
flutter run -t lib/main.dart          # mock
flutter run -t lib/main_local.dart    # contra fintech-services
```

## Pruebas

22 suites. `test/` son unitarias —incluido el guard de tokens y el de prelación
del home— e `integration_test/` recorre la app en un simulador:

| Suite | Qué cubre |
|---|---|
| `regression_suite.dart` | alta → login → login fallido. Detecta el backend solo. |
| `journey_connected_showcase_test.dart` | los cinco recorridos completos **sin mocks** |
| `perfil_smoke_test.dart` | el perfil como expediente claro |
| `*_showcase_test.dart` | recorridos en mock, para grabar |

Los conectados necesitan `fintech-services` arriba y una distribuidora con línea
activa; el teléfono se pasa con `--dart-define=DIST_PHONE=`. Los detalles y la
consulta para sacar una vigente están en `docs/KREDIUS_E2E_VIDEOS.md`.
