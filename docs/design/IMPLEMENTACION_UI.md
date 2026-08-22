# Kredius — de este prototipo a `fintech-app` (Flutter)

Guía de implementación del journey diseñado en `Kredius Journey.dc.html`.
Todo lo que sigue asume la arquitectura ya verificada en `docs/INTEGRATION_TRACKER.md`:
app → gateway `:8080` → BFF `channel-mobile-service`. **Ninguna pantalla llama a un servicio de dominio directo.**

---

## 1. Design tokens — qué ya existe y qué falta

Ya en `fa_design_system/lib/src/theme/app_colors.dart`:

| Token | Valor | Uso en el diseño |
|---|---|---|
| `primary` | `#0D47A1` | fondo de héroe, CTA principal, tarjeta wallet, iconos activos |
| `primaryContainer` | `#D6E4FF` | chips, fondo de iconos, banners informativos |
| `onPrimaryContainer` | `#001A42` | texto sobre `primaryContainer` |
| `secondary` | `#00695C` | montos de ingreso, check de criterios, estado "al corriente" |
| `secondaryContainer` | `#B2DFDB` | chips de estado OK / verificado |
| `tertiary` | `#FF8F00` | contraoferta, badge "pasa a comité", punto de notificación |
| `surfaceVariant` | `#F5F7FA` | — **cambiar** (ver abajo) |
| `outlineVariant` | `#E0E0E0` | bordes de tarjeta e input |
| `onSurfaceVariant` | `#44474E` | texto secundario |
| `disabled` | `#9E9E9E` | labels, metadatos |

**Cambios a hacer en el tema:**

```dart
// app_colors.dart
static const Color surfaceVariant = Color(0xFFEBF0F7); // era F5F7FA — el blanco se veía plano
static const Color accentGreen   = Color(0xFF00B894);  // acento del logo y progreso
static const Color divider       = Color(0xFFEDEFF3);  // separador dentro de tarjetas
```

El resto ya coincide: Inter (`GoogleFonts.interTextTheme`), radio 12 en botones/inputs, botones de 52 px.
En el diseño uso además radio **16–22** para tarjetas y **99** para chips: agrégalos como constantes
(`AppRadii.card = 18`, `AppRadii.chip = 999`) en `fa_design_system`.

---

## 2. Mapa pantalla → paquete → endpoint

| # | Pantalla del prototipo | Paquete | Pantalla Flutter | Endpoint (BFF) |
|---|---|---|---|---|
| 0 | Bienvenida | `fa_onboarding` | `welcome_screen.dart` | — |
| 1 | Datos (text fields) | `fa_onboarding` | `personal_data_screen.dart` | `POST /kyc/submit` |
| 1b | Documentos (INE, selfie, comprobante) | `fa_onboarding` | `ine_capture_screen.dart` + nueva `documents_screen.dart` | `POST /ocr/extract` |
| 2 | Consentimiento buró y círculo | `fa_onboarding` | `privacy_consent_screen.dart` | incluido en `/kyc/submit` |
| 3 | Análisis de riesgo | `fa_credit` | `application_status_screen.dart` (polling) | `GET /credit/applications/{id}` |
| 4 | Aprobado + criterios | `fa_credit` | `offer_screen.dart` (encabezado) | `POST /credit/applications/{id}/offer` |
| 5 | **Preofertas (carrusel)** | `fa_credit` | `product_selection_screen.dart` | `GET /credit/products` |
| 6 | Cómo solicitar | `fa_credit` | `offer_screen.dart` (cuerpo) | — |
| 7 | Configurador monto/plazo | `fa_credit` | `application_amount_screen.dart` | `POST /credit/applications` |
| 8 | Resumen + destino de depósito | `fa_credit` | `contract_sign_screen.dart` | `POST /credit/applications/{id}/contract` |
| 9 | Firma OTP | `fa_credit` | `contract_sign_screen.dart` | `.../contract/sign` |
| 10 | Desembolso confirmado | `fa_credit` | nueva `disbursement_success_screen.dart` | evento Kafka → `GET /credit/account` |
| 11 | Home · Resumen (wallet + crédito) | `fa_shell` + `fa_wallet` | `home_screen.dart` | `GET /wallet/balance`, `GET /credit/account` |
| 11 | Home · Créditos (historial) | `fa_credit` | nueva `credits_list_screen.dart` | `GET /credit/account` (+ histórico) |
| 11 | Home · Movimientos | `fa_wallet` | `transactions_screen.dart` | `GET /wallet/transactions` |
| 11 | Perfil + contratos | `fa_profile` | `profile_screen.dart` | `GET /users/me` |
| 12 | Contraoferta | `fa_credit` | `offer_screen.dart` (variante) | `.../offer/reject` + nueva oferta |

---

## 3. Widgets nuevos para `fa_design_system`

Cada uno sale 1:1 del prototipo:

1. **`DsProductCarouselCard`** — tarjeta 262×250 con icono, chip de segmento (`B2C`/`B2B`/`B2B2C`),
   nombre, descripción, línea autorizada y badge de estado. Se alimenta de `CreditProduct`
   (`productType`, `targetAudience`, `maxAmount`, `behavior`).
   Contenedor: `ListView.separated(scrollDirection: Axis.horizontal)` + `PageScrollPhysics`.
2. **`DsAmountSlider`** — slider con `divisions` derivadas de `CreditProduct.amountStep`,
   `min: minAmount`, `max: maxAmount`; thumb blanco con borde `primary`.
3. **`DsTermStepper`** — `−` / valor / `+` sobre la lista de plazos del producto
   (`minTerm..maxTerm`), con barra de progreso por segmentos.
4. **`DsPaymentSummaryCard`** — bloque azul con pago mensual, total e intereses.
   **Nunca muestra la tasa**: solo `pago`, `total`, `interés`. El cálculo vive en
   `AmortizationCalculator` (ya existe en `fa_credit`), y se re-evalúa en cada cambio de slider/plazo.
5. **`DsWalletCard`** — tarjeta de débito: saldo, `•••• {últimos 4}`, CLABE (`WalletBalance.clabe`,
   ya expuesta desde la sesión 3 del tracker) y tres acciones.
6. **`DsCreditListTile`** — fila de historial expandible. Para `DISTRIBUTOR_LINE` muestra
   beneficiario, su referencia SPEI y la comisión; para revolvente, "tabla por disposición".
7. **`DsMovementTile`** — fila de movimiento mapeada desde `TransactionCategory`:

   ```dart
   IconData iconFor(TransactionCategory c) => switch (c) {
     TransactionCategory.disposicion  => Icons.south_west,
     TransactionCategory.transferIn   => Icons.south_west,
     TransactionCategory.deposit      => Icons.south_west,
     TransactionCategory.transferOut  => Icons.north_east,
     TransactionCategory.payment      => Icons.north_east,
     TransactionCategory.withdrawal   => Icons.north_east,
     _                                 => Icons.swap_horiz,
   };
   ```
   Color: `secondary` si `transaction.isIncome`, `onSurface` si no.
8. **`DsDocumentTile`** — captura de documento con estado LISTO / CAPTURAR
   (`DocumentFile`; ojo con el gap conocido: hoy solo se manda `fileName`, no los bytes).

---

## 4. Detalles de comportamiento que el prototipo define

**Configurador.** El pago mensual se recalcula en cada `onChanged` del slider — no al soltar.
Fórmula: `pago = P·i / (1 − (1+i)^−n)` con `i = nominalRate/12`. Se muestran **pago mensual,
total a pagar e intereses incluidos**; la tasa y el CAT quedan solo en el contrato PDF.

**Productos revolventes.** `CreditProduct.requiresAmount == false` → la pantalla de monto se salta
y se va directo a contrato; el monto se define al **disponer** (`POST /credit/dispose`).

**Distribuidor (B2B2C).** En la disposición hay que capturar beneficiario y mandar
`dispositionType: THIRD_PARTY_CREDIT` + `beneficiaryPartyId`. El prototipo asume una pantalla
adicional de "elegir beneficiario" antes de disponer — hoy no existe en la app.

**Destino del depósito.** Dos caminos: CLABE ya registrada (viene en `WalletBalance.clabe`) o
captura de CLABE de 18 dígitos con validación de longitud y titularidad contra CURP. Si no tiene
cuenta, se ofrece abrir la cuenta Kredius (el wallet se crea solo al firmar, vía Kafka).

**Segmentos.** `INDIVIDUAL` auto-aprueba; `BUSINESS` y `DISTRIBUTOR` van a comité — la pantalla de
análisis debe terminar en "en revisión" y no en "aprobado" para esos dos, con
`COMMITTEE_REVIEW`/`UNDER_MANUAL_REVIEW` como estados válidos del polling.

**Perfil.** Fuera del `BottomNavigationBar` (3 tabs: Inicio, Créditos, Movimientos). Se abre al
tocar el nombre o el avatar del header → `Navigator.push`, no un tab.

---

## 5. Orden sugerido de trabajo

1. Tokens (`surfaceVariant`, verde de acento, radios de tarjeta) — toca todo, va primero.
2. `fa_design_system`: los 8 widgets de arriba, con `flutter analyze` limpio.
3. `fa_onboarding`: text fields de `PersonalData` + paso de documentos.
4. `fa_credit`: carrusel de productos → configurador → resumen con destino de depósito.
5. `fa_shell` + `fa_wallet`: home de 3 tabs, wallet card, movimientos.
6. `fa_credit`: lista/historial de créditos con contrato por tipo de línea.
7. `fa_profile`: perfil desde el header + contratos históricos.

Pendientes reales que este diseño toca y siguen abiertos en el tracker: subir los bytes del
documento en OCR, y la pantalla de beneficiario para disposiciones `THIRD_PARTY_CREDIT`.
