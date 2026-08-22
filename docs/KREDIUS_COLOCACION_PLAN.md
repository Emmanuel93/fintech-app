# Kredius — Plan de la 7ª pasada: colocación y beneficiarios

**Fecha:** 2026-08-16
**Estado:** ✅ **Fases A–D implementadas**. `flutter analyze` limpio en los 10
paquetes y 176 tests unitarios en verde. Los servicios quedan **mockeados**
contra el contrato de `docs/KREDIUS_COLOCACION_API.md`.
**Autor:** revisión como Sr. Frontend (Flutter) del bundle de diseño (hoy en `docs/design/`).

> El contrato de API que el backend debe cumplir vive aparte, en
> [`KREDIUS_COLOCACION_API.md`](KREDIUS_COLOCACION_API.md): no es una propuesta,
> es lo que la app ya consume.

---

## 1. Qué cambió en el bundle de diseño

El handoff se volvió a exportar y **ya no es el mismo archivo** que sustentó
`KREDIUS_JOURNEY_PLAN.md`. Es el cambio más grande desde la primera pasada.

| | Bundle anterior | Bundle actual |
|---|---|---|
| Archivo primario | `Kredius Journey.dc.html` (1 193 líneas, 134 KB) | **`Kredius Journey App.dc.html`** (2 457 líneas, 193 KB) |
| Pantallas en el riel | 16 | **30** |
| Piezas web | Landing, Backoffice | Landing, Backoffice **+ `KYC Beneficiario.dc.html`** (nueva) |

El archivo viejo sigue en `project/design_handoff_kredius/design/` — es histórico.
**La fuente de verdad ahora es `project/Kredius Journey App.dc.html`**, y todas las
referencias de línea de este documento apuntan a ese archivo.

Lo nuevo se concentra en un solo tema: **el journey B2B2C del distribuidor**
(pantallas 17–25 y dos pestañas de home), más una **aplicación web aparte** para
que el beneficiario haga su propio KYC.

---

## 2. Auditoría: las 30 pantallas del riel contra la app

`✅` existe y es fiel · `🟡` existe pero no coincide · `❌` no existe

| # | Riel (`STEPS()` L1570-1583) | Pantalla | Destino en la app | Hoy |
|---|---|---|---|---|
| 1 | Alta · bienvenida | s0 | `fa_onboarding/welcome_screen.dart` | ✅ |
| 2 | Alta · tu celular | s1 | `phone_entry_screen.dart` | ✅ |
| 3 | Alta · aviso y autorización | s2 | `privacy_notice` + `privacy_consent` | ✅ |
| 4 | Alta · código SMS | s3 | `otp_screen.dart` | ✅ |
| 5 | **Alta · tipo de perfil** | s17 L982 | `purpose_screen.dart` | 🟡 faltan las viñetas por opción y el aviso ámbar |
| 6 | Alta · documentos y datos | s4 | `identity_screen.dart` | ✅ |
| 7 | Alta · análisis de riesgo | s5 | `account_analysis_screen.dart` | ✅ |
| 8 | Alta · aprobado | s6 | `post_analysis_screen.dart` | ✅ |
| 9 | Alta · rechazado | s15 | `rejected_screen.dart` | ✅ |
| 10 | Alta · contraoferta | s14 | `counter_offer_screen.dart` | ✅ |
| 11 | Inicio · solo ofertas | s13/t0 | `credit_module.buildHomeCard` | ✅ |
| 12 | Contratar · oportunidades | s7 | `product_selection_screen.dart` | ✅ |
| 13 | Contratar · cómo funciona | s8 | fusionada en `offer_screen.dart` | 🟡 decisión documentada §14.5 |
| 14 | Contratar · monto y plazo | s9 | `application_amount_screen.dart` | ✅ |
| 15 | Contratar · resumen | s10 | `contract_sign` + `contract_review` | ✅ |
| 16 | Contratar · firma | s11 | `contract_otp_screen.dart` | ✅ |
| 17 | Contratar · desembolso | s12 | `disbursement_success_screen.dart` | ✅ |
| 18 | **Inicio · solo línea de distribuidor** | s13/t0/h3 L703-734 | `fa_shell` + `fa_credit` | ❌ tarjeta "MI LÍNEA DE DISTRIBUIDOR" |
| 19 | Inicio · sin línea, uso propio | s13/t0/h4 | — | 🟡 |
| 20 | Inicio · un crédito | s13/t0/h1 | `DsActiveCreditCard` | ✅ |
| 21 | Inicio · varios créditos | s13/t0/h2 | carrusel + dots | ✅ |
| 22 | **Movimientos** | s13/t1 L840-871 | `fa_wallet/movements_screen.dart` | 🟡 existe la pantalla, **ya no es pestaña** (la 4ª pasada la sacó) |
| 23 | **Enviar préstamo · a quién** | s18 L1029 | — | ❌ |
| 24 | **Enviar préstamo · monto y plazo** | s22 L1275 | — | ❌ |
| 25 | **Enviar préstamo · liga enviada** | s23 L1342 | — | ❌ |
| 26 | **Enviar préstamo · su historial y tu decisión** | s25 L1211 | — | ❌ |
| 27 | **Colocaciones** | s13/t2 L804-837 | — | ❌ |
| 28 | **Beneficiarios** | s13/t3 L873-932 | — | ❌ |
| 29 | Perfil y contratos | s13/t4 | `fa_profile/profile_screen.dart` | 🟡 sin histórico de contratos PDF |
| 30 | Notificaciones | s16 | `notifications_screen.dart` | ✅ |

**Saldo: 8 pantallas nuevas (❌) y 4 desalineadas (🟡).** Las ocho nuevas son, sin
excepción, del journey del distribuidor.

### 2.1 Tres pantallas del archivo que **no** hay que construir

`Kredius Journey App.dc.html` todavía contiene las pantallas 19, 20 y 21
(*documentos del beneficiario*, *verificar datos*, *consentimiento del
beneficiario*, L1080-1209) — el KYC asistido, con el distribuidor capturando la
INE del cliente. **No están en el riel** (`RAIL()` L1585-1595 salta de 18 a 22) y
`beneNext` (L1956) manda de la 18 **directo a la 22**. Son la versión anterior del
flujo, quedaron huérfanas en el export.

Lo que las reemplazó es explícito en `kycModes` (L1940-1942), que hoy tiene **una
sola opción**:

> **Ella se verifica sola** — *"Le llega una liga por WhatsApp: pone su código,
> fotografía su INE y se toma su video. Desde su propio celular, sin ti."*

Y esa liga es la otra pieza nueva del bundle: **`KYC Beneficiario.dc.html`**, una
web responsive de 7 pasos (bienvenida → OTP → INE → prueba de vida → datos →
autorización → listo) que el beneficiario abre en **su** teléfono.

**Consecuencia de diseño, y es la más importante del bundle:** el distribuidor
nunca hace el KYC de su cliente. Captura tres datos, define monto y plazo, manda
la liga y espera. El aviso ámbar de la pantalla 17 (L1022) lo dice como regla:
*"cada persona a la que le coloques tiene que hacer su propio KYC y autorizar su
consulta de buró. Tú no puedes firmar por ella."*

---

## 3. Servicios: qué está conectado y qué falta

### 3.1 Lo que el BFF ya expone (`channel-mobile-service`, 36 endpoints)

Auth, OTP, OCR, KYC, `/users/me`, wallet (balance/transactions/transfer),
notificaciones (con lectura real), y todo el crédito propio:
`/credit/products`, `/prequalification`, `/applications` (+ `offer`,
`offer/accept`, `offer/reject`, `contract`, `contract/sign`), `/credit/account`,
`/credit/payment`, `/credit/dispose`, y los `/internal/test-support/*`.

El journey B2C está **completo y conectado**.

### 3.2 Lo que falta para la colocación

De las 8 pantallas nuevas, **ninguna tiene endpoint**. Lo único que existe es la
punta final del flujo:

```
POST /credit/dispose  { amount, dispositionType: THIRD_PARTY, beneficiaryPartyId }
```

…que ya acepta un beneficiario, **pero no hay forma de crear ese
`beneficiaryPartyId` desde la app**: el alta móvil sólo genera prospectos
`INDIVIDUAL` (B2C). El distribuidor mismo se onboardea por canal ops.

| Necesidad de la pantalla | Endpoint | Estado |
|---|---|---|
| Crear beneficiario + colocación y mandar la liga (s18+s22) | `POST /placements` | ❌ |
| Estado de la colocación / polling (s23) | `GET /placements/{id}` | ❌ |
| Reenviar o revocar la liga | `POST /placements/{id}/resend`, `/cancel` | ❌ |
| KYC del beneficiario desde la web (7 pasos) | API pública por token | ❌ |
| Semáforo de buró del beneficiario (s25) | `GET /placements/{id}/bureau` | ❌ |
| Decisión del distribuidor (s25) | `POST /placements/{id}/approve` \| `/reject` | ❌ |
| Lista de colocaciones con filtros (t2) | `GET /placements?status=` | ❌ |
| Lista y ficha de beneficiarios (t3) | `GET /beneficiaries`, `/{id}` | ❌ |
| Tarjeta de línea del distribuidor (h3) | `GET /distributor/line-summary` | ❌ |
| Bonificación 20% decreciente por atraso | `GET /commissions/...` | ⚠️ el dominio existe |

**Matiz que importa para el costo:** el backend **ya tiene el dominio**, lo que no
tiene es la orquestación ni el canal.

- `party-service` → `PartyRelationshipController` (`GET`/`POST /relationships`,
  `/incoming`): la relación distribuidor→beneficiario ya es un concepto de primera
  clase.
- `commission-service` → `GET /beneficiaries/{partyId}/pending`,
  `/promoters/credits`, políticas de comisión y `liquidation-runs`.
- `scoring-service` → política `DISTRIBUTOR/DISTRIBUTOR_LINE` sembrada y el
  `MockCirculoAdapter` determinista.
- `origination-service` → `ProspectType.DISTRIBUTOR` y disposición
  `THIRD_PARTY_CREDIT` validada E2E el 2026-07-27.
- `collections-service` → `GET /bureau-reports`.

No hay que inventar el dominio de comisiones ni el de relaciones: hay que
**componerlos** detrás de un agregado *Colocación* y publicarlos por el BFF.

---

## 4. Lo que sí se puede hacer ahora

La app tiene un flavor `mock` con interceptores Dio por módulo
(`shell_injection.dart` L16-25) y así se construyeron las seis pasadas
anteriores: **primero la UI contra el mock, después el cambio de interceptor por
el cliente real**. La colocación entra por el mismo camino, con una condición que
propongo respetar estrictamente:

> El mock **espeja el contrato de API que se propone en §6**, path por path y
> campo por campo. Conectar después es borrar el interceptor, no reescribir la
> capa de datos.

---

## 5. Plan de implementación

### Fase A — Reconciliar el alta con el bundle nuevo · ~0.5 día

| ID | Acción | Origen |
|---|---|---|
| A1 | `purpose_screen`: viñetas por opción (*"Línea revolvente de $25,000 a $500,000"*, *"KYC de cada beneficiario desde la app"*, *"20% de comisión sobre lo que cobras a tiempo"*) que **sólo se despliegan en la opción seleccionada**, y radio de 20 px con borde de 6 px | L1902-1919 |
| A2 | `purpose_screen`: banner ámbar con la regla del KYC propio | L1020-1023 |
| A3 | Copy: el diseño dice *"Para colocar a terceros"*; `CreditPurpose.distribuidor.title` dice *"Para colocar con mis clientes"* — alinear | L1906 |

**Divergencia que propongo mantener, no corregir:** el diseño pone el tipo de
perfil en el paso **4/5** (después del OTP); la app lo pide en el **paso 1**, antes
del celular. La razón está escrita en la 5ª pasada — *nada se pide antes de tener
permiso para pedirlo*, y el propósito decide qué productos se evalúan. Moverlo
obligaría a rehacer la evaluación. **Se queda como está y se documenta.**

### Fase B — Home multi-perfil · ~1.5 días

| ID | Acción | Origen |
|---|---|---|
| B1 | Nav dinámico: `[Inicio, Movimientos, Colocaciones, Beneficiarios]` con línea de distribuidor; `[Inicio, Movimientos, Oportunidades]` sin ella. Hoy son 3 fijas y "Créditos" ya no existe en el diseño (`tabCreditos: false`, L1700) | L1701-1713 |
| B2 | Reponer **Movimientos** como pestaña: chips de cuenta + agrupación por día con total. Reusa `movements_screen.dart`, `DsMovementTile` y `DsFilterChips` | L840-871 |
| B3 | Tarjeta **MI LÍNEA DE DISTRIBUIDOR**: colocado sobre autorizado, barra de avance, disponible, rejilla de 4 datos (total a cobrar, pago a Kredius, vencimiento, bonificación en verde menta) y CTA *Enviar préstamo* | L703-734, L2046-2051 |
| B4 | Widget nuevo `DsLineSummaryCard` en el DS + entrada en el guard test de compliance | — |

### Fase C — Flujo "Enviar préstamo" contra mock · ~4 días

Paquete nuevo **`fa_placements`** (vía `/create-module`, para heredar la
estructura hexagonal y el registro en `melos.yaml` + shell). Va aparte de
`fa_credit` porque su dominio es otro —beneficiario, colocación, comisión— y
`fa_credit` ya carga el otorgamiento completo.

| ID | Pantalla / pieza | Origen |
|---|---|---|
| C1 | **s18 · ¿A quién le vas a prestar?** — 3 campos (nombre como en su INE, celular a 10 dígitos, cómo la conoces) + selector de modo de verificación, hoy con una sola tarjeta; barra de 3 segmentos | L1029-1078, L1931-1956 |
| C2 | **s22 · Monto y plazo** — slider $5 000–línea, stepper de **quincenas**, tarjeta azul con *"ella paga cada quincena"* + **tu bonificación**, 3 renglones de resumen y el aviso ámbar de la comisión decreciente (20 → 17 → 14 → 10 → 6 → 0 %) | L1275-1340, L2053-2064 |
| C3 | **s23 · Liga enviada** — héroe azul, timeline de 4 pasos y la promesa explícita: *"tu línea sigue completa: sólo se descuenta cuando ella termine y tú apruebes"* | L1342-1384, L2065-2075 |
| C4 | **s25 · Su historial y tu decisión** — anillo de score, banda bajo/medio/alto, 5 renglones de riesgo, el bloque *"Kredius no aprueba ni rechaza: tú decides"*, casilla de asunción de riesgo y las dos salidas (aprobar / no colocar) | L1211-1273, L2014-2041 |
| C5 | **t2 · Colocaciones** — CTA, chips de filtro y lista con avatar, chip de estado, monto y comisión | L804-837 |
| C6 | **t3 · Beneficiarios** — buscador por nombre o celular, filas expandibles con 4 datos, *su contrato* / *sus pagos* / *enviarle otro préstamo* | L873-932 |
| C7 | `PlacementMockInterceptor` espejando §6, con máquina de estados real (`INVITED → KYC_IN_PROGRESS → BUREAU_READY → APPROVED → DISBURSED`) y emisión de eventos → notificaciones vía `shell_injection` | — |
| C8 | Widgets al DS: `DsScoreGauge`, `DsRiskFactsTable`, `DsPersonRow`, `DsSearchField`, `DsTimeline` | — |
| C9 | Tests: unitarios del cálculo de bonificación y de la máquina de estados; E2E de colocación en flavor mock | — |

### Fase D — Verificación · ~0.5 día

`flutter analyze` limpio en los 10 paquetes, suite unitaria en verde, guard test
de compliance extendido, y una corrida del journey de distribuidor en simulador
con grabación (como en las pasadas anteriores).

**Total Fases A–D: ~6.5 días de front, sin depender del backend.**

---

## 6. Contrato de API que el mock va a espejar

Es la propuesta que debe validar el diseño del servicio (§8). Todo cuelga del BFF
y del `partyId` inyectado por el gateway en `X-User-Id`.

```
POST   /placements
       { beneficiary: { fullName, phone, relationship },
         amount, termFortnights, verificationMode: "SELF_SERVICE_LINK" }
    →  { placementId, status: "INVITED", inviteExpiresAt, lineAvailableAfter }

GET    /placements?status=&query=&page=
    →  [ { placementId, beneficiary{ partyId, fullName, phoneMask, initials },
           status, amount, termFortnights, commissionAccrued, updatedAt } ]

GET    /placements/{id}
    →  { …, timeline: [ { step, state, at } ], kycProgress }

POST   /placements/{id}/resend        // reenviar la liga
POST   /placements/{id}/cancel        // revocar antes del KYC

GET    /placements/{id}/bureau        // sólo con status BUREAU_READY
    →  { score, band: "LOW|MEDIUM|HIGH", title, description,
         facts: [ { key, value, tone } ], recommendation }

POST   /placements/{id}/approve       // { riskAcknowledged: true }
    →  dispara dispose THIRD_PARTY + desembolso al beneficiario
POST   /placements/{id}/reject        // { reason? }

GET    /beneficiaries?query=
    →  [ { partyId, fullName, phoneMask, status, facts[], placementsCount } ]
GET    /beneficiaries/{partyId}       // contrato, tabla de pagos, historial

GET    /distributor/line-summary
    →  { authorized, placed, available, toCollect, dueToKredius,
         nextDueDate, commissionAccrued, status }
```

**Reglas de negocio que el diseño fija y el contrato debe honrar:**

1. **La línea no se aparta.** Se descuenta al aprobar, no al invitar (L1375).
2. **La liga vive 7 días**; si expira, la colocación no se crea (L2066).
3. **El KYC es todo o nada** (L2067).
4. **El buró se consulta con la autorización del beneficiario, no la del
   distribuidor** (L2068) — y por eso el distribuidor jamás ve la pantalla de
   consentimiento de su cliente.
5. **Kredius no filtra por score**: entrega el reporte y el distribuidor decide,
   asumiendo el riesgo por escrito (L1260-1267).
6. **La bonificación es 20 % de lo cobrado a tiempo**, y decae por día de atraso:
   17, 14, 10, 6 y al quinto día 0 (L1335).

---

## 7. Lo que queda fuera de este plan

| Qué | Por qué |
|---|---|
| **Web de KYC del beneficiario** (`KYC Beneficiario.dc.html`) | No es la app Flutter. Hay que decidir si vive en `kredius-web`, en el repo `fintech-backoffice-web` o como Flutter Web del mismo monorepo. **Es una decisión que te toca a ti**; hasta que se tome, el mock simula que el beneficiario completó su KYC. |
| Landing y Backoffice | Web, fuera del alcance de la app (el backoffice tiene su repo). |
| Los 7 puntos de `KREDIUS_JOURNEY_PLAN.md` §11 | Siguen abiertos: bytes del OCR, endpoints de selfie/comprobante, firma con OTP real, Face ID y social. |
| Histórico de contratos PDF en Perfil | Pendiente de la 4ª pasada, no lo toca la colocación. |

---

## 8. Lo que se implementó (2026-08-16)

### Paquete nuevo: `fa_placements`

Décimo paquete del monorepo, hexagonal como el resto. Dominio propio
—`Placement`, `Beneficiary`, `DistributorLine`, `BureauReport`— porque
colocación no es crédito: la deuda es del titular y el contrato del
beneficiario, y mezclarlos en `fa_credit` habría contaminado las dos.

| Capa | Piezas |
|---|---|
| Dominio | 4 entidades, `IPlacementRepository`, `PlacementQuote` + `CommissionPolicy` |
| Aplicación | 8 casos de uso |
| Infraestructura | 4 DTOs, `PlacementRepositoryImpl`, `PlacementsMockInterceptor` |
| Presentación | `PlacementProvider`, 6 pantallas, `PlacementTopBar` |

### Design system

Seis widgets nuevos (`DsNoticeBanner` + `DsCheckBullet`, `DsLineSummaryCard`,
`DsPersonRow` + `DsAvatar` + `DsListCard`, `DsTimeline` + `DsSegmentBar`,
`DsBureauScoreCard`, `DsSearchField`), el tono `DsChipTone.danger` y tres
tokens de color (`amberInk`, `onAmberContainer`, `onSecondaryContainer`).

`DsTermStepper` ganó `steps`: el crédito propio admite cualquier plazo, pero la
colocación sólo 12/24/36/48, y dejar pasar un 13 daba un pago que después no se
puede contratar.

### Contrato de tabs, reescrito

`IModule.ownedTab` (uno) pasó a `ownedTabs` (lista) más `areTabsVisible`, porque
colocación aporta **dos** pestañas y ambas dependen de tener línea. El nav dejó
de ser una constante de tres elementos: se compone en cada build.

**"Créditos" salió del nav** — el diseño lo quita (`tabCreditos: false`,
L1700) porque el carrusel de Inicio ya los muestra. La pantalla no se borró:
vive en `/credit/list`.

### Tres decisiones que se apartaron del prototipo

1. **Las pantallas 19–21 no se construyeron.** Están en el archivo pero fuera
   del riel, y `beneNext` salta de la 18 a la 22: son el KYC asistido que el
   diseño reemplazó por la liga self-service. Construirlas era trabajo tirado.
2. **El tipo de perfil se queda en el paso 1**, no en el 4/5 del diseño. La
   razón es la de la 5ª pasada: el propósito decide qué productos se evalúan, y
   preguntarlo después obliga a rehacer la evaluación.
3. **La tarjeta de crédito de fa_credit se suprime para el distribuidor** cuando
   su cuenta es la línea revolvente: `fa_placements` la pinta con el vocabulario
   correcto. Dos tarjetas del mismo dinero contándolo distinto es peor que una.

### Cuatro defectos que salieron de escribir los tests

1. **El directorio duplicaba a cada persona.** El mock derivaba beneficiarios de
   las colocaciones vivas *y* servía el directorio sembrado, así que María Luisa
   salía dos veces. Las de la semilla ahora se excluyen de la derivación.
2. **El mock resolvía los 4xx como éxito.** La capa de datos intentaba parsear
   `{message: …}` como colocación y el error llegaba a pantalla como un cast
   raro. Ahora rechaza con `DioException`, igual que haría el BFF.
3. **El pago quincenal que yo esperaba estaba mal**, no el cálculo: $45,000 a 24
   quincenas al 28.9 % dan **$2,170.16**, no $2,450. La fórmula del prototipo
   era la correcta.
4. **El nav podía quedar apuntando a un tab inexistente.** Si la línea
   desaparece estando en "Beneficiarios" (índice 3), el `IndexedStack` pedía un
   hijo que ya no estaba. Hay guardia y test.

### Verificación

- `flutter analyze` **limpio en los 10 paquetes**.
- **176 tests**: 79 en `fa_shell` (incluidos 14 nuevos de compliance y 4 del nav
  dinámico), 50 en `fa_credit`, **27 en `fa_placements`**, 17 en
  `fa_design_system`, 3 en `fa_auth`.
- `widget_test.dart` monta la app real en flavor mock con `PlacementsModule`
  registrado: el módulo arranca y compone sin romper el journey existente.
- **Journey de demostración en simulador, en verde (2:44)**:
  `integration_test/placement_journey_showcase_test.dart` recorre alta como
  distribuidora → home con la línea → Enviar préstamo (a quién → monto y plazo →
  liga enviada) → la beneficiaria se verifica sola → su historial de buró →
  asumir el riesgo → aprobar → Colocaciones y Beneficiarios → notificaciones.
  Grabación en `kredius_journey_e2e.mp4` (4:22, iPhone 16 · iOS 26.1), que recorre los
  dos perfiles: uso propio con préstamo personal y distribuidora con colocación.

### Un defecto más, que sólo se vio al grabar

El home del distribuidor mostraba **"Tu solicitud está en revisión" encima de una
línea ya disponible**: `fa_credit` pintaba el estado de su solicitud sin saber
que `fa_placements` ya estaba enseñando la línea autorizada. Es la contradicción
más cara que puede tener esa pantalla —dice que no puedes usar el dinero que te
está ofreciendo dos centímetros más abajo.

Se resolvió con `AppSession.hasDistributorLine`: el módulo de colocación publica
el hecho al cargar la línea y el de crédito lo consume para callarse. Va en la
sesión porque es justo el tipo de dato que dos módulos que no se importan entre
sí necesitan compartir — el mismo lugar donde ya viven `purpose` y `prospectId`.
