# Integration Tracker — Kredius (app ↔ BFF ↔ backend)

**Última actualización:** 2026-08-08
**Alcance:** estado real, verificado, de la conexión end-to-end entre `fintech-app` (Flutter) y `fintech-services` (Spring Boot) — incluye el journey crediticio completo para los tres segmentos de negocio (B2C / B2B / B2B2C).

## Resumen ejecutivo

El journey crediticio conecta de punta a punta — onboarding → solicitud → scoring → oferta → contrato → firma → cuenta activa → wallet fondeado → disposición/pago/transferencia → movimientos → notificaciones — para los tres segmentos, con datos reales persistidos en cada base de datos (no hardcodeados) y verificado con traces distribuidos. El único dato simulado en toda la cadena es el reporte del buró de crédito (ver [Simulado vs. real](#simulado-vs-real)).

---

## Arquitectura

```
Flutter app (flavor local/qa/prod)
   │  http://mobile.localhost:8080   (NO se habla directo con ningún backend service)
   ▼
gateway-service (OpenResty :8080) — valida JWT RS256, inyecta X-User-Id (=sub=prospectId) + X-Roles
   ▼
channel-mobile-service :8085 (BFF — único agregador del canal móvil)
   ├── identity-service         (auth)
   ├── origination-service      (prospecto, solicitudes, oferta, contrato)
   ├── party-service            (datos del cliente)
   ├── credit-product-service   (catálogo)
   ├── credit-portfolio-service (cuentas activas, saldos, CLABE)
   ├── scoring-service          (motor de decisión de crédito)
   ├── wallet-service           (saldo, disposiciones, pagos, retiros, movimientos)
   └── notifications-service    (bandeja de notificaciones)
```

**Regla dura:** la app nunca llama a un backend service directo — siempre gateway → BFF. El BFF orquesta síncrono (WebClient) o dispara eventos Kafka que los servicios de dominio consumen entre sí (p. ej. firmar contrato → activar cuenta → crear wallet, todo async).

## Leyenda
✅ Conectado y verificado end-to-end · 🟡 Conectado, con gap conocido · 🔴 Bloqueado · ⚠️ Dato simulado

---

## Tabla maestra — pantalla por pantalla

| Módulo app | Pantalla / uso | Endpoint | Estado |
|---|---|---|---|
| fa_auth | Login / logout | `POST /auth/login`, `/auth/logout` | ✅ |
| fa_onboarding | Alta de prospecto | `POST /otp/*`, `/ocr/extract`, `/kyc/submit`, `/auth/register` | ✅ |
| fa_credit | Catálogo de productos | `GET /credit/products` | ✅ |
| fa_credit | Solicitud de crédito + polling | `POST/GET /credit/applications[/{id}]` | ✅ |
| fa_credit | **Oferta** (nueva pantalla) | `POST /credit/applications/{id}/offer[/accept\|/reject]` | ✅ |
| fa_credit | **Contrato / firma** (nueva pantalla) | `POST /credit/applications/{id}/contract[/sign]` | ✅ |
| fa_credit | Home: cuenta / saldo (tarjeta adaptativa) | `GET /credit/account` | ✅ |
| fa_credit | Pago de crédito | `POST /credit/payment` | ✅ |
| fa_credit | Disposición de línea (solo revolventes) | `POST /credit/dispose` | ✅ |
| fa_wallet | Saldo / CLABE | `GET /wallet/balance` | ✅ |
| fa_wallet | Movimientos (historial) | `GET /wallet/transactions` | ✅ |
| fa_wallet | Transferencia SPEI | `POST /wallet/transfer` | ✅ |
| fa_profile | Perfil del usuario | `GET /users/me` | ✅ |
| fa_notifications | Lista / marcar leído | `GET /notifications`, `PUT .../read[-all]` | ✅ persiste (`read_at` en notifications-service) |

---

## Journey crediticio E2E — los tres segmentos

Ciclo completo de una solicitud: `PENDING_SCORING → SCORING → APPROVED | COMMITTEE_REVIEW/UNDER_MANUAL_REVIEW → OFFER_PRESENTED → OFFER_ACCEPTED → PENDING_SIGNATURE → CONTRACT_SIGNED → DISBURSED`.

### B2C (INDIVIDUAL) — 100% desde la app, automático
Onboarding (OTP+OCR+KYC) → login → elegir producto (p. ej. Línea Revolvente Personal) → scoring auto-aprueba → la app presenta la oferta automáticamente → el usuario acepta → firma (CLABE + aceptar términos) → **el backend activa la cuenta y crea el wallet solo, vía Kafka** → home muestra crédito real + wallet fondeado → disponer / pagar / transferir / ver movimientos / notificaciones.

Verificado con datos reales (usuario TERESA, `5510026001`): línea $10,000, disposición $4,000 → saldo wallet $4,000 (correcto tras el fix del bug, ver abajo) → transferencia $1,500 y pago $500 → saldo final $2,500 → 3 movimientos reales en el ledger.

### B2B (BUSINESS) — a comité
El alta es por canal ops/partner (no por la app móvil — la app es el canal B2C). Prospecto `BUSINESS` + producto `SME_LOAN` → scoring enruta a `COMMITTEE_REVIEW` → un underwriter aprueba (`POST /api/v1/origination/underwriting/applications/{id}/decision`, red interna, no expuesto en el gateway móvil) → oferta → firma → cuenta `INSTALLMENT` activa.

Verificado: cuenta SME_LOAN, `INSTALLMENT`, principal $800,000, `ACTIVE`.

### B2B2C (DISTRIBUTOR) — a comité + disposición a tercero
Prospecto `DISTRIBUTOR` + producto `DISTRIBUTOR_LINE` → comité → aprueba → firma → cuenta `REVOLVING` activa. La disposición usa `dispositionType=THIRD_PARTY_CREDIT` + `beneficiaryPartyId` (el crédito fluye a un tercero, no al obligor).

Verificado: cuenta DISTRIBUTOR_LINE, `REVOLVING`, línea $500,000, disposición THIRD_PARTY → `HTTP 202`.

---

## Qué se conectó / arregló (cronología)

### Sesión 1 — Wallet, notificaciones, pagos (2026-07-25)
Se conectaron al BFF los módulos que hasta entonces mockeaba la app: `wallet-service` y `notifications-service` (ambos ya estaban implementados en el backend, no eran stubs). Nuevos: `WalletClient`/`WalletController`/`NotificationsClient`/`NotificationController` en el BFF; `/credit/payment` y `/credit/dispose` extendidos para llamar a wallet-service (que orquesta el resto vía Kafka, sin que el BFF hable con `payments` directo).

### Sesión 2 — Journey multi-segmento E2E (2026-07-26/27)
Se descubrió que el journey no podía completarse: el scoring nunca terminaba (buró sandbox externo rechaza CURPs sintéticos + race condition en el re-intento) y faltaba todo el tramo oferta→contrato→firma (sin eso nunca se crea la cuenta ni el wallet). Trabajo:

- **scoring-service**: `MockCirculoAdapter` (perfil dev/local, flag `SCORING_CIRCULO_MOCK_ENABLED`, reporte determinista por CURP) + fix de reintento acotado en `ScoreRequestedEventListener` (antes: si el prefetch del buró no había terminado, la solicitud se quedaba pegada para siempre) + 3 políticas de scoring nuevas (antes solo existía una, para `PERSONAL_LOAN`): `INDIVIDUAL/REVOLVING_LINE` (auto-aprueba), `BUSINESS/SME_LOAN` y `DISTRIBUTOR/DISTRIBUTOR_LINE` (ambas a comité) — mismas reglas/motor que la política original, solo cambia la banda de decisión.
- **origination-service**: `ProductType` +`SME_LOAN` +`BUSINESS_REVOLVING_LINE`, `ProspectType` +`DISTRIBUTOR` (antes solo `INDIVIDUAL`/`BUSINESS`) + migración de los `CHECK` constraints correspondientes — el catálogo ya tenía productos B2B/B2B2C que origination no podía aceptar.
- **BFF**: endpoints nuevos `/credit/applications/{id}/offer[/accept|/reject]` y `/contract[/sign]` (el BFF resuelve el `productCode` del catálogo a partir del `productType` de la solicitud); `/wallet/transactions` pasó de devolver `[]` siempre a devolver el ledger real; `/credit/dispose` acepta `dispositionType`/`beneficiaryPartyId` (para B2B2C); fix de fecha del stub de OCR (`DD/MM/YYYY` → ISO, rompía el registro en origination).
- **wallet-service**: **bug real corregido** — al disponer crédito, `walletBalance` se logueaba como acreditado pero no persistía (lost-update por una condición de carrera entre dos listeners de Kafka concurrentes sobre el mismo registro). Fix con updates atómicos (`@Modifying`) que nunca se pisan entre sí. Nuevo **ledger de movimientos** (`wallet_movements`: disposición/retiro/pago) + endpoint `GET /api/v1/wallet/{creditAccountId}/movements`.
- **App (fa_credit)**: pantallas nuevas de **Oferta** y **Contrato/Firma**; el polling ya no se detiene en "aprobado" sino que avanza por todo el ciclo; **tarjeta de crédito adaptativa** (revolvente vs. a plazo, título por tipo de producto) — antes asumía "Revolvente" siempre y ocultaba cualquier cuenta sin `creditLimit` (es decir, ocultaba todos los créditos a plazo).
- **App (fa_wallet)**: acción "Disponer" ya cableada (gated a productos revolventes); movimientos reales.

### Sesión 3 — Fixes de perfil y CLABE (2026-07-27)
Al correr la app en simulador con un usuario con journey completo aparecieron dos gaps reales:

- **Perfil `/users/me` daba 404**: el `sub` del JWT es el `prospectId`, pero `party-service` genera su propio `partyId` (distinto) ligado a ese `prospectId`. El BFF buscaba por `partyId` → nunca encontraba nada. Fix: `PartyClient.getByProspectId` usa el endpoint `GET /api/v1/parties/by-prospect/{prospectId}` (ya existía en party-service, solo faltaba usarlo) + el `UserController` del BFF ahora **mapea** la respuesta al shape que espera la app (`fullName`, `kycStatus`, `memberSince` — antes mandaba el objeto crudo de party y la app no encontraba esos campos).
- **CLABE siempre `null`**: la CLABE que el cliente registra al firmar vive en `credit_portfolio.credit_accounts.clabe_account` pero la API de portfolio no la exponía. Fix: se agregó al `CreditAccountResponse` de portfolio y al `WalletBalanceResponse` del BFF; en la app, `WalletBalance` gana el campo `clabe` y la tarjeta del wallet la muestra.

### Sesión 4 — Estado de lectura de notificaciones (2026-08-08)
`PUT /notifications/{id}/read` y `/read-all` eran no-op (el BFF respondía `success:true` sin persistir nada — notifications-service no tenía dónde guardar "leído"). Fix:

- **notifications-service**: columna `read_at TIMESTAMPTZ` (NULL = no leída) en `notification_records`; `NotificationRecord.markRead()` (idempotente); nuevo `ManageNotificationReadStateUseCase` (`markAsRead` por id, `markAllAsRead` por destinatario vía `UPDATE ... WHERE read_at IS NULL` atómico — no carga N filas a memoria); endpoints `PUT /api/v1/notifications/{notificationId}/read` y `PUT /api/v1/notifications/read-all/{recipientId}`; `NotificationRecordResponse` ahora incluye `isRead`.
- **BFF**: `NotificationsClient.markAsRead/markAllAsRead` llaman de verdad a notifications-service; `GET /notifications` mapea `isRead` real (antes hardcodeado a `false`).
- Verificado con curl + confirmación directa en Postgres: marcar una notificación individual no afecta a las demás; "marcar todas" persiste el mismo `read_at` (mismo UPDATE atómico) en todas las que seguían sin leer.

---

## Verificación realizada

- **curl E2E completo** (vía `http://mobile.localhost:8080`, JWT real) para los tres segmentos: B2C (REVOLVING_LINE y PERSONAL_LOAN), B2B (SME_LOAN vía comité), B2B2C (DISTRIBUTOR_LINE vía comité + disposición THIRD_PARTY). Sin sembrar ningún dato a mano.
- **`flutter analyze`** limpio en `fa_credit`, `fa_wallet`, `fa_shell` tras todos los cambios de app.
- **App corrida en simulador iOS** (iPhone 16 Pro, flavor `local`): capturas reales de home (perfil, saldo, CLABE, cuenta, notificaciones), pantalla de perfil, y detalle de crédito (saldo pendiente, pago mínimo, fechas).
- **Traces distribuidos verificados en Tempo**: una request real de `GET /credit/account` se rastreó cruzando `api-gateway → channel-mobile-service (BFF) → credit-portfolio-service → SELECT credit_portfolio.credit_accounts`, todo bajo el mismo `traceID` — confirma que no hay atajos, la request atraviesa toda la cadena.
- **Verificación de que los datos no son hardcodeados**: correlación de IDs entre tablas — `credit_portfolio.credit_accounts.contract_id` = `origination.credit_applications.application_id`, mismo `contract_number`, `activated_at` ~0.46s después de `contract_signed_at` (el tiempo real de un round-trip de Kafka). Prueba que la cuenta la creó el evento, no un INSERT manual.

## Simulado vs. real

El **único** dato sintético en toda la cadena es el **reporte del buró de crédito** (`scoring.circulo_reports`, `fico_score_razones='MOCK-CLEAN'`), vía `MockCirculoAdapter` — el sandbox real de Círculo de Crédito rechaza CURPs de prueba, así que se sustituyó por un adaptador determinista (flag `fintech.circulo.mock-enabled` / env `SCORING_CIRCULO_MOCK_ENABLED`, **solo dev/local, nunca debe activarse en prod**). A partir de ese único insumo, **todo corre con el motor y las tablas reales**: el cálculo del score (suma real de reglas `MORA_CHECK`/`FICO_THRESHOLD`/`CREDIT_COUNT`/`INQUIRY_COUNT`), la decisión, la oferta, el contrato, la activación de cuenta, el saldo del wallet y los movimientos.

La política de scoring para `REVOLVING_LINE` (B2C) y las de `SME_LOAN`/`DISTRIBUTOR_LINE` (B2B/B2B2C) no existían antes de este trabajo — se crearon porque sin ellas el motor nunca puede decidir nada (la solicitud queda pegada en `PENDING_SCORING`). Usan el mismo motor y tipos de regla que la política original de `PERSONAL_LOAN`, no un atajo para forzar aprobación.

---

## Gaps conocidos (pendientes)

| Gap | Detalle | Bloqueante |
|---|---|---|
| Sesión no persiste | `refreshToken` se captura y nunca se usa; no hay interceptor 401→refresh; requiere agregar `flutter_secure_storage` (no está en el proyecto hoy) | No — la sesión funciona dentro de una corrida (JWT expira a los 900s) |
| Notificaciones "duplicadas" | No es bug: `NotificationRecord` guarda un registro por (evento, canal) — un evento enviado por WhatsApp *y* Email genera 2 filas a propósito (ver `NotificationRecord`, comentario de dominio) | No |
| OCR no sube la imagen real | `fa_onboarding` solo manda el `fileName`, no los bytes de `DocumentFile` — bloqueante solo si se integra un OCR real (hoy es un stub) | No |
| Ledger de movimientos con 3 tipos | `wallet_movements` cubre disposición/retiro/pago; no incluye, p. ej., ajustes manuales u otros orígenes de movimiento | No |

---

## Cómo correr todo

**Backend** (`fintech-services`):
```bash
docker compose up -d   # trae todo el stack (postgres, kafka, gateway, todos los servicios)
```
`./gradlew` no corre en macOS con BSD `readlink` (sin `-e`). Usar en su lugar:
```bash
java -cp gradle/wrapper/gradle-wrapper.jar org.gradle.wrapper.GradleWrapperMain :<servicio>:<task> --console=plain
```
Al reconstruir/recrear el BFF (`channel-mobile-service`), el gateway puede cachear la IP vieja del contenedor → `502`. Solución: `docker compose restart gateway-service`.

**App** (`fintech-app`):
```bash
cd packages/fa_shell
flutter run -t lib/main_local.dart -d <simulator-id>   # OJO: correr desde aquí, no desde la raíz del repo
```
El flavor `local` apunta al gateway (`http://mobile.localhost:8080`), nunca directo al BFF.

**Usuario de prueba con journey completo** (B2C, REVOLVING_LINE activa, wallet fondeado): `5510026001` / `Test1234!`.

---

## Referencias rápidas

| Servicio | Puerto local (fuera de Docker) | Contenedor Docker |
|---|---|---|
| gateway-service | 8080 (host) | `gateway-service:80` |
| channel-mobile-service (BFF) | 8085 | `channel-mobile-service:8080` |
| identity-service | 8080 | `identity-service:8080` |
| party-service | 8083 | `party-service:8080` |
| origination-service | 8081 | `origination-service:8080` |
| credit-product-service | 8084 | `credit-product-service:8080` |
| credit-portfolio-service | 8087 | `credit-portfolio-service:8080` |
| scoring-service | — | `scoring-service:8080` |
| wallet-service | 8092 | `wallet-service:8080` |
| notifications-service | 8098 | `notifications-service:8080` |

> Nota histórica: las carpetas/servicios `wallet`, `notifications` y `payments` se renombraron a `wallet-service`, `notifications-service` y `payments-service` durante este trabajo — si algo referencia los nombres viejos, están desactualizados.
