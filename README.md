# Fintech App — Monorepo de Módulos Flutter Comercializables

## Índice

1. [Visión General](#1-visión-general)
2. [Arquitectura y Desacoplamiento](#2-arquitectura-y-desacoplamiento)
   - [2.0 Microfrontends en una app móvil](#20-microfrontends-en-una-app-móvil)
   - [2.1 Principio Fundamental](#21-principio-fundamental)
   - [2.2 Flujo de datos en un módulo](#22-flujo-de-datos-en-un-módulo)
   - [2.3 Desacoplamiento entre módulos](#23-desacoplamiento-entre-módulos)
3. [Mapa de Dependencias](#3-mapa-de-dependencias)
4. [Contratos Clave: Cómo se Desacoplan los Módulos](#4-contratos-clave-cómo-se-desacoplan-los-módulos)
5. [Sistema de Mocks e Interceptores](#5-sistema-de-mocks-e-interceptores)
6. [Comercialización de Módulos Independientes](#6-comercialización-de-módulos-independientes)
7. [Ambientes y Flavors](#7-ambientes-y-flavors)
   - [7.1 Qué es un flavor en este proyecto](#71-qué-es-un-flavor-en-este-proyecto)
   - [7.2 Comandos principales — qué hace cada uno](#72-comandos-principales--qué-hace-cada-uno)
   - [7.3 Flujo completo: correr en flavor mock](#73-flujo-completo-correr-en-flavor-mock-desarrollo-diario)
   - [7.4 Flujo completo: correr en flavor QA](#74-flujo-completo-correr-en-flavor-qa)
   - [7.5 Flujo completo: correr en flavor producción](#75-flujo-completo-correr-en-flavor-producción)
   - [7.6 Tabla resumen de comandos por flavor](#76-tabla-resumen-de-comandos-por-flavor)
   - [7.7 Errores comunes al cambiar de flavor](#77-errores-comunes-al-cambiar-de-flavor)
8. [Prerrequisitos e Instalación](#8-prerrequisitos-e-instalación)
9. [Correr en Emulador iOS](#9-correr-en-emulador-ios)
10. [Correr en Dispositivo Físico](#10-correr-en-dispositivo-físico)
11. [Correr en Android](#11-correr-en-android)
12. [Comandos Melos del Monorepo](#12-comandos-melos-del-monorepo)
13. [Agregar un Módulo Nuevo](#13-agregar-un-módulo-nuevo)
14. [Estructura Completa del Proyecto](#14-estructura-completa-del-proyecto)

---

## 1. Visión General

Fintech App es un **monorepo Flutter gestionado con Melos** que aplica el patrón
de **microfrontends** a una app móvil: diez paquetes Dart/Flutter independientes
—siete de dominio, dos de plataforma y el shell que los ensambla— donde cada uno
se prueba solo, se versiona solo y puede **publicarse en pub.dev**, venderse como
librería o integrarse en otra app Flutter.

Qué significa eso en concreto, y qué no, está en
[2.0 Microfrontends en una app móvil](#20-microfrontends-en-una-app-móvil).

### Los diez paquetes

Cada uno tiene su propio README con su contrato, sus rutas y sus decisiones.

| Paquete | Qué es | Rutas | Home |
|---|---|---|---|
| [`fa_core`](packages/fa_core/README.md) | El contrato: `IModule`, `ApiClient`, `AppSession` | — | — |
| [`fa_design_system`](packages/fa_design_system/README.md) | Tokens, `DsScale` y ~35 componentes | — | — |
| [`fa_auth`](packages/fa_auth/README.md) | Splash, login y sesión | `/splash`, `/login` | — |
| [`fa_onboarding`](packages/fa_onboarding/README.md) | El alta: OTP, OCR de INE, análisis | `/onboarding/*` | — |
| [`fa_credit`](packages/fa_credit/README.md) | Catálogo, contratación y vida del crédito | `/credit/*` | tarjeta (20) |
| [`fa_placements`](packages/fa_placements/README.md) | Colocación B2B2C | `/placements/*` | tarjeta (10) + 2 tabs |
| [`fa_wallet`](packages/fa_wallet/README.md) | Saldo, movimientos y envíos | `/wallet/*` | tab |
| [`fa_notifications`](packages/fa_notifications/README.md) | Bandeja y no leídas | `/notifications` | badge |
| [`fa_profile`](packages/fa_profile/README.md) | El expediente, en consulta | `/profile` | — |
| [`fa_shell`](packages/fa_shell/README.md) | La app: ensambla, rutea y no conoce a nadie | — | — |

```
fintech-app/
├── packages/
│   ├── fa_core           → Contratos, ApiClient, IModule (base de todo)
│   ├── fa_design_system  → UI Kit: tokens, componentes, temas (Material 3)
│   ├── fa_auth           → Login, sesión, splash
│   ├── fa_onboarding     → Alta de prospecto (persona): OTP, OCR de INE, KYC, consentimientos
│   ├── fa_wallet         → Billetera, saldo, transferencias
│   ├── fa_credit         → Solicitud de crédito (producto → scoring), cuenta, pagos, disposición
│   ├── fa_notifications  → Bandeja de notificaciones
│   ├── fa_profile        → Perfil de usuario
│   └── fa_shell          → App ensambladora (entry point final)
├── melos.yaml
└── pubspec.yaml
```

**Stack técnico:**

| Tecnología | Propósito |
|---|---|
| Flutter 3.41+ / Dart 3.11+ | Framework UI |
| Melos 6.x | Gestión del monorepo |
| Provider / ChangeNotifier | State management |
| GoRouter 14.x | Navegación declarativa |
| Dio 5.x | HTTP client |
| Clean Architecture | Patrón por módulo |

---

### 1.1 Flujo de negocio: alta de prospecto ≠ crédito (ADR-001)

El backend ([fintech-services](../fintech-services)) está re-orientado por **ADR-001**: la
**persona se da de alta sin elegir producto** (un `Prospect`), y el **crédito se solicita
aparte**. La app refleja esa separación en dos flujos independientes:

**A) Alta de prospecto — `fa_onboarding`** (crea sólo la persona + identidad + consentimientos):

```
welcome → privacy → phone → OTP → INE (captura) → OCR (revisión)
       → datos personales + contacto + domicilio → clave → registro
```

Contra el BFF `channel-mobile-service` (único punto de entrada):

```
1. POST /otp/send            envía OTP
2. POST /otp/verify          → devuelve preAuthToken (JWT corto)
3. POST /ocr/extract         (Bearer preAuthToken) extrae datos del INE
4. POST /kyc/submit          (Bearer preAuthToken) → devuelve folioKyc
5. POST /auth/register       (Bearer preAuthToken) { folioKyc, password } → { prospectId }
6. POST /auth/login          { phone, password, deviceId } → { accessToken, refreshToken }
```

> El `preAuthToken` de `/otp/verify` viaja como `Bearer` en OCR/KYC/register.
> `/auth/register` crea **sólo el prospecto** (sin producto) y devuelve `prospectId`
> (no tokens); la sesión se obtiene en `/auth/login`. **No** se piden comprobantes de
> ingreso/domicilio en el alta — son documentos por-producto del flujo de crédito.

**B) Solicitud de crédito — `fa_credit`** (la persona ya onboardeada elige un producto):

```
Home (CTA "Solicitar crédito") → selección de producto → monto/plazo
       → envío → polling de la decisión de scoring → aprobado | revisión | rechazado
```

```
GET  /credit/products                 catálogo de productos activos
POST /credit/applications  (Bearer)   { prospectId, productType, requestedAmount?, requestedTerm? }
GET  /credit/applications/{id} (Bearer)  polling de la decisión del scoring
```

El `prospectId` se comparte entre módulos vía `AppSession` (`fa_core`).

---

## 2. Arquitectura y Desacoplamiento

### 2.0 Microfrontends en una app móvil

La palabra viene del web, donde un microfrontend es un fragmento que se compila,
despliega y versiona por separado y que el contenedor descubre en tiempo de
ejecución. En una app móvil eso último no existe: **todo se compila en un solo
binario** y no hay Module Federation que resuelva nada en caliente. Lo que sí se
puede conservar —y es lo que aquí se conserva— son las tres propiedades que
hacen útil el patrón.

| Propiedad | Cómo se logra aquí |
|---|---|
| **Autonomía** | Cada módulo es un paquete Dart publicable, con su dominio, sus casos de uso, sus mocks y sus pruebas. Se le hace `flutter test` solo. |
| **Contrato explícito** | `IModule`. Un módulo aparece en la app declarando rutas, providers, tabs y tarjeta; jamás lo referencia otro módulo. |
| **Reemplazabilidad** | Quitar un módulo del `ShellInjection` deja la app compilando, sin esa funcionalidad y entera. |

El precio de no tener federación es que **el ensamblado ocurre en tiempo de
compilación**, en un solo archivo. La ganancia es que el contrato se verifica con
el analizador, no en producción: si un módulo deja de cumplir `IModule`, no
compila.

#### Las tres reglas que sostienen el patrón

**1. El shell no conoce a nadie.** `ShellInjection` es el único archivo del
repositorio que importa los `fa_*`, y sólo para instanciarlos y guardarlos como
`IModule`. A partir de ahí el shell habla con la interfaz.

**2. Ningún módulo importa a otro módulo.** La única excepción es
`fa_credit → fa_wallet`, y es una dependencia del negocio, no un atajo: el
desembolso aterriza en la cuenta y el pago sale de ella.

**3. Lo que dos módulos necesitan saber, lo publica el shell.** Ni `fa_credit`
ni `fa_placements` se conocen, pero ambos necesitan saber si el titular tiene
línea de colocación. Ese hecho vive en `AppSession`, en `fa_core`: uno lo
escribe, el otro lo lee, ninguno sabe del otro.

#### Cómo se compone una pantalla entre varios módulos

El home es el caso interesante, porque **no lo escribe nadie**. El shell pinta el
saludo y el nav; el contenido lo aportan los módulos y él sólo lo apila en el
orden que cada uno declara:

```
┌─ DsBrandBar ──────────────── fa_shell, sobre todas las pantallas
│  avatar (fa_profile)  ·  logo  ·  campana (fa_notifications → badge)
├─ "Hola, Emmanuel" ────────── fa_shell
├─ MI LÍNEA DE DISTRIBUIDOR ── fa_placements   homeCardOrder = 10
├─ MIS CRÉDITOS ───────────── fa_credit       homeCardOrder = 20
├─ Oportunidades ──────────── fa_credit       (dentro de su misma card)
└─ nav: Inicio · Movimientos · Colocaciones · Beneficiarios
        └ fa_shell   fa_wallet    fa_placements (ambos, si hay línea)
```

`homeCardOrder` no es cosmético: es **prelación**. Primero el dinero del que el
titular responde frente a Kredius, después el que tomó para sí, al final lo que
se le ofrece. Antes ese orden lo daba el renglón en que cada módulo quedaba en
`ShellInjection` —moverlo cambiaba la jerarquía en silencio—; ahora lo declara el
módulo y lo fija una prueba.

#### Qué no se puede hacer, y por qué está bien

- **Desplegar un módulo sin recompilar la app.** No hay forma en móvil sin un
  intérprete embebido, y eso trae más problemas de los que resuelve.
- **Que dos módulos usen versiones distintas de `fa_core`.** El monorepo los
  resuelve por `path`; al publicarlos en pub.dev cada uno declara su rango.
- **Equipos desplegando por separado.** Pueden desarrollar y probar por separado
  —que es donde está el 90 % del beneficio—, pero la app sale en un solo tren.

### 2.1 Principio Fundamental

Cada módulo `fa_*` sigue **Clean Architecture** con cuatro capas:

```
fa_wallet/lib/src/
├── domain/          ← Entidades y puertos (interfaces puras, sin dependencias externas)
│   ├── entities/
│   └── ports/       ← Interfaces: IWalletRepository
├── application/     ← Casos de uso (solo orquestan domain)
│   └── use_cases/
├── infrastructure/  ← Implementaciones concretas (Dio, DTOs, Mocks)
│   ├── adapters/    ← Implementa los puertos del domain
│   ├── dtos/        ← Mapeo JSON ↔ entidades
│   └── mock/        ← Interceptor Dio para modo sin servidor
└── presentation/    ← UI: Provider + Screens
    ├── providers/
    └── screens/
```

### 2.2 Flujo de datos en un módulo

```
Pantalla (Screen)
    ↓  llama a
Provider (ChangeNotifier)
    ↓  ejecuta
UseCase (Application)
    ↓  llama a la interfaz
IRepository (Domain Port)
    ↑  implementada por
RepositoryImpl (Infrastructure)
    ↓  hace HTTP via
ApiClient (fa_core — interfaz abstracta)
    ↑  implementada por
DioApiClient (fa_shell) ← aquí viven los interceptores mock
```

El módulo **nunca sabe** si está hablando con un servidor real o con un mock. Solo conoce la interfaz `ApiClient`.

### 2.3 Desacoplamiento entre módulos

Los módulos no se importan entre sí directamente. La comunicación inter-módulo ocurre únicamente mediante:

- **`NavigationCallbacks`**: el módulo A le dice al shell "quiero navegar a X" y el shell decide cómo hacerlo.
- **`IModule.buildHomeCard()`**: cada módulo expone opcionalmente un widget para la pantalla principal; el shell los compone.

**Excepción controlada**: `fa_credit` importa `fa_wallet` porque la disposición de crédito acredita dinero a la wallet. Este es el único acoplamiento horizontal y está documentado en la dependencia de pubspec.

---

## 3. Mapa de Dependencias

```
fa_core ──────────────────────────────────────────┐
                                                   │ dependen de
fa_design_system ─────────────────────────────────┤
                                                   ↓
fa_auth          →  fa_core + fa_design_system
fa_onboarding    →  fa_core + fa_design_system
fa_wallet        →  fa_core + fa_design_system
fa_notifications →  fa_core + fa_design_system
fa_profile       →  fa_core + fa_design_system
fa_credit        →  fa_core + fa_design_system + fa_wallet  ← único acoplamiento horizontal

fa_shell         →  todos los anteriores
```

**Regla de hierro**: ningún paquete `fa_feature` puede importar a otro `fa_feature`, salvo `fa_credit → fa_wallet` que es explícito y justificado.

---

## 4. Contratos Clave: Cómo se Desacoplan los Módulos

### 4.1 `IModule` — El contrato de todo módulo

**Archivo**: `packages/fa_core/lib/src/contracts/i_module.dart`

```dart
abstract interface class IModule {
  String get moduleId;
  String get version;

  void configure({
    required ApiClient apiClient,
    required NavigationCallbacks navigation,
  });

  List<Widget> get providers;   // ChangeNotifierProvider(s) del módulo
  List<RouteBase> get routes;   // Rutas GoRouter del módulo
  Widget? buildHomeCard(BuildContext context); // Tarjeta para el Home
}
```

Cualquier módulo que implemente esta interfaz puede enchufarse al shell sin modificar el shell. El shell solo itera sobre `List<IModule>` y llama a sus métodos.

**Cómo el shell ensambla los módulos** (`shell_injection.dart`):

```dart
abstract final class ShellInjection {
  static ApiClient buildApiClient() {
    if (AppConfig.current.isMock) {
      return DioApiClient(
        baseUrl: AppConfig.current.bffUrl,
        interceptors: [
          AuthMockInterceptor(),
          OnboardingMockInterceptor(),
          WalletMockInterceptor(),
          CreditMockInterceptor(),
          NotificationsMockInterceptor(),
          ProfileMockInterceptor(),
        ],
      );
    }
    return DioApiClient(baseUrl: AppConfig.current.bffUrl);
  }

  static List<IModule> buildModules({
    required ApiClient apiClient,
    required NavigationCallbacks navigation,
  }) {
    final modules = <IModule>[
      AuthModule(),
      OnboardingModule(),
      WalletModule(),
      CreditModule(),
      NotificationsModule(),
      ProfileModule(),
    ];
    for (final m in modules) {
      m.configure(apiClient: apiClient, navigation: navigation);
    }
    return modules;
  }
}
```

Para **agregar un módulo nuevo** solo se hace: 1) crear la clase que implementa `IModule`, 2) agregarla a esta lista.

### 4.2 `ApiClient` — Abstracción HTTP

**Archivo**: `packages/fa_core/lib/src/network/api_client.dart`

```dart
abstract interface class ApiClient {
  Future<Map<String, dynamic>> get(String path, {
    Map<String, String>? headers,
    Map<String, dynamic>? queryParams,
  });
  Future<Map<String, dynamic>> post(String path, {
    Map<String, dynamic>? body,
    Map<String, String>? headers,
  });
  Future<Map<String, dynamic>> put(String path, {
    Map<String, dynamic>? body,
    Map<String, String>? headers,
  });
  Future<Map<String, dynamic>> delete(String path, {
    Map<String, String>? headers,
  });
}
```

Los módulos solo usan esta interfaz. El shell provee la implementación concreta (`DioApiClient`). Esto permite:
- Cambiar Dio por http, Retrofit, o cualquier otra librería sin tocar ningún módulo.
- Inyectar interceptores mock solo en el shell.
- En tests de módulo, proveer un `FakeApiClient` trivial.

### 4.3 `NavigationCallbacks` — Navegación sin acoplamiento

**Archivo**: `packages/fa_core/lib/src/contracts/navigation_callbacks.dart`

```dart
class NavigationCallbacks {
  final void Function(String userId) onLoginSuccess;
  final void Function() onLogout;
  final void Function() onOnboardingComplete;
  final void Function(String creditId) onCreditDetail;
  final void Function() onWalletTransfer;
  final void Function() onSupportRequest;

  const NavigationCallbacks({
    required this.onLoginSuccess,
    required this.onLogout,
    required this.onOnboardingComplete,
    required this.onCreditDetail,
    required this.onWalletTransfer,
    required this.onSupportRequest,
  });
}
```

El módulo `fa_auth` **no sabe** que existe GoRouter ni que hay una ruta `/home`. Cuando el login es exitoso llama a `_navigation.onLoginSuccess(userId)`. El shell, al configurar los callbacks, define qué pasa:

```dart
// En main.dart del shell:
final navigation = NavigationCallbacks(
  onLoginSuccess: (userId) => _router.go('/home'),
  onLogout: () => _router.go('/login'),
  onOnboardingComplete: () => _router.go('/login'),
  // ...
);
```

Si el comprador del módulo usa Navigator 2.0 en lugar de GoRouter, solo cambia estos callbacks.

### 4.4 `AppConfig` — Configuración de ambiente

**Archivo**: `packages/fa_core/lib/src/config/app_config.dart`

```dart
enum AppFlavor { mock, qa, prod }

class AppConfig {
  final AppFlavor flavor;
  final String bffUrl;

  static late AppConfig current;

  static void setup({required AppFlavor flavor, String? bffUrl}) {
    current = AppConfig._(
      flavor: flavor,
      bffUrl: bffUrl ?? switch (flavor) {
        AppFlavor.mock => 'https://mock.fintechapp.mx',
        AppFlavor.qa   => 'https://api-qa.fintechapp.mx/v1',
        AppFlavor.prod => 'https://api.fintechapp.mx/v1',
      },
    );
  }

  bool get isMock => flavor == AppFlavor.mock;
}
```

Se inicializa una vez al inicio de cada entry point (`main.dart`, `main_qa.dart`, `main_prod.dart`) antes de `runApp`.

---

## 5. Sistema de Mocks e Interceptores

### 5.1 Arquitectura del mock

El mock **no usa un servidor**. Se implementa como un `Interceptor` de Dio: intercepta la request antes de que salga a la red, construye una response JSON y la devuelve directamente.

```
Request HTTP
    ↓
Dio interceptors pipeline
    ↓
XxxMockInterceptor.onRequest()
    ↓
  ¿path coincide?
  SÍ → handler.resolve(Response(data: mockData))  ← nunca toca la red
  NO → handler.next(options)                       ← pasa al siguiente interceptor
```

Cada módulo tiene su propio interceptor en `infrastructure/mock/`. Esto es importante: el módulo **encapsula su propio mock**, nadie más necesita saber cómo generar datos de wallet o crédito.

### 5.2 Anatomía de un interceptor: `AuthMockInterceptor`

**Archivo**: `packages/fa_auth/lib/src/infrastructure/mock/auth_mock_interceptor.dart`

```dart
class AuthMockInterceptor extends Interceptor {
  // Paths que este interceptor conoce y maneja
  static const _paths = {'/auth/login', '/auth/logout', '/auth/register'};

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    if (!_paths.contains(options.path)) {
      handler.next(options); // No es mi ruta, pasar al siguiente
      return;
    }
    Future.delayed(_delay(options.path), () {
      handler.resolve(Response(
        requestOptions: options,
        data: _resolve(options),
        statusCode: 200,
      ));
    });
  }

  Map<String, dynamic> _resolve(RequestOptions req) {
    final path = req.path;
    if (path == '/auth/login') return _login(req.data as Map?);
    if (path == '/auth/logout') return {'success': true};
    return {'success': true, 'userId': 'usr_emf_001'};
  }

  Map<String, dynamic> _login(Map? body) {
    final phone = body?['phone'] as String? ?? '';
    final password = body?['password'] as String? ?? '';
    if (phone.isNotEmpty && password.length >= 6) {
      return {
        'success': true,
        'token': 'mock_jwt_token_emf_001',
        'userId': 'usr_emf_001',
      };
    }
    throw Exception('Credenciales inválidas');
  }

  // Simula latencia real por endpoint
  Duration _delay(String path) {
    if (path.contains('/auth/login')) return const Duration(milliseconds: 700);
    return const Duration(milliseconds: 200);
  }
}
```

Puntos clave:
- **`_paths`**: el set de rutas que este interceptor maneja. Cualquier otra ruta se pasa con `handler.next()` al siguiente interceptor de la cadena.
- **`Future.delayed(_delay(...))`**: simula latencia de red diferenciada por endpoint. Login simula 700 ms, logout 200 ms.
- **`handler.resolve(...)`**: resuelve la request con data mock sin tocar la red.
- El `DioApiClient` en el shell encadena todos los interceptores: el primero que reconoce la ruta gana.

### 5.3 Interceptor de Wallet: datos ricos para demos

**Archivo**: `packages/fa_wallet/lib/src/infrastructure/mock/wallet_mock_interceptor.dart`

```dart
class WalletMockInterceptor extends Interceptor {
  static const _paths = {
    '/wallet/balance',
    '/wallet/transactions',
    '/wallet/transfer',
  };

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    if (!_paths.contains(options.path)) { handler.next(options); return; }
    Future.delayed(_delay(options.path), () {
      handler.resolve(Response(
        requestOptions: options,
        data: _resolve(options),
        statusCode: 200,
      ));
    });
  }

  Map<String, dynamic> _resolve(RequestOptions req) {
    switch (req.path) {
      case '/wallet/balance':
        return {
          'available': 13596.00,
          'accountNumber': '6673038098',
          'clabe': '646180557000123456',
          'currency': 'MXN',
        };
      case '/wallet/transactions':
        final d = (int days) =>
            DateTime.now().subtract(Duration(days: days)).toIso8601String();
        return {
          'transactions': [
            {'id': 't1', 'type': 'credit', 'category': 'disposicion',
             'description': 'Disposición de crédito', 'amount': 12000.0, 'date': d(0)},
            {'id': 't2', 'type': 'debit', 'category': 'payment',
             'description': 'Netflix', 'amount': 199.0, 'date': d(1), 'merchant': 'Netflix'},
            {'id': 't3', 'type': 'credit', 'category': 'deposit',
             'description': 'Depósito SPEI', 'amount': 5000.0, 'date': d(2)},
          ],
        };
      case '/wallet/transfer':
        return {
          'success': true,
          'transferId': 'TRF-${DateTime.now().millisecondsSinceEpoch}',
        };
      default:
        return {'success': true};
    }
  }

  Duration _delay(String path) {
    if (path.contains('/transfer')) return const Duration(milliseconds: 1100);
    if (path.contains('/transactions')) return const Duration(milliseconds: 460);
    return const Duration(milliseconds: 380);
  }
}
```

### 5.4 Cómo se encadenan todos los interceptores en el Shell

**Archivo**: `packages/fa_shell/lib/src/di/shell_injection.dart`

```dart
return DioApiClient(
  baseUrl: AppConfig.current.bffUrl,
  interceptors: [
    AuthMockInterceptor(),          // maneja /auth/*
    OnboardingMockInterceptor(),    // maneja /otp/*, /ocr/*, /kyc/*
    WalletMockInterceptor(),        // maneja /wallet/*
    CreditMockInterceptor(),        // maneja /credit/*
    NotificationsMockInterceptor(), // maneja /notifications/*
    ProfileMockInterceptor(),       // maneja /profile/*
  ],
);
```

En modo `AppFlavor.qa` o `AppFlavor.prod` no se agrega ningún interceptor, por lo que todas las requests salen a la red normalmente.

### 5.5 `DioApiClient` — Implementación concreta

**Archivo**: `packages/fa_shell/lib/src/network/dio_api_client.dart`

```dart
class DioApiClient implements ApiClient {
  DioApiClient({
    required String baseUrl,
    List<Interceptor> interceptors = const [],
  }) {
    _dio = Dio(BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ));
    _dio.interceptors.addAll(interceptors);
  }

  late final Dio _dio;

  @override
  Future<Map<String, dynamic>> get(String url, {...}) async {
    final res = await _dio.get<Map<String, dynamic>>(url, ...);
    return res.data!;
  }
  // post, put, delete análogos...
}
```

`DioApiClient` vive en el shell, no en `fa_core`. Los módulos de dominio solo usan la interfaz `ApiClient`. Si mañana quieres cambiar a `http` de Dart o a Retrofit, solo reemplazas `DioApiClient` en el shell.

---

## 6. Comercialización de Módulos Independientes

### 6.1 Modelo de licenciamiento

Cada paquete `fa_*` es independiente y puede venderse por separado. Los precios sugeridos y los paquetes mínimos:

| Módulo | Dependencias requeridas | Descripción |
|---|---|---|
| `fa_core` | ninguna | Contratos base. Siempre requerido. |
| `fa_design_system` | ninguna | UI Kit. Requerido si se usa cualquier pantalla. |
| `fa_auth` | `fa_core`, `fa_design_system` | Login + sesión + splash |
| `fa_onboarding` | `fa_core`, `fa_design_system` | Alta de prospecto: OTP + OCR + KYC |
| `fa_wallet` | `fa_core`, `fa_design_system` | Billetera + transferencias |
| `fa_credit` | `fa_core`, `fa_design_system`, `fa_wallet` | Solicitud de crédito + cuenta |
| `fa_notifications` | `fa_core`, `fa_design_system` | Bandeja de notificaciones |
| `fa_profile` | `fa_core`, `fa_design_system` | Perfil de usuario |

### 6.2 Cómo un comprador integra un módulo

El comprador hace:

**Paso 1 — Declarar dependencias en su `pubspec.yaml`:**

```yaml
dependencies:
  fa_core:
    git:
      url: https://github.com/tu-org/fa_core.git
      ref: v1.0.0
  fa_design_system:
    git:
      url: https://github.com/tu-org/fa_design_system.git
      ref: v1.0.0
  fa_wallet:
    git:
      url: https://github.com/tu-org/fa_wallet.git
      ref: v1.0.0
  # sus propias dependencias
  dio: ^5.7.0
  provider: ^6.1.2
  go_router: ^14.3.0
```

**Paso 2 — Configurar `AppConfig` (una vez al inicio):**

```dart
void main() {
  AppConfig.setup(flavor: AppFlavor.prod); // o qa, o mock
  runApp(const MyApp());
}
```

**Paso 3 — Implementar `ApiClient` con su propio setup de Dio:**

```dart
// El comprador trae su propio DioApiClient o usa el que vendas junto al módulo.
// Solo necesita implementar la interfaz:
class MyApiClient implements ApiClient {
  final Dio _dio = Dio(BaseOptions(
    baseUrl: 'https://api.mi-empresa.com/v1',
    headers: {'Authorization': 'Bearer ${MyAuthService.token}'},
  ));

  @override
  Future<Map<String, dynamic>> get(String path, {...}) async {
    final res = await _dio.get(path, ...);
    return res.data as Map<String, dynamic>;
  }
  // ...
}
```

**Paso 4 — Crear y configurar el módulo:**

```dart
final apiClient = MyApiClient();
final walletModule = WalletModule();

walletModule.configure(
  apiClient: apiClient,
  navigation: NavigationCallbacks(
    onLoginSuccess: (_) {},
    onLogout: () => myRouter.go('/login'),
    onOnboardingComplete: () {},
    onCreditDetail: (_) {},
    onWalletTransfer: () => myRouter.go('/wallet/send'),
    onSupportRequest: () {},
  ),
);
```

**Paso 5 — Registrar providers y rutas:**

```dart
class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: walletModule.providers.cast<SingleChildWidget>(),
      child: MaterialApp.router(
        routerConfig: GoRouter(
          routes: [
            ...walletModule.routes,
            // las demás rutas de mi app
          ],
        ),
      ),
    );
  }
}
```

Con esto el comprador tiene todas las pantallas de `fa_wallet` (movimientos, envío de dinero) y la tarjeta para el home, conectadas a su propio backend via su implementación de `ApiClient`.

### 6.3 Modo demo con mocks

Si el comprador quiere una demo sin backend, agrega los interceptores mock del módulo:

```dart
final apiClient = DioApiClient(
  baseUrl: 'https://demo.mi-empresa.com',
  interceptors: [WalletMockInterceptor()], // viene en el paquete fa_wallet
);
```

Todos los interceptores mock están exportados en el barrel file de cada módulo.

### 6.4 Sustitución del Design System

Si el comprador tiene su propio design system:
- No importa `fa_design_system`.
- Crea sus propias pantallas que usan sus componentes propios.
- Las pantallas del módulo son reemplazables porque la lógica está en el Provider/UseCase/Repository, no en las pantallas.

Para esto, el comprador puede crear su propio módulo que reutiliza solo las capas `domain`, `application` e `infrastructure`:

```dart
// El comprador solo usa estas capas:
import 'package:fa_wallet/src/domain/ports/i_wallet_repository.dart';
import 'package:fa_wallet/src/application/use_cases/get_wallet_use_case.dart';
import 'package:fa_wallet/src/infrastructure/adapters/wallet_repository_impl.dart';
// Y construye sus propias pantallas con su propio design system
```

---

## 7. Ambientes y Flavors

### 7.1 Qué es un flavor en este proyecto

El proyecto no usa flavors nativos de Xcode/Gradle (product flavors). En su lugar, cada **entry point** (`main.dart`, `main_qa.dart`, `main_prod.dart`) inicializa `AppConfig` con un `AppFlavor` diferente antes de llamar a `runApp`. Flutter resuelve cuál correr con el flag `--target`.

| Entry point | Flavor | BFF URL | Mocks activos |
|---|---|---|---|
| `lib/main.dart` | `AppFlavor.mock` | `https://mock.fintechapp.mx` | ✅ Todos los interceptores mock |
| `lib/main_qa.dart` | `AppFlavor.qa` | `https://api-qa.fintechapp.mx/v1` | ❌ Requests reales a QA |
| `lib/main_prod.dart` | `AppFlavor.prod` | `https://api.fintechapp.mx/v1` | ❌ Requests reales a Prod |

> **Regla de oro**: `mock` nunca toca la red. `qa` y `prod` requieren que el servidor esté levantado y accesible.

---

### 7.2 Comandos principales — qué hace cada uno

Antes de correr cualquier cosa, debes estar en el paquete shell:

```bash
cd packages/fa_shell
```

#### `flutter devices` — ver qué tienes disponible

```bash
flutter devices
```

Siempre corre esto primero. Te muestra todos los targets disponibles: simuladores iOS, emuladores Android y dispositivos físicos conectados. Copia el **Device ID** de la segunda columna.

```
Found 3 connected devices:
  iPhone 16 Pro (mobile)        • 280BA0D6-F4F9-4B61-A71C-299EAF739917 • ios  • simulator
  sdk gphone64 arm64 (mobile)   • emulator-5554                         • android-arm64 • emulator
  Emmanuel iPhone (mobile)      • 00008130-000A45D93AD2001C             • ios  • device
```

#### `flutter run` — compilar, instalar y conectar en modo debug

```bash
flutter run -d <DEVICE_ID> --target lib/main.dart
```

- Compila la app en modo **debug**.
- La instala en el dispositivo/simulador.
- Abre una sesión de **hot reload** activa en la terminal.
- La app se conecta al Dart VM Service (puedes inspeccionar con DevTools).
- Al salir con `q` la **app queda instalada** pero la sesión debug termina.

#### `flutter install` — instalar sin abrir sesión debug

```bash
flutter install -d <DEVICE_ID>
```

- Instala el último build compilado **sin** abrir sesión de debug.
- Útil para dejar la app instalada en un dispositivo de QA para que alguien más la pruebe sin tener la terminal conectada.
- **Requiere** haber corrido `flutter build` previamente para que exista el artefacto.

#### `flutter build` — compilar sin instalar

```bash
# iOS (genera .app o .ipa)
flutter build ios --release --target lib/main_qa.dart

# Android (genera .apk o .aab)
flutter build apk --release --target lib/main_qa.dart
flutter build appbundle --release --target lib/main_prod.dart
```

- Genera el artefacto final pero **no lo instala**.
- Usar `--release` para builds de QA y Prod (sin debug symbols, optimizado).
- Usar `--debug` para desarrollo local (con DevTools, hot reload).

#### `flutter attach` — conectar a una app ya corriendo

```bash
flutter attach -d <DEVICE_ID>
```

- Se conecta a una app que ya está corriendo en el dispositivo.
- Útil cuando la app se lanzó manualmente o se reinició el teléfono.
- Habilita hot reload sin tener que reinstalar.

---

### 7.3 Flujo completo: correr en flavor mock (desarrollo diario)

Este es el flujo para desarrollo. No requiere servidor ni red.

```bash
# 1. Ir al shell (siempre desde aquí)
cd packages/fa_shell

# 2. Ver qué dispositivos tienes disponibles
flutter devices

# 3. Bootear el simulador iOS (si usas simulador)
xcrun simctl boot 280BA0D6-F4F9-4B61-A71C-299EAF739917
open -a Simulator

# 4. Correr en mock
flutter run -d 280BA0D6-F4F9-4B61-A71C-299EAF739917 --target lib/main.dart
```

La terminal queda activa con los siguientes atajos:

```
r  → Hot reload     (aplica cambios de UI al instante, conserva el estado)
R  → Hot restart    (reinicia la Dart VM, resetea el estado)
h  → Lista todos los comandos disponibles
q  → Salir de la sesión debug (la app sigue instalada)
d  → Detach (desconecta el debug pero la app sigue corriendo)
```

**Primera vez en un simulador/dispositivo nuevo**: Flutter corre `pod install` automáticamente y puede tardar 3–5 minutos. Las veces siguientes el build incremental tarda 5–15 segundos.

---

### 7.4 Flujo completo: correr en flavor QA

Requiere acceso al servidor de QA (VPN si aplica).

```bash
# 1. Ir al shell
cd packages/fa_shell

# 2. Ver dispositivos
flutter devices

# 3. Correr apuntando a QA
flutter run -d <DEVICE_ID> --target lib/main_qa.dart
```

Para instalar en un dispositivo físico de QA sin mantener la terminal conectada:

```bash
# Compilar el build de QA
flutter build ios --debug --target lib/main_qa.dart
# o para Android:
flutter build apk --debug --target lib/main_qa.dart

# Instalar en el dispositivo (sin sesión debug)
flutter install -d <DEVICE_ID>
```

---

### 7.5 Flujo completo: correr en flavor producción

> ⚠️ Solo usar en validaciones finales. Las acciones en `prod` son reales.

```bash
# 1. Ir al shell
cd packages/fa_shell

# 2. Compilar en release (obligatorio para prod)
flutter build ios --release --target lib/main_prod.dart
# o para Android:
flutter build appbundle --release --target lib/main_prod.dart

# 3. Correr directamente en release (para validar antes de subir a la tienda)
flutter run -d <DEVICE_ID> --target lib/main_prod.dart --release
```

---

### 7.6 Tabla resumen de comandos por flavor

| Objetivo | Comando |
|---|---|
| Listar devices disponibles | `flutter devices` |
| **Mock** — dev con hot reload | `flutter run -d <ID> --target lib/main.dart` |
| **QA** — con hot reload | `flutter run -d <ID> --target lib/main_qa.dart` |
| **Prod** — release sin debug | `flutter run -d <ID> --target lib/main_prod.dart --release` |
| Compilar iOS QA (sin instalar) | `flutter build ios --debug --target lib/main_qa.dart` |
| Compilar iOS Prod release | `flutter build ios --release --target lib/main_prod.dart` |
| Compilar APK QA | `flutter build apk --debug --target lib/main_qa.dart` |
| Compilar AAB Prod | `flutter build appbundle --release --target lib/main_prod.dart` |
| Instalar sin sesión debug | `flutter install -d <ID>` |
| Conectar a app ya corriendo | `flutter attach -d <ID>` |
| Ver logs en tiempo real | `flutter logs -d <ID>` |

---

### 7.7 Errores comunes al cambiar de flavor

**`AppConfig not initialized`**

Significa que se llamó a `AppConfig.current` antes de `AppConfig.setup(...)`. Verifica que el entry point tiene la inicialización al inicio de `main()`:

```dart
void main() {
  AppConfig.setup(flavor: AppFlavor.mock); // ← debe ser la primera línea
  runApp(const App());
}
```

**`SocketException: Connection refused`** en QA o Prod

La app intentó conectarse al servidor pero no tiene acceso. Soluciones:
1. Verifica que estás conectado a la VPN correcta.
2. Confirma que el servidor de QA/Prod está levantado.
3. Si solo quieres ver la UI sin backend, usa `--target lib/main.dart` (flavor mock).

**Build de release falla por signing en iOS**

```bash
# Abre Xcode y firma manualmente:
open ios/Runner.xcworkspace
# Runner target → Signing & Capabilities → Team → tu cuenta
```

---

## 8. Prerrequisitos e Instalación

### 8.1 Herramientas requeridas

Instala exactamente en este orden:

**1. Flutter SDK (versión 3.41 o superior)**

```bash
# Verificar si ya tienes Flutter:
flutter --version

# Si no lo tienes, con Homebrew (macOS):
brew install --cask flutter

# Verificar la instalación:
flutter doctor
```

`flutter doctor` debe mostrar ✓ en Flutter y Dart. Los errores de Android Studio o Xcode solo importan si vas a correr en esa plataforma.

**2. Xcode (solo para iOS/macOS)**

```bash
# Instalar desde App Store o:
xcode-select --install

# Aceptar licencia:
sudo xcodebuild -license accept

# Instalar simuladores (desde Xcode: Xcode → Settings → Platforms → iOS → Download)

# Instalar CocoaPods:
sudo gem install cocoapods
# o con Homebrew:
brew install cocoapods

# Verificar:
pod --version  # debe ser 1.14 o superior
```

**3. Android Studio (solo para Android)**

```bash
# Descargar desde https://developer.android.com/studio
# Después de instalar, instalar Android SDK desde el SDK Manager

# Verificar:
flutter doctor --android-licenses
# Aceptar todas las licencias cuando se pida
```

**4. Melos (gestor del monorepo)**

```bash
dart pub global activate melos

# Agregar al PATH si no está:
export PATH="$PATH:$HOME/.pub-cache/bin"

# Verificar:
melos --version
```

### 8.2 Clonar e inicializar el proyecto

```bash
# Clonar el repositorio
git clone https://github.com/tu-org/fintech-app.git
cd fintech-app

# Bootstrap del monorepo: resuelve dependencias de todos los paquetes
# y genera los pubspec_overrides.yaml de path dependencies locales
melos bootstrap

# Verificar que todos los paquetes tienen dependencias resueltas:
melos exec -- flutter pub get
```

`melos bootstrap` hace automáticamente `flutter pub get` en cada paquete y configura las rutas locales entre paquetes via `pubspec_overrides.yaml`. Siempre corre esto después de clonar o después de agregar nuevas dependencias.

---

## 9. Correr en Emulador iOS

### 9.1 Listar emuladores disponibles

```bash
# Listar todos los simuladores iOS instalados:
xcrun simctl list devices available

# Ejemplo de output:
# == Devices ==
# -- iOS 18.6 --
#     iPhone 16 Pro (280BA0D6-F4F9-4B61-A71C-299EAF739917) (Shutdown)
#     iPhone 15 (A1B2C3D4-...) (Shutdown)
```

### 9.2 Iniciar el simulador

```bash
# Opción A — Por UDID (más preciso):
xcrun simctl boot 280BA0D6-F4F9-4B61-A71C-299EAF739917

# Abrir la app Simulator para verlo en pantalla:
open -a Simulator

# Opción B — Por nombre:
open -a Simulator --args -CurrentDeviceUDID 280BA0D6-F4F9-4B61-A71C-299EAF739917

# Verificar que está booteado:
xcrun simctl list devices | grep Booted
# Output esperado:
# iPhone 16 Pro (280BA0D6-F4F9-4B61-A71C-299EAF739917) (Booted)
```

### 9.3 Correr el proyecto en el simulador

```bash
# Ir al paquete shell (entry point de la app):
cd packages/fa_shell

# Ver dispositivos disponibles para Flutter:
flutter devices

# Correr en el simulador por UDID:
flutter run -d 280BA0D6-F4F9-4B61-A71C-299EAF739917

# O simplemente (si solo hay un simulador booteado):
flutter run
```

**Primera vez**: Flutter instalará los pods de iOS automáticamente (`pod install`). Puede tardar 2-5 minutos.

**Runs subsecuentes**: el build incremental de Xcode tarda entre 3-15 segundos.

### 9.4 Comandos interactivos durante `flutter run`

Una vez corriendo, en la terminal:

```
r  → Hot reload     (recarga widgets sin reiniciar el estado)
R  → Hot restart    (reinicia Dart VM, resetea el estado)
h  → Ver todos los comandos
q  → Salir (termina flutter run, la app sigue instalada)
d  → Detach (sale de flutter run pero deja la app corriendo)
```

### 9.5 Correr un flavor específico

```bash
# Modo mock (default, sin conexión a servidor real):
flutter run -d <UDID> --target lib/main.dart

# Modo QA (apunta a servidor de QA):
flutter run -d <UDID> --target lib/main_qa.dart

# Modo producción:
flutter run -d <UDID> --target lib/main_prod.dart
```

### 9.6 Instalar un simulador diferente

Si necesitas un simulador de iPhone que no tienes instalado:

```bash
# Ver runtimes disponibles para descargar:
xcrun simctl list runtimes

# Crear un nuevo simulador:
xcrun simctl create "iPhone 15" "com.apple.CoreSimulator.SimDeviceType.iPhone-15" \
  "com.apple.CoreSimulator.SimRuntime.iOS-17-5"

# O desde Xcode: Xcode → Window → Devices and Simulators → + (inferior izquierdo)
```

---

## 10. Correr en Dispositivo Físico

### 10.1 iOS (iPhone real)

**Prerrequisito**: necesitas una Apple Developer Account (gratuita para desarrollo personal).

```bash
# 1. Conectar el iPhone por cable USB

# 2. Confiar en la computadora:
#    En el iPhone: Settings → General → VPN & Device Management → Trust

# 3. Ver si Flutter detecta el dispositivo:
flutter devices
# Output esperado:
# Emmanuel Hernandez iPhone (mobile) • 00008130-000A45D93AD2001C • ios • iOS 18.x

# 4. Abrir Xcode para firmar la app:
open packages/fa_shell/ios/Runner.xcworkspace
# En Xcode: Runner target → Signing & Capabilities → Team → seleccionar tu cuenta

# 5. Correr:
cd packages/fa_shell
flutter run -d 00008130-000A45D93AD2001C

# O si solo hay un dispositivo físico conectado:
flutter run -d physical
```

**Error frecuente**: "Unable to install app" → abre Xcode, corre el proyecto desde ahí la primera vez para que registre el device en tu cuenta.

### 10.2 iOS inalámbrico (Wi-Fi)

```bash
# Prerequisito: el iPhone debe estar conectado por cable al menos una vez
# y tener habilitado Connect via Network en Xcode

# En Xcode: Window → Devices and Simulators → tu iPhone → Connect via network ✓

# Correr por Wi-Fi (el UDID es el mismo):
flutter run -d 00008130-000A45D93AD2001C
```

---

## 11. Correr en Android

### 11.1 Emulador Android (AVD)

```bash
# Listar AVDs existentes:
flutter emulators

# Crear un AVD (si no tienes ninguno):
# Android Studio → Device Manager → Create Device

# Iniciar el emulador:
flutter emulators --launch Pixel_8_API_35
# o
flutter run -d emulator-5554

# Listar dispositivos detectados por Flutter:
flutter devices
```

### 11.2 Dispositivo Android físico

```bash
# 1. Habilitar Developer Options en el Android:
#    Settings → About Phone → Build Number × 7 veces

# 2. Habilitar USB Debugging:
#    Settings → Developer Options → USB Debugging → ON

# 3. Conectar por cable y aceptar la autorización en el teléfono

# 4. Verificar:
adb devices
# Output: List of devices attached
#         R5CW4... device

# 5. Correr:
flutter run
```

---

## 12. Comandos Melos del Monorepo

Melos permite correr comandos en todos los paquetes a la vez desde la raíz del monorepo.

```bash
# Desde la raíz del repo (donde está melos.yaml):
cd /ruta/a/fintech-app

# Resolver dependencias de TODOS los paquetes:
melos bootstrap

# Correr tests en todos los paquetes:
melos run test:all

# Correr tests de un paquete específico:
melos run test:fa_auth
melos run test:fa_wallet
melos run test:fa_credit

# Analizar código de todos los paquetes:
melos run analyze:all

# Limpiar builds de todos los paquetes:
melos run clean:all

# Generar código (build_runner) en todos los que lo necesiten:
melos run gen:all
```

**Correr un comando arbitrario en todos los paquetes:**

```bash
# flutter pub get en todos:
melos exec -- flutter pub get

# flutter test en todos:
melos exec -- flutter test

# flutter analyze en todos:
melos exec -- flutter analyze

# Solo en paquetes que tienen cierta dependencia:
melos exec --depends-on=dio -- flutter test
```

---

## 13. Agregar un Módulo Nuevo

Ejemplo: agregar `fa_investments` (módulo de inversiones).

### Paso 1 — Crear la estructura del paquete

```bash
mkdir -p packages/fa_investments/lib/src/{domain/{entities,ports},application/use_cases,infrastructure/{adapters,mock},presentation/{providers,screens}}
touch packages/fa_investments/lib/fa_investments.dart
```

### Paso 2 — Crear `pubspec.yaml`

```yaml
# packages/fa_investments/pubspec.yaml
name: fa_investments
description: "Fintech App Investments — módulo de inversiones."
version: 1.0.0
publish_to: none

environment:
  sdk: ">=3.4.0 <4.0.0"
  flutter: ">=3.22.0"

dependencies:
  flutter:
    sdk: flutter
  fa_core:
    path: ../fa_core
  fa_design_system:
    path: ../fa_design_system
  provider: ^6.1.2
  go_router: ^14.3.0
  dio: ^5.7.0
```

### Paso 3 — Implementar `IModule`

```dart
// packages/fa_investments/lib/investments_module.dart
import 'package:fa_core/fa_core.dart';

class InvestmentsModule implements IModule {
  late ApiClient _apiClient;
  late NavigationCallbacks _navigation;

  @override
  String get moduleId => 'fa_investments';

  @override
  String get version => '1.0.0';

  @override
  void configure({required ApiClient apiClient, required NavigationCallbacks navigation}) {
    _apiClient = apiClient;
    _navigation = navigation;
  }

  @override
  List<Widget> get providers => [
        ChangeNotifierProvider<InvestmentsProvider>(
          create: (_) => InvestmentsProvider(
            getPortfolio: GetPortfolioUseCase(
              InvestmentsRepositoryImpl(apiClient: _apiClient),
            ),
          ),
        ),
      ];

  @override
  List<RouteBase> get routes => [
        GoRoute(
          path: '/investments',
          builder: (_, __) => const InvestmentsScreen(),
        ),
      ];

  @override
  Widget? buildHomeCard(BuildContext context) => const InvestmentsHomeCard();
}
```

### Paso 4 — Crear el mock interceptor

```dart
// packages/fa_investments/lib/src/infrastructure/mock/investments_mock_interceptor.dart
class InvestmentsMockInterceptor extends Interceptor {
  static const _paths = {'/investments/portfolio', '/investments/buy'};

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    if (!_paths.contains(options.path)) { handler.next(options); return; }
    Future.delayed(const Duration(milliseconds: 500), () {
      handler.resolve(Response(
        requestOptions: options,
        data: {'totalValue': 50000.0, 'positions': []},
        statusCode: 200,
      ));
    });
  }
}
```

### Paso 5 — Registrar en el shell

En `packages/fa_shell/pubspec.yaml` agregar:

```yaml
dependencies:
  fa_investments:
    path: ../fa_investments
```

En `packages/fa_shell/lib/src/di/shell_injection.dart`:

```dart
import 'package:fa_investments/fa_investments.dart';

// En buildApiClient():
interceptors: [
  ...
  InvestmentsMockInterceptor(), // agregar aquí
],

// En buildModules():
final modules = <IModule>[
  ...
  InvestmentsModule(), // agregar aquí
];
```

### Paso 6 — Actualizar dependencias

```bash
cd packages/fa_shell
flutter pub get

# O desde la raíz:
melos bootstrap
```

El módulo ya está integrado. GoRouter recolecta sus rutas automáticamente via `module.routes`.

---

## 14. Estructura Completa del Proyecto

```
fintech-app/
├── melos.yaml                          ← configuración del monorepo
├── pubspec.yaml                        ← dependencias de desarrollo (melos)
├── .gitignore                          ← deja fuera caches, Pods y evidencias/
│
├── docs/                               ← documentación viva del proyecto
│   ├── design/                         ← la especificación de la interfaz
│   │   ├── Kredius Journey App.dc.html ← prototipo: 186 comentarios lo citan
│   │   └── README.md                   ← dónde está cada pantalla, por línea
│   ├── KREDIUS_E2E_VIDEOS.md           ← cómo regrabar los cinco recorridos
│   ├── KREDIUS_COLOCACION_API.md       ← contrato congelado del B2B2C
│   └── …
│
├── evidencias/                         ← videos de los E2E (NO se versiona)
│
└── packages/
    │
    ├── fa_core/                        ← CONTRATOS BASE (sin dependencias Flutter)
    │   └── lib/
    │       ├── fa_core.dart            ← barrel: exporta todo lo público
    │       └── src/
    │           ├── config/
    │           │   └── app_config.dart ← AppFlavor, AppConfig.setup()
    │           ├── contracts/
    │           │   ├── i_module.dart   ← interfaz IModule + HomeTab
    │           │   └── navigation_callbacks.dart
    │           ├── network/
    │           │   └── api_client.dart ← interfaz ApiClient
    │           ├── presentation/
    │           │   ├── safe_notifier.dart ← no avisar tras destruirse
    │           │   └── nombres.dart    ← comoNombrePropio
    │           └── session/
    │               ├── app_session.dart   ← los hechos de nadie
    │               └── credit_purpose.dart
    │
    ├── fa_design_system/               ← UI KIT
    │   └── lib/
    │       ├── fa_design_system.dart   ← barrel
    │       └── src/
    │           ├── theme/              ← AppTheme.light, colores
    │           └── widgets/            ← DsButton, DsTextField, DsLoaderOverlay...
    │
    ├── fa_auth/                        ← MÓDULO: AUTENTICACIÓN
    │   └── lib/
    │       ├── fa_auth.dart            ← barrel
    │       ├── auth_module.dart        ← AuthModule implements IModule
    │       └── src/
    │           ├── domain/entities/auth_user.dart
    │           ├── domain/ports/i_auth_repository.dart
    │           ├── application/use_cases/login_use_case.dart
    │           ├── infrastructure/adapters/auth_repository_impl.dart
    │           ├── infrastructure/mock/auth_mock_interceptor.dart
    │           └── presentation/{providers,screens}/
    │
    ├── fa_onboarding/                  ← MÓDULO: ALTA DE PROSPECTO (OTP + OCR + KYC)
    │   └── lib/
    │       ├── fa_onboarding.dart
    │       ├── onboarding_module.dart
    │       └── src/
    │           ├── domain/entities/{kyc_state,kyc_status,ocr_extracted_data,personal_data,ine_images,document_file}.dart
    │           ├── domain/ports/{i_kyc_repository,i_otp_repository,i_ocr_repository}.dart
    │           ├── application/use_cases/{send_otp,verify_otp,extract_ocr,submit_kyc}_use_case.dart
    │           ├── infrastructure/adapters/{kyc,otp,ocr}_repository_impl.dart
    │           ├── infrastructure/mock/onboarding_mock_interceptor.dart
    │           └── presentation/screens/ (welcome → privacy → phone → otp → ine → ocr → datos → clave → success)
    │
    ├── fa_wallet/                      ← MÓDULO: BILLETERA
    │   └── lib/
    │       ├── fa_wallet.dart
    │       ├── wallet_module.dart
    │       └── src/
    │           ├── domain/entities/{wallet_balance,transaction}.dart
    │           ├── domain/ports/i_wallet_repository.dart
    │           ├── application/use_cases/{get_wallet,get_transactions,send_transfer}_use_case.dart
    │           ├── infrastructure/adapters/wallet_repository_impl.dart
    │           ├── infrastructure/dtos/{wallet_balance,transaction}_dto.dart
    │           ├── infrastructure/mock/wallet_mock_interceptor.dart
    │           └── presentation/{providers/wallet_provider,screens/{movements,send_money}_screen}.dart
    │
    ├── fa_credit/                      ← MÓDULO: CRÉDITO (solicitud + cuenta)
    │   └── lib/
    │       ├── fa_credit.dart
    │       ├── credit_module.dart
    │       └── src/
    │           ├── domain/entities/{credit_account,credit_product,credit_application}.dart
    │           ├── domain/ports/i_credit_repository.dart
    │           ├── application/use_cases/{get_credit,make_payment,dispose_credit,list_products,submit_application,get_application}_use_case.dart
    │           ├── infrastructure/adapters/credit_repository_impl.dart
    │           ├── infrastructure/dtos/{credit_account,credit_product,credit_application}_dto.dart
    │           ├── infrastructure/mock/credit_mock_interceptor.dart
    │           └── presentation/{providers/{credit_provider,credit_application_provider},screens/{credit_detail,product_selection,application_amount,application_status}_screen}.dart
    │
    ├── fa_notifications/               ← MÓDULO: NOTIFICACIONES
    │   └── lib/
    │       ├── fa_notifications.dart
    │       ├── notifications_module.dart
    │       └── src/ (estructura análoga a los demás)
    │
    ├── fa_profile/                     ← MÓDULO: PERFIL DE USUARIO
    │   └── lib/
    │       ├── fa_profile.dart
    │       ├── profile_module.dart
    │       └── src/ (estructura análoga a los demás)
    │
    └── fa_shell/                       ← APP ENSAMBLADORA
        └── lib/
            ├── main.dart               ← entry point Mock
            ├── main_qa.dart            ← entry point QA
            ├── main_prod.dart          ← entry point Producción
            └── src/
                ├── di/
                │   └── shell_injection.dart   ← composición de módulos
                ├── home/
                │   └── home_screen.dart       ← pantalla principal
                ├── network/
                │   └── dio_api_client.dart    ← implementación de ApiClient
                └── router/
                    └── shell_router.dart      ← buildRouter(modules)
```

---

## Solución de Problemas Comunes

### "No devices found"

```bash
# Asegúrate de que el simulador esté booteado:
xcrun simctl boot <UDID>
open -a Simulator

# Verifica que Flutter lo ve:
flutter devices
```

### "Pod install failed"

```bash
cd packages/fa_shell
flutter clean
cd ios && pod install --repo-update
cd ..
flutter run
```

### "pubspec_overrides.yaml out of sync"

```bash
# Desde la raíz del repo:
melos bootstrap
```

### "Unhandled Exception: objective_c.dylib"

Este error es cosmético en modo debug con el simulador de iOS. La app funciona normalmente. Es un warning conocido de `image_picker` con native assets en simuladores. No ocurre en builds de release ni en dispositivo físico.

### Rebuild completo desde cero

```bash
cd packages/fa_shell
flutter clean
cd ios && rm -rf Pods Podfile.lock && pod install && cd ..
flutter pub get
flutter run
```
