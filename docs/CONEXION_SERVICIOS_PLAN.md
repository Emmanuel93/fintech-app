# Conectar el journey Kredius a fintech-services

**Fecha:** 2026-08-10 · **Método:** se recorrió el journey completo contra el
gateway local (`localhost:8090`, `Host: mobile.localhost`) con `curl`, servicio
por servicio, y se comparó cada respuesta contra lo que la app espera.

**Entorno de la auditoría:** gateway, identity, channel-mobile y los diez
servicios de dominio (party, credit-product, scoring, origination,
credit-portfolio, payments, charges, collections, notifications, wallet)
levantados con `docker compose up -d`, sobre postgres/kafka/redis ya corriendo.

---

## 1. Qué está conectado hoy

La cadena completa **funciona de punta a punta contra servicios reales**. Se
otorgó un crédito de $50,000 a 12 meses y quedó `ACTIVE` en
`credit_portfolio.credit_accounts`, con su contrato `CTR-202608-6FCE8493`.

| Paso del journey | Endpoint | Estado |
|---|---|---|
| Envío de código | `POST /otp/send` | ✅ 200 |
| Verificación | `POST /otp/verify` | ✅ 200 · `preAuthToken` |
| Alta de KYC | `POST /kyc/submit` | ✅ 200 · `folioKyc` |
| Crear cuenta | `POST /auth/register` | ✅ 200 · `userId` (**sin token**, ver §2.1) |
| Login | `POST /auth/login` | ✅ 200 · `token` + `refreshToken`, 900 s |
| Catálogo | `GET /credit/products` | ✅ 200 |
| Precalificación | `GET /credit/prequalification` | ✅ 200 (el 400 era una imagen vieja, §3.1) |
| Solicitud | `POST /credit/applications` | ✅ 201 |
| Consulta / polling | `GET /credit/applications/{id}` | ✅ 200 |
| Oferta | `POST …/offer` · `…/offer/accept` | ✅ 200 |
| Contrato | `POST …/contract` | ✅ 200 |
| Firma | `POST …/contract/sign` | ✅ 200 · `clabeAccount` (no `clabe`) |
| Cuenta de crédito | `GET /credit/account` | ✅ 200 · **asíncrona** (ver §2.3) |
| Perfil | `GET /users/me` | ✅ 200 |
| Notificaciones | `GET /notifications` | ✅ 200 |
| Wallet | `GET /wallet/balance` | ✅ 404 correcto sin cuenta activa |
| Pago | `POST /credit/payment` | ✅ 200 con cuenta activa |
| Soporte: devengo | `POST /internal/test-support/run-daily-accrual` | ✅ 200 · `{eligibleSchedules: 12}` |
| Soporte: corte | `POST …/run-installment-due-job` | ✅ 200 |
| Soporte: vencimiento | `POST …/run-upcoming-installment-job` | ✅ 200 |
| Soporte: mover fecha | `POST …/{acc}/installments/{n}/shift-due-date?daysFromToday=` | ✅ expuesto |

**Los endpoints de soporte que pediste ya existen.** `TestSupportProxyController`
en el BFF reenvía a charges-service y credit-portfolio-service: correr el
devengo diario, disparar el corte, marcar vencidas y mover la fecha de una
mensualidad. Están detrás de `fintech.channel-mobile.test-support-enabled`, así
que no se exponen en QA ni producción.

---

## 2. Qué falta — lado **app** (fintech-app)

### 2.1 Sin sesión después de crear la cuenta — **corregido**

`/auth/register` devuelve `{success, userId, message}` y **ningún token**. La app
nunca llamaba a `/auth/login` después, así que todo lo que sigue —productos,
precalificación, solicitud, cuenta— habría salido **401 justo en el primer
ingreso del usuario**. En mock no se notaba: el interceptor responde sin mirar
el token.

`KycRepositoryImpl.createAccount` ahora inicia sesión con el celular y la
contraseña recién creados y deja el bearer puesto. Falla en silencio a
propósito: la cuenta ya existe y bloquear el alta sería peor que mandar al
login.

### 2.2 Precalificación sin `prospectId` — **corregido**

El código asumía que el BFF lo resolvía del JWT como hace `/credit/account`.
No: responde `400 Required parameter 'prospectId' is not present`. Ahora se
manda el de la sesión. Cuando el BFF unifique el criterio (§3.1), el parámetro
sobra y no estorba.

### 2.3 Género invertido — **corregido**

La app mandaba `M` para *Masculino* y `F` para *Femenino*. En el estándar CURP
—que es el que valida el BFF— **`M` es Mujer** y `H` es Hombre; `F` no existe.
Resultado: los hombres se registraban como mujeres y las mujeres eran
rechazadas con *"Género debe ser H, M o X"*. Ahora el selector usa H/M/X con
etiquetas Hombre/Mujer/No binario.

### 2.4 Nombres de campos de cartera — **corregido**

El payload de `/credit/account` usa `daysDelinquent` y `penaltyBalance`; la app
leía `daysPastDue` y `overdueAmount`. Se aceptan ambos.

### 2.5 La cuenta se crea de forma asíncrona — **pendiente**

Firmar responde 200 pero la cuenta aparece en `/credit/account` **medio segundo
después**: la crea credit-portfolio al consumir el evento de Kafka. La primera
consulta devuelve `[]`.

> **Qué hacer:** tras la firma, reintentar `/credit/account` con backoff corto
> (p. ej. 5 intentos cada 400 ms) antes de dar por bueno el estado vacío. Hoy la
> pantalla de desembolso navega al home y el home muestra "sin créditos" si
> alcanza a consultar antes de que el evento aterrice.

### 2.6 Campos que la tarjeta del home necesita — **resuelto por §3.2**

`minimumPayment`, `paymentDueDate` y el contador de pagos ya vienen en
`/credit/account`. El DTO de la app no necesitó cambios: ya aceptaba
`paidInstallments` como alias de `paymentsMade`, y `assignedTerm` cubre el
total. Que la UI tratara estos campos como opcionales —"—" y barra
indeterminada en vez de un cero inventado— fue lo que permitió conectar sin
romper nada mientras el backend no los mandaba.

### 2.7 OCR y documentos — **pendiente** (ya estaba en el plan del journey)

`/ocr/extract` manda `fileName`, no los bytes, y no hay endpoint para la selfie
ni el comprobante. El KYC real no puede validarse con eso.

---

## 3. Lado **fintech-services** — cerrado el 2026-08-10

> Todo lo de esta sección quedó implementado y verificado contra el journey
> completo. Se conserva la descripción del problema porque explica el porqué de
> cada cambio. El repo `fintech-services` ahora está versionado con git; los
> ajustes viven en el commit *"Expone el avance del plan de pagos y cierra el
> aviso de mora"*.

### 3.1 ~~Resolver el prospecto del JWT~~ ✅

Resultó que `/credit/prequalification` **ya lo resolvía del token en el
código**: el 400 de la auditoría venía de una imagen de hace dos días. El que sí
lo exigía era `GET /credit/applications`, y ese sí se corrigió — pedirlo por
query permitía leer las solicitudes de otra persona cambiando el parámetro.

**Lección:** la auditoría se hizo contra los contenedores corriendo, no contra
el código. Antes de concluir que algo falta, verificar que la imagen sea del
commit que se está leyendo.

### 3.2 ~~El payload de la cuenta no trae el plan de pagos~~ ✅

Es lo que impide que el home muestre el avance real. Falta exponer, desde el
calendario que credit-portfolio ya tiene:

| Campo | De dónde sale |
|---|---|
| `paymentsMade` | mensualidades pagadas del `amortization_schedule` |
| `assignedTerm` | ya viene ✅ |
| `minimumPayment` | importe de la siguiente mensualidad |
| `paymentDueDate` | vencimiento de la siguiente |
| `cutoffDate` | corte del periodo |
| `principalPaid` | capital amortizado acumulado |
| `overdueAmount` | vencido + moratorios (hoy sólo `penaltyBalance`) |

**Cómo quedó:** `PaymentPlanSummary` deriva el resumen del calendario en
credit-portfolio y `CreditAccountResponse` lo expone; el BFF lo reenvía. Se
resuelve en el servicio dueño del calendario y no en el canal, porque un
cálculo del lado del cliente se desincroniza en cuanto hay un pago parcial o una
reestructura.

Verificado: `paidInstallments 0, totalInstallments 12, nextInstallmentNumber 1,
paymentDueDate 2026-08-04, minimumPayment 4173.89, overdueAmount 4173.89,
overdueInstallments 1, daysDelinquent 6`.

**De paso:** `InstallmentDueJob` buscaba sólo las que vencen *hoy*. Una corrida
fallida —o una fecha movida— dejaba esa mensualidad pendiente para siempre: nadie
la marcaba vencida y el cliente nunca se enteraba. Ahora busca "hoy o antes" y se
recupera solo del día que se perdió.

> `days_delinquent` **ya existe** en `credit_portfolio.credit_accounts` y ya se
> expone como `daysDelinquent`. La mora del backend y la de la app hablan el
> mismo idioma; sólo falta el resto del plan.

### 3.3 ~~Notificaciones de vencimiento y mora~~ ✅

`notifications.credit_account_progress` ya existe y los jobs de corte corren,
pero no se vio llegar el aviso a `GET /notifications` al dispararlos. Verificar
que `run-installment-due-job` publique el evento que notifications-service
consume, con el número de mensualidad y los días de atraso — es lo que la app
muestra en el aviso.
**Cómo quedó:** notifications-service ahora **consume**
`credit-portfolio.installment-due`, que se publicaba sin que nadie lo
escuchara. Un mismo evento produce recordatorio o aviso de mora según los días
de atraso —decir "tu pago vence el 9" cuando ya es 15 confunde a quien tiene que
ponerse al corriente—, con `PAYMENT_OVERDUE` y sus plantillas. El BFF le da copy
propio al inbox, que antes caía al genérico "tienes una notificación nueva".

### 3.4 ~~Rate limit del gateway estorba a las pruebas~~ ✅

Tres altas seguidas disparan `rate_limited` en `/kyc/submit` y `/auth/register`.
Razonable en producción; en local impide correr la suite E2E de corrido.
**Cómo quedó:** las zonas salieron a `rate-limits.conf` (producción, sin
cambios) y `rate-limits.local.conf` (holgado), y el compose monta una u otra
según `GATEWAY_RATE_LIMITS`. El `burst` por ubicación no se toca: es la
protección real y no debe depender del entorno.

### 3.5 ~~`otel-collector` no resuelve~~ ✅

Cada request escupe `UnknownHostException: otel-collector` en los logs. No
afecta al negocio, pero enmascara errores reales.
**Cómo quedó:** `OTEL_TRACES_EXPORTER` por default en `none`. Al levantar el
perfil de observabilidad se pone en `otlp`.

---

## 4. Qué queda

| # | Qué | Lado |
|---|---|---|
| 1 | Bytes del OCR y endpoints de selfie/comprobante (§2.7) | ambos |
| 2 | `OtpServiceTest` y dos pruebas de onboarding en channel-mobile | services |

La segunda no la introdujeron estos cambios: fallan igual en la línea base del
repo, y se dejaron como estaban para no mezclar arreglos ajenos en el mismo
commit.

Con lo de §3 cerrado, el journey corre conectado de punta a punta y la app deja
de degradar: muestra el mismo avance de pagos y la misma mora que hoy enseña el
mock.

### El puerto del gateway

En esta máquina el 8080 lo ocupa otro proceso, así que el gateway se publica en
**8090** vía `GATEWAY_PORT` en el `.env` local. La app apunta ahí con
`--dart-define=BFF_URL=http://mobile.localhost:8090`.

---

## 5. Cómo reproducir la auditoría

```bash
cd ~/Documents/projects/fintech-services
docker compose up -d party-service credit-product-service scoring-service \
  origination-service credit-portfolio-service payments-service \
  charges-service notifications-service wallet-service

# El journey completo, paso por paso (celular y CURP nuevos en cada corrida)
bash /tmp/journey_bff.sh 5599885511 ana@correo.com RIVM900112MDFVLZ11
```

La app contra servicios reales:

```bash
cd packages/fa_shell
flutter run -t lib/main_local.dart --dart-define=BFF_URL=http://mobile.localhost:8090
```
