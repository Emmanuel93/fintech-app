# Colocación B2B2C — estado de la conexión real

**Fecha:** 2026-08-18 (segunda revisión)
**Estado:** la app corre **conectada de punta a punta**, sin mocks. Verificado con
`integration_test/placement_connected_e2e_test.dart` en simulador y con el flujo
completo por curl a través del gateway.

Este documento reemplaza a `KREDIUS_COLOCACION_API.md` como fuente de verdad del
*estado*: aquél describe el contrato, éste dice qué parte de ese contrato ya
está viva y qué falta construir.

---

## 1. La ruta, de punta a punta

```
app (flavor local)
  → gateway :8090  (valida el JWT RS256, inyecta X-User-Id)
    → channel-mobile-service   (BFF — la única puerta)
      → beneficiary-service    (el agregado Colocación)
        ├→ credit-portfolio    línea autorizada, disponible, calendario
        ├→ credit-product      límites por beneficiario
        ├→ scoring             reporte de buró (con mock de Círculo)
        ├→ wallet              disposición THIRD_PARTY_CREDIT
        ├→ origination         prospecto y expediente de la beneficiaria
        └→ party               su Party y la relación con el distribuidor
```

**Lo único simulado son los servicios externos**, y viven dentro de los
servicios donde corresponde: el buró (`MockCirculoAdapter` en scoring) y el SPEI
(stub de stp). El resto es real, incluida la contabilidad de la línea.

---

## 2. Qué quedó conectado

| Endpoint del BFF | Resuelve | Estado |
|---|---|---|
| `GET /distributor/line-summary` | credit-portfolio + colocaciones vivas | ✅ |
| `POST /placements` | cotiza contra la tasa de la línea y crea la colocación | ✅ |
| `GET /placements` · `/{id}` | agregado + métricas del calendario | ✅ |
| `GET /placements/{id}/bureau` | scoring → cinco renglones y banda | ✅ |
| `POST /placements/{id}/approve` | wallet → disposición → desembolso | ✅ |
| `POST /placements/{id}/reject` · `/resend` · `/cancel` | agregado | ✅ |
| `GET /beneficiaries` | directorio agrupado por persona | ✅ |
| `POST /internal/test-support/…/complete-kyc` | **sustituye la web de la beneficiaria** | ⚠️ sólo local |

El gateway no necesitó rutas nuevas: su bloque `location /` ya enruta al BFF
todo lo que trae JWT válido.

### Corrida real verificada

```
crear      → invited      $12,000 · 12 quincenas · pago $1,046.55 (tasa real de la línea)
KYC        → bureauReady  prospecto + Party + relación creados de verdad
buró       → score 768 · RIESGO BAJO · 5 renglones
aprobar    → approved     wallet acepta (202)
desembolso → active       vía `credit-portfolio.disposition-completed`
línea      → 315,000 → 273,000 (dos colocaciones descontadas)
```

---

## 3. Lo que se arregló para que funcionara

Tres defectos reales, ninguno introducido por este trabajo:

1. **scoring-service no devolvía ningún reporte de buró** (500 en todas las
   llamadas). `CirculoReportQueryService` inicializaba las colecciones con
   `Hibernate.initialize(r.getCredits())`, pero el getter devuelve
   `Collections.unmodifiableList(...)` — un envoltorio, no la colección
   persistente. `Hibernate.initialize` sobre eso no hace nada, así que la carga
   parecía resuelta y el fallo aparecía después, fuera de la sesión, al mapear
   a DTO. Ahora se recorre el tamaño, que sí toca la colección de abajo.
2. **`markDisbursing` publicaba un evento genérico** y el propio guardia del
   dominio lo rechazaba: DISBURSING lleva el `dispositionId` y necesita evento
   propio. Se agregó `PlacementDisbursingEvent`.
3. **El módulo de colocación desaparecía al hacer login.** Se activaba con
   `AppSession.purpose`, que vive en memoria y se pierde al cerrar la app: un
   distribuidor que volvía a entrar no veía ni su línea ni sus pestañas. Ahora
   manda el backend — `line-summary` con `authorized: 0` es la única señal que
   sobrevive a un login.

Y dos ajustes de contrato: el `channelType` de la beneficiaria (`WHATSAPP`, que
es por donde le llega la liga) y el estado `failed`, que el backend emite y la
app no conocía — su fallback lo mandaba a `invited`, dejando una colocación
muerta pintada como «liga enviada».

---

## 4. Lo que falta para cerrar el dominio

Ordenado por lo que más duele en producción.

### 4.1 La web pública de KYC de la beneficiaria — **el hueco grande**

Es la pieza que el diseño describe en `KYC Beneficiario.dc.html`: 7 pasos que
ella recorre desde su teléfono. **No existe**, ni el frontend ni la API pública
que lo sirva (`/api/v1/beneficiary/public/**`, fase 3 del plan del servicio).

Hoy la sustituye `POST /internal/test-support/…/complete-kyc`, que hace lo real
—prospecto, Party, relación, consentimiento— pero **desde el servidor y sin
ella**. Es un bypass de identidad: está detrás de `kyc-simulation-enabled` y
apagado por defecto.

Falta construir:
- La API pública por token de liga: OTP a su celular, OCR de INE, prueba de
  vida, datos, consentimientos con IP y hora, y su CLABE.
- `PlacementInvite`: token, hash, vigencia de 7 días, reenvío que revoca la
  anterior, y el barrido de vencidas.
- El frontend web responsive.

Mientras no exista, **ninguna colocación puede avanzar sola**: la beneficiaria
no tiene por dónde verificarse.

### 4.2 Notificaciones

La liga se "manda" sólo en el log. Faltan los cinco `EventType` nuevos en
notifications-service con sus plantillas de WhatsApp: liga enviada, recordatorio,
liga por vencer, KYC completado y depósito realizado. El evento
`beneficiary.placement-invited` ya se publica; nadie lo consume.

### 4.3 La bonificación real (commission-service)

Hoy `commissionAccrued` se calcula en beneficiary-service con la regla simple
(20 % si no hay atraso, 0 si lo hay). **La escalera completa —17, 14, 10, 6, 0
por día— no está implementada en ningún lado.** El plan la ubica en
commission-service con `DISTRIBUTOR_PUNCTUALITY_SHARE` y `commission_policy_tiers`
(fase 7). Mientras tanto la cifra es correcta en los extremos y aproximada en el
medio.

### 4.4 Correlación exacta de la disposición

`markDisbursing` guarda el `placementId` como `dispositionId` provisional porque
wallet responde 202 sin cuerpo. El listener de `disposition-completed` desempata
por cuenta y monto, lo que **puede confundirse si dos colocaciones idénticas
salen el mismo día**. El arreglo correcto es que wallet devuelva el
`dispositionId` en la respuesta de la disposición.

### 4.5 Menores

| Qué | Detalle |
|---|---|
| Límites desde el catálogo | El tope por beneficiario sale de configuración; el plan lo quiere de `credit-product` (`DL-DIST-STD-V1`). |
| `GET /beneficiaries/{id}` | La ficha individual no existe: «Su contrato» y «Sus pagos» están dibujados y desactivados en la app. |
| Detalle de colocación activa | Sólo las que esperan decisión tienen pantalla propia. |
| Reenvío de liga | El endpoint valida y responde, pero no manda nada (depende de 4.2). |
| Barrido de vencidas | Nadie expira las ligas de 7 días todavía. |
| `PlacementInvite` | El token no existe como entidad; la ventana vive en la colocación. |

---

## 5. Cómo correrlo

```bash
# Backend
cd fintech-services && docker compose up -d
#   si el BFF o un servicio se recrea, el gateway cachea su IP vieja:
docker compose restart gateway-service

# App conectada
cd fintech-app/packages/fa_shell
flutter run -t lib/main_local.dart          # apunta a mobile.localhost:8090

# E2E conectado
flutter test integration_test/placement_connected_e2e_test.dart -d <device>
```

**Distribuidora de prueba:** `5578449614` / `Kredius#Cliente2026` — línea
`DL-DIST-STD-V1` de $500,000 activa. Hay tres más sembradas
(`scripts/seed-distribuidoras.py`).


---

## 6. Segunda revisión (2026-08-18) — el backoffice

Se revisó lo que se construyó desde la primera pasada. **Lo nuevo es la mesa de KYC del
backoffice**, no la web pública de la beneficiaria: ésa sigue sin existir (§4.1 vive tal cual).

### Lo que había

| Pieza | Dónde |
|---|---|
| `BackofficePlacementController` | bandeja que cruza todas las distribuidoras, con filtros por estado, identidad y SLA |
| `IdentityStatus` | derivado de `PlacementStatus` — **validamos identidad, no riesgo**; el score nunca bloquea |
| `PlacementQueryRepository` | consulta paginada con los filtros |
| `BeneficiariesController` / `DistributorsController` | los mismos datos, republicados por `channel-backoffice-service` |

### Cuatro cosas que faltaban para que estuviera conectado

1. **El backoffice no sabía dónde vivía `beneficiary-service`.** Su `application.yml` declara
   `beneficiary-service-url`, pero el compose no le pasaba la variable: dentro del contenedor
   caía al default de `bootRun` (`localhost:8102`), que es el propio backoffice. La bandeja
   respondía 404 sin decir por qué.
2. **`beneficiaries.view` no estaba sembrada para ningún rol.** La ruta ya estaba protegida por
   esa capacidad, así que la bandeja daba **403 a todo el mundo, incluido ADMIN**. Una ruta
   protegida por una capacidad que nadie tiene no está protegida: está rota. Migración
   `identity:015`, con la matriz de respaldo del backoffice que ya la traía.
3. **Los nombres de las distribuidoras salían en `null`.** Se resolvían con `/batch?by=partyId`,
   pero el `distributorPartyId` que guarda la colocación es el **prospectId** —el `sub` del JWT—
   y party-service guarda su Party con un id propio distinto. Ahora se pide `by=prospectId`.
   Los tres tests que fijaban el comportamiento anterior estaban fijando el error y se
   corrigieron.
4. **Carrera en el desembolso.** El listener de `disposition-completed` sólo aceptaba
   colocaciones en `DISBURSING`, pero credit-portfolio puede completar la disposición **antes**
   de que el agregado registre que la pidió: la colocación quedaba desembolsada de verdad y
   pintada «DEPOSITANDO» para siempre. Ahora acepta también `APPROVED` y registra las dos
   transiciones.

Y uno del alta B2C, que salió al arreglar la sonda de los E2E: **el stub de OCR del BFF devolvía
siempre la misma CURP**, así que la segunda persona que se diera de alta en el ambiente chocaba
con `DUPLICATE_PROSPECT`. Ahora la deriva de la imagen de la credencial, que es lo que hace un OCR
real: dos INE distintas, dos personas distintas.

### Verificación

| Suite | Resultado |
|---|---|
| Backend completo (`cleanTest test`, 24 servicios) | **1446 tests, 0 fallos** |
| App — analyze | limpio en los **10 paquetes** |
| App — unitarios | **176** (79 shell · 50 credit · 27 placements · 17 DS · 3 auth) |
| `placement_connected_e2e_test` (app real contra servicios reales) | ✅ |
| `create_account_e2e_test` (mock) | 11/12 — ver abajo |
| Ciclo completo por curl | crear → KYC → buró (score 787) → aprobar → **active**, línea $315,000 → $288,000 |
| Bandeja de backoffice | 2 colocaciones, identidad `VERIFIED`, distribuidora resuelta |

### La originación conectada — ✅ arreglada (2026-08-18)

TC-CA10 llevaba tiempo saltándose porque la sonda apuntaba a `localhost:8085`, el puerto que el
BFF dejó de publicar cuando entró el gateway. Al corregirla salieron **dos defectos reales**, uno
detrás del otro:

1. **El stub de OCR devolvía una CURP que el propio BFF rechaza.** Al hacerla única por
   credencial se metió un dígito entre las cinco letras que van tras la H, y el patrón de
   `/kyc/submit` es `[A-Z]{4}\d{6}[HM][A-Z]{5}[A-Z0-9]\d`. El alta moría con un 400 que en
   pantalla se veía como «Intentar de nuevo», sin decir que el problema era la CURP. Ahora sólo
   varían las dos últimas posiciones, que es donde el registro civil pone el desempate.
2. **El primer login de la vida del usuario no reintentaba.** `/auth/register` deja la cuenta
   creada, pero la credencial con la que se entra la crea identity al consumir el evento: entre
   una cosa y otra hay un instante en que la cuenta existe y no se puede usar. Un solo intento
   caía justo ahí y devolvía 401, dejando el alta terminada pero sin sesión. Ahora reintenta con
   espera creciente y tope.

Y dos más que salieron al reverificar la colocación:

3. **Carrera en el desembolso.** La aprobación por HTTP y el listener de Kafka movían la misma
   colocación a `DISBURSING` a la vez y una perdía el lock optimista — la colocación quedaba
   desembolsada de verdad y pintada «depositando». El listener reintenta una vez: en la segunda
   pasada encuentra el estado que escribió la otra y sólo cierra el desembolso.
4. **La relación distribuidor→beneficiaria daba 404.** Se pedía sobre el `prospectId` y
   party-service la indexa por su `partyId` propio. Es el mismo trasfondo que el `distributorName`
   nulo del backoffice.

**Verificado contra la base:** el alta deja prospecto `CAPTURED`, credencial `ACTIVE` y Party
ligado; el ciclo de colocación cierra en `DISBURSED` con su disposición, sin warnings.

#### Cómo se veía antes (queda como registro del diagnóstico)

Es el alta B2C contra el backend real. Llevaba tiempo saltándose porque la sonda apuntaba a
`localhost:8085`, el puerto que el BFF dejó de publicar cuando entró el gateway; al corregirla el
caso corre y falla.

Lo que se sabe, leyendo el log del BFF durante una corrida completa: llegan **exactamente seis
líneas**, todas de OTP —`otp/send` y `otp/verify`, dos veces— y **nada más**. No hay
`/ocr/extract`, no hay `/kyc/submit`, no hay `/auth/register`. La app sí avanza en pantalla (se
la ve capturando documentos y llenando «Verifica tus datos»), así que **el alta no está
fallando en el backend: no llega a llamarlo.** La pantalla de análisis termina en «Intentar de
nuevo», que es su estado de error, sin que haya salido una sola petición de registro.

Eso descarta las dos hipótesis anteriores —CURP duplicada y datos de prueba— y mueve el
problema al lado del cliente, en el tramo documentos → análisis del flavor `local`. **Bloquea
cualquier video E2E conectado**, porque la originación es la primera pata de los cuatro
recorridos.
