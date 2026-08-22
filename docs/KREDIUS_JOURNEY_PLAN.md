# Kredius — Plan de integración E2E del diseño a la app Flutter

**Estado:** ✅ **F0–F6 implementadas** (2026-08-09). `flutter analyze` limpio en los 9 paquetes y toda la suite unitaria en verde. Ver §14 para lo que quedó fuera.
**Fecha:** 2026-08-09
**Alcance:** replicar el journey completo del prototipo — entrada (splash/welcome/login) → alta con documentos y datos → consentimiento de buró → análisis → aprobado → preofertas → configurador → firma → desembolso → home logueado — con las animaciones del prototipo.

> Este documento se escribió como plan y se conserva como **registro de lo implementado**: las secciones 3–9 describen lo que efectivamente se construyó, con el origen de diseño de cada pieza. La §14, al final, lista lo que quedó pendiente y por qué.

---

## 0. Fuentes del diseño — de dónde sale cada cosa

Todo lo que sigue cita el archivo y las líneas exactas del bundle de handoff, para que ninguna decisión visual quede "a criterio".

| Fuente | Ruta | Qué aporta |
|---|---|---|
| **Journey (primario)** | `docs/design/Kredius Journey App.dc.html` | Las 16 pantallas móviles 402×874. Markup en L27–L840, lógica y estilos derivados en el `<script>` L843–L1271. |
| Guía de implementación | `.../project/docs/IMPLEMENTACION_UI.md` | Mapa pantalla → paquete → endpoint BFF, y las reglas de negocio que el prototipo asume. |
| Marca | `packages/fa_design_system/assets/brand/README.md` + `isotipo/*.svg` | Geometría exacta de la K, y **cuál variante va en cada fondo**. |
| Keyframes | `Kredius Journey.dc.html` L18–L20 | `kr-spin`, `kr-pulse`, `kr-rise`. |
| Estilo del slider | `Kredius Journey.dc.html` L21–L23 | Track 8px `#D6E4FF`, thumb 30px blanco con borde 3px `#0D47A1`. |
| Landing / Backoffice | `Kredius Landing.dc.html`, `Kredius Backoffice.dc.html` | **Fuera de alcance** de este plan (web, no app). |
| `support.js`, `ios-frame.jsx` | `.../project/` | Runtime del prototipo (`DCLogic`, `sc-if`, `sc-for`) y chrome del device (Dynamic Island, home indicator). **No contienen diseño de producto**: `ios-frame.jsx` dibuja el marco del iPhone, que en la app real lo pone el sistema. No hay que portar nada de estos dos archivos. |

---

## 1. Diagnóstico de los defectos reportados

### 1.1 El isotipo del Welcome está en la variante equivocada — **confirmado**

El prototipo dibuja en el welcome (L135–L139) y en el login (L71–L75) un **tile blanco de 46×46 radio 13** con el astil y la pierna en `#0D47A1` y el brazo superior en `#00B894`:

```html
<div style="width:46px;height:46px;border-radius:13px;background:#fff;…">
  <span style="…background:#0D47A1"></span>                    <!-- astil -->
  <span style="…background:#00B894;transform:rotate(-45deg)"></span> <!-- brazo verde -->
  <span style="…background:#0D47A1;transform:rotate(45deg)"></span>  <!-- pierna -->
</div>
```

Y el manual de marca lo dice explícito (`assets/brand/README.md` L18):
> **Invertido** (tile blanco, K azul) — **Sobre el azul de marca** — es el que usa la pantalla de bienvenida y el login de la app.

Lo que la app pinta hoy en [welcome_screen.dart:46](packages/fa_onboarding/lib/src/presentation/screens/welcome_screen.dart#L46) es `KrediusBrand(markSize: 44, onDark: true)`, que resuelve a `KrediusMark.onDark` → **trazos blancos sin tile** ([kredius_brand.dart:36](packages/fa_design_system/lib/src/brand/kredius_brand.dart#L36)). Falta por completo la variante invertida: [kredius_mark.dart:30-45](packages/fa_design_system/lib/src/brand/kredius_mark.dart#L30-L45) sólo expone `onDark`, `onLight` y `badge` (badge = tile **azul** con K blanca, que es el ícono de app, no esto).

**Acción:** agregar el constructor `KrediusMark.inverted` (tile blanco radio 22%, astil+pierna `primary`, brazo `accentGreen`) y una bandera `inverted` en `KrediusBrand`.

### 1.2 La tipografía "se ve ligeramente diferente" — **confirmado, tres causas**

**(a) La fuente no está embebida.** `fa_design_system` usa `google_fonts: ^6.2.1` ([pubspec.yaml:13](packages/fa_design_system/pubspec.yaml#L13)) y ningún `fonts:` declarado. `GoogleFonts.inter*` descarga el TTF en runtime; en el primer arranque, sin red, o con la caché fría, Flutter renderiza con **Roboto/SF** y todo el journey se ve "casi pero no". Esto explica el síntoma mejor que cualquier ajuste de tamaño.

**(b) Los `letterSpacing` de Material siguen puestos.** El prototipo escribe Inter con tracking **0** en cuerpo y etiquetas; el `TextTheme` de la app conserva los defaults de Material: `bodyLarge 0.5`, `bodyMedium 0.25`, `titleMedium 0.15`, `labelMedium/Small 0.5` ([app_text_styles.dart:103-139](packages/fa_design_system/lib/src/theme/app_text_styles.dart#L103-L139)). A 14px, 0.25 de tracking ensancha visiblemente cada párrafo.

**(c) Los títulos de pantalla usan el estilo equivocado.** El prototipo usa `font:700 27px/1.15; letter-spacing:-1.1px` para todos los H2 (L169, L239, L529). `AppTextStyles.screenTitle()` ya replica eso exactamente ([app_text_styles.dart:41](packages/fa_design_system/lib/src/theme/app_text_styles.dart#L41)) — pero **sólo lo usa `application_amount_screen.dart`**. El resto (`personal_data`, `ine_capture`, `ocr_review`, `offer`, `product_selection`, `application_status`) usa `theme.textTheme.headlineSmall`, que es **24px w600 sin tracking negativo**. De ahí el "ligeramente diferente".

**(d) Menor, pero real:** el welcome escala el titular con `h * 0.05` ([welcome_screen.dart:50](packages/fa_onboarding/lib/src/presentation/screens/welcome_screen.dart#L50)). En el frame de diseño (874) da 43.7 ≈ 42 ✓, pero en un Android de 915dp da 45.7 y en un SE de 667 da 33 — el titular pierde la proporción del diseño en los extremos.

### 1.3 "Datos" y "Documentos" no están homologados — **confirmado**

El prototipo resuelve identidad en **una sola pantalla con un segmented control de dos pestañas** (L172–L176, estilos en L1061–L1064), progreso `1/4`, título "Cuéntanos de ti", y un CTA que cambia de label según la pestaña (L1066).

La app lo tiene partido en **tres pantallas distintas con tres estéticas distintas**: `ine-capture` → `ocr-review` → `personal-data` ([onboarding_module.dart:75-86](packages/fa_onboarding/lib/onboarding_module.dart#L75-L86)). No hay segmented control en ningún lado, `personal_data_screen` usa `DropdownButtonFormField` crudos con `InputDecoration` inline (L250–L305, L444–L470) en vez de los agrupadores del diseño, y no existen los **chips de procedencia** (`INE · OCR`, `VALIDADO`, `CP VALIDADO`, `OTP VERIFICADO`) que en el prototipo encabezan cada grupo (L182–L185, L1069–L1099).

### 1.4 El orden de las pestañas debe invertirse — **cambio pedido sobre el diseño**

El prototipo trae `['Datos', 'Documentos']` (L1061) y sugiere capturar documentos después. **Se invierte a `['Documentos', 'Datos']`**, que además es lo coherente con el propio texto del prototipo (L216): *"Leímos tu INE y llenamos nombre, CURP, fecha de nacimiento y domicilio. Revísalos en la pestaña Datos antes de continuar."* — el OCR sólo puede apalancar el llenado si los documentos van primero.

Documentos del prototipo (L1107–L1111), en este orden: **INE frente → INE reverso → Selfie de vida → Comprobante de domicilio**.

---

## 2. Auditoría E2E: prototipo vs. app

`✅` existe y es fiel · `🟡` existe pero no coincide con el diseño · `❌` no existe

| # | Pantalla (líneas del prototipo) | Destino en la app | Hoy |
|---|---|---|---|
| 0b | **Login** L63–127, L1033–1046 | `fa_auth/…/login_screen.dart` | 🟡 fondo claro + `DsTextField`; el diseño es héroe azul con inputs translúcidos, Face ID y social |
| 0 | **Bienvenida** L129–159, L1059 | `fa_onboarding/…/welcome_screen.dart` | 🟡 estructura fiel; logo equivocado y stats con copy distinto |
| 1 | **Datos + Documentos** L161–229, L1061–1118 | `fa_onboarding` (pantalla nueva unificada) | 🟡 partido en 3 pantallas, sin tabs ni chips |
| 2 | **Consentimiento buró/círculo** L231–258, L1151–1158 | `fa_onboarding/…/privacy_consent_screen.dart` | 🟡 no muestra las dos SIC como tarjetas |
| 3 | **Análisis** L260–280, L1160–1168 | `fa_credit/…/application_status_screen.dart` | 🟡 `CircularProgressIndicator` genérico sobre fondo claro; el diseño es héroe azul con 4 pasos animados |
| 4 | **Aprobado + criterios** L282–315, L1170–1176 | `fa_credit/…/offer_screen.dart` | 🟡 icono `verified` + `LoanTermsCard`; falta header azul, badge pulsante y lista de criterios |
| 5 | **Preofertas (carrusel)** L317–370, L1178–1198 | `fa_credit/…/product_selection_screen.dart` | 🟡 `ListView` vertical de filas; `DsProductCarouselCard` **existe en el DS pero nadie lo usa** en pantalla |
| 6 | **Cómo solicitar** L372–399, L1200–1204 | `fa_credit` (nueva) | ❌ |
| 7 | **Configurador** L401–463, L1206–1214 | `fa_credit/…/application_amount_screen.dart` | 🟡 lo más cercano al diseño; falta el header, el "cada día 5" y los dots de plazo |
| 8 | **Resumen + destino de depósito** L465–520, L1216–1234 | `fa_credit/…/contract_sign_screen.dart` | 🟡 sin tabs "Ya tengo / No tengo cuenta" ni la opción "ábrete cuenta Kredius" |
| 9 | **Firma OTP + teclado** L522–543, L1241–1255 | `fa_credit` (separar de la 8) | ❌ hoy se firma con `signatureProof` sintético |
| 10 | **Desembolso** L545–566, L1257–1261 | `fa_credit` (nueva) | ❌ hay un `_SignedState` genérico |
| 11 | **Home · Resumen** L568–644 | `fa_shell/…/home_screen.dart` + `fa_wallet` | 🟡 header y nav no coinciden; `DsWalletCard` sólo vive en la home-card del módulo |
| 11 | **Home · Créditos** L646–708, L954–997 | `fa_credit/…/credits_list_screen.dart` | 🟡 falta el bloque "disposición a tercero" del B2B2C |
| 11 | **Home · Movimientos** L710–752, L999–1022 | `fa_wallet/…/movements_screen.dart` | 🟡 faltan filtros por tipo y agrupación por día |
| 11 | **Perfil + contratos** L754–788, L1120–1149 | `fa_profile/…/profile_screen.dart` | 🟡 sin chips de procedencia ni histórico de contratos PDF |
| 12 | **Contraoferta** L807–836, L1263–1267 | `fa_credit` (variante) | ❌ |

---

## 3. Fase 0 — Fundaciones (bloquea todo lo demás)

| ID | Acción | Archivo | Origen del diseño |
|---|---|---|---|
| **F0-1** | Embeber Inter estático (400/500/600/700/800) como asset y declarar `family: Inter`; reemplazar `GoogleFonts.inter*` por `TextStyle(fontFamily: 'Inter')`. Elimina la dependencia de red y el fallback a Roboto. | `fa_design_system/assets/fonts/`, `pubspec.yaml`, `app_text_styles.dart`, `kredius_wordmark.dart`, `kredius_brand.dart` | `Journey L14` (`family=Inter:wght@400;500;600;700;800`) |
| **F0-2** | Poner `letterSpacing: 0` en `bodyLarge/bodyMedium/bodySmall/labelMedium/labelSmall/titleMedium/titleSmall` y `height: 1.5` en los body. | `app_text_styles.dart` L85–L139 | Journey: cuerpo `400 14px/1.5`, sin tracking (L170, L302, L385) |
| **F0-3** | Añadir los estilos que faltan: `fieldLabel` (500/11.5), `inputText` (500/14.5), `chipLabel` (600/9, ls .08em), `navLabel` (600/10.5), `cardTitle` (700/15/1.2). | `app_text_styles.dart` | L188, L1103, L1099, L794, L492 |
| **F0-4** | Sustituir `headlineSmall` por `AppTextStyles.screenTitle()` en las 6 pantallas que titulan mal. | `personal_data`, `ine_capture`, `ocr_review`, `offer`, `product_selection`, `application_status` | L169, L239, L529 |
| **F0-5** | `heroTitle`: acotar el tamaño a `(h*0.05).clamp(34, 44)` para que no se deforme fuera del frame de diseño. | `welcome_screen.dart:50` | L143 (`42px` fijo en 874) |
| **F0-6** | `KrediusMark.inverted` — tile blanco radio 22%, astil+pierna `primary`, brazo `accentGreen`; + `KrediusBrand(inverted: true)`. | `kredius_mark.dart`, `kredius_brand.dart` | `brand_kredius/isotipo/kredius-isotipo-invertido.svg`; `README.md` L18; Journey L135–139 |
| **F0-7** | Curva de animación compartida: `KrediusMotion` con `spin(1100ms)`, `pulse(1600ms)`, `rise(500ms, dy 12)`. Un solo lugar, no duplicar `AnimationController` por pantalla. | `fa_design_system/lib/src/motion/kredius_motion.dart` (nuevo) | Journey L18–L20 |
| **F0-8** | Extender el guard test de compliance con los archivos nuevos (mark invertido, motion, pantallas nuevas). | `fa_shell/test/design_system_compliance_test.dart` | — |

> Los tokens de color **ya están completos y correctos** (`surfaceVariant #EBF0F7`, `accentGreen #00B894`, `divider #EDEFF3` en [app_colors.dart:28-34](packages/fa_design_system/lib/src/theme/app_colors.dart#L28-L34)). Esta fase no toca color.

---

## 4. Fase 1 — Entrada: Welcome y Login

| ID | Acción | Origen |
|---|---|---|
| **F1-1** | Welcome: cambiar el lockup a `KrediusBrand(markSize: 46, inverted: true)`. | L135–L141 |
| **F1-2** | Welcome: corregir los stats a los del diseño — `3 min / SOLICITUD`, `15 min / DEPÓSITO`, `$0 / APERTURA`. Hoy dicen "$50 mil / LÍNEA MÁX." etc. | L1059 |
| **F1-3** | Welcome: quitar el `\n` manual del titular y dejar que envuelva solo con `maxWidth` (equivalente a `text-wrap:pretty`). | L143 |
| **F1-4** | **Rediseñar Login** como héroe azul: blobs radiales, lockup invertido + botón cerrar, titular "Qué gusto verte otra vez.", inputs translúcidos (`rgba(255,255,255,.10)`, borde `.20`, 52px, radio 12), toggle "Ver/Ocultar", CTA blanco + botón Face ID 52×52, separador "O ENTRA CON", Google/Apple, y pie "¿Aún no tienes cuenta? Créala en 3 minutos". | L63–L127; estilos L1033–L1046 |
| **F1-5** | Nuevo `DsTranslucentField` en el DS (input sobre azul) — hoy `DsTextField` sólo resuelve el caso claro. | L1045 |
| **F1-6** | Face ID / social: dejarlos visibles pero deshabilitados con un `TODO` de integración, o esconderlos por `AppConfig`. **Decisión pendiente — ver §11.** | L105–L123 |

---

## 5. Fase 2 — Alta unificada: **Documentos → Datos** (el cambio de fondo)

Esta fase colapsa `ine-capture` + `ocr-review` + `personal-data` en **una sola pantalla con dos pestañas, en orden invertido respecto al prototipo**.

### Pantalla nueva: `fa_onboarding/lib/src/presentation/screens/identity_screen.dart`

| ID | Acción | Origen |
|---|---|---|
| **F2-1** | Shell de la pantalla: `DsOnboardingTopBar(step: 2, total: 4)`, título `Cuéntanos de ti`, subtítulo `Validamos tu identidad con INE y consultamos tu historial. Nada más.` | L164–L170 |
| **F2-2** | `DsSegmentedTabs` nuevo en el DS: contenedor `#E3E9F2` radio 12 padding 4, pestaña activa blanca radio 9 con sombra `0 1px 3px rgba(26,28,30,.10)`, texto 600/12.5. **Orden: `['Documentos', 'Datos']`.** | L172–L176; estilos L1061–L1064 |
| **F2-3** | Tab **Documentos** (índice 0): cuatro `DsDocumentTile` — INE frente / INE reverso / Selfie de vida / Comprobante de domicilio — con sus hints exactos y chip `LISTO` (teal) o `CAPTURAR` (azul, con borde azul en la tarjeta pendiente). | L197–L210; datos L1107–L1118 |
| **F2-4** | Tarjeta de OCR al pie de Documentos: label `LECTURA AUTOMÁTICA (OCR)` + chip `EXTRAÍDO` + el copy de resultado. Aparece sólo cuando el OCR resolvió. | L211–L217 |
| **F2-5** | Tab **Datos** (índice 1): cuatro grupos con chip de procedencia — `IDENTIDAD / INE · OCR`, `CLAVES FISCALES / VALIDADO`, `DOMICILIO / CP VALIDADO`, `CONTACTO E INGRESO / OTP VERIFICADO`. Campos e inputs 48px radio 12, borde `#C9D4E5` cuando tienen valor y `#E0E0E0` cuando están vacíos. | L178–L194; datos L1069–L1105 |
| **F2-6** | **Gating:** la pestaña Datos queda bloqueada hasta que los 4 documentos estén capturados; al completarse, se dispara `processOcr()` y se **prefill** de Datos. CTA: `Continuar a tus datos` en Documentos, `Continuar` en Datos (invertido respecto a L1066). | Regla derivada de L216 + petición del usuario |
| **F2-7** | Banner de cifrado al pie (candado sobre `primaryContainer`) + CTA de 52px. | L221–L227 |
| **F2-8** | Migrar los dropdowns de Estado/Género al look del diseño (mismo `inputStyle`, no `InputDecoration` de Material), **conservando** el `menuMaxHeight` que arregla el menú de 32 estados. | L1103; fix actual en [personal_data_screen.dart:291-296](packages/fa_onboarding/lib/src/presentation/screens/personal_data_screen.dart#L291-L296) |

### Dominio y estado

| ID | Acción | Nota |
|---|---|---|
| **F2-9** | Extender `IneImages` → `KycDocuments { frenteINE, reversoINE, selfie, comprobanteDomicilio }` con `isComplete`. | Hoy `IneImages` sólo tiene frente/reverso ([ine_images.dart](packages/fa_onboarding/lib/src/domain/entities/ine_images.dart)) |
| **F2-10** | `PersonalData` necesita `ingresoMensual` (el prototipo lo pide en CONTACTO E INGRESO, L1095) y `celular` como campo mostrado. | L1092–L1096 |
| **F2-11** | `KycProvider`: `setDocument(DocumentKind, DocumentFile)`, `documentsComplete`, y auto-OCR al completar. Rutas `/onboarding/ine-capture` y `/onboarding/ocr-review` → `redirect` a `/onboarding/identity` para no romper deep links. | [kyc_provider.dart:113-151](packages/fa_onboarding/lib/src/presentation/providers/kyc_provider.dart#L113-L151) |
| **F2-12** | **Gap de backend conocido:** hoy `/ocr/extract` recibe sólo `fileName`, no los bytes; y no hay endpoint para selfie/comprobante. Ver §11. | `docs/IMPLEMENTACION_UI.md` L139–L140 |

---

## 6. Fase 3 — Consentimiento de buró + Análisis animado

| ID | Acción | Origen |
|---|---|---|
| **F3-1** | `privacy_consent_screen`: rehacer con las **dos tarjetas de SIC** — `BC` (tile `primary`) "Buró de crédito / Historial y comportamiento de pago" y `CC` (tile `secondary`) "Círculo de crédito / Deuda vigente y capacidad de pago". | L241–L251; datos L1151–L1153 |
| **F3-2** | Caja de consentimiento tocable con tick 22×22 radio 7 que vira a `primary`, fondo `primaryContainer` cuando está activa; el CTA `Consultar y analizar` queda **deshabilitado** (gris `#E0E0E0`/`#9E9E9E`) hasta marcarla. | L252–L256; estilos L1155–L1158 |
| **F3-3** | Copy exacto: "Autorizo a Kredius a consultar mi historial crediticio durante **90 días** para evaluar esta solicitud." + "Esta consulta no baja tu score." | L240, L254 |
| **F3-4** | **Rehacer `application_status_screen` como el héroe azul de análisis**: anillo de 112px con borde `rgba(255,255,255,.16)` y `border-top #00B894` girando (`kr-spin`, 1.1s lineal infinito), titular "Analizando tu perfil", 4 pasos secuenciales, y el pie "CONEXIÓN SEGURA · CIFRADO EXTREMO A EXTREMO". | L260–L280 |
| **F3-5** | Los 4 pasos: `Verificando tu identidad` → `Consultando buró de crédito` → `Consultando círculo de crédito` → `Calculando tu capacidad de pago`. Estado hecho = punto `accentGreen` con ✓; activo = punto pulsante (`kr-pulse` 1.2s) + fondo translúcido; pendiente = texto al 42%. **El avance debe engancharse al polling real, no a un timer de 850ms** como el prototipo. | L271–L276; datos L1160–L1168; polling actual en [credit_application_provider](packages/fa_credit/lib/src/presentation/providers/credit_application_provider.dart) |
| **F3-6** | Segmentos: `BUSINESS`/`DISTRIBUTOR` terminan en "en revisión" (`COMMITTEE_REVIEW`/`UNDER_MANUAL_REVIEW`), no en aprobado. | `docs/IMPLEMENTACION_UI.md` L120–L122 |

---

## 7. Fase 4 — Aprobado → Preofertas → Cómo solicitar → Configurador

| ID | Acción | Origen |
|---|---|---|
| **F4-1** | **Aprobado**: header azul a sangre con radio inferior 28, badge pulsante `SÍ CUMPLES LOS CRITERIOS`, monto autorizado 46px, y la fila `PERFIL` / `CAPACIDAD / MES`. Cuerpo: "Esto fue lo que revisamos" + 4 criterios con ✓ teal. CTA `Ver mis preofertas`. | L282–L315; criterios L1170–L1176 |
| **F4-2** | **Preofertas**: carrusel horizontal con `scroll-snap` — usar **`DsProductCarouselCard`, que ya existe en el DS y hoy sólo se usa como home-card**. Tarjetas 262 de ancho, mín. 250 de alto, borde 2px `primary` cuando está seleccionada + sombra `0 12px 26px rgba(13,71,161,.16)`. Producto no disponible → `opacity .55`, no tocable. | L317–L353; estilos L1178–L1192 |
| **F4-3** | Dots del carrusel con ancho animado (6 → 18, 200ms). | L349–L353; L1192 |
| **F4-4** | Ficha "CÓMO FUNCIONA {producto}" con los 3 specs (Tipo / Plazos / Pago) en una grilla de 3 con separadores de 1px. | L355–L366; L1193–L1197 |
| **F4-5** | Los 6 productos y sus badges (`RECOMENDADO` teal, `PASA A COMITÉ` ámbar, `AUTORIZADO` azul, `NO DISPONIBLE` gris) deben mapearse desde `CreditProduct` del BFF, **no hardcodearse** como en el prototipo. Chips de segmento `B2C`/`B2B`/`B2B2C` desde `targetAudience`. | Prototipo L858–L879 (referencia de contenido) |
| **F4-6** | **Pantalla nueva "Cómo solicitar"**: tarjeta azul con línea disponible + los 3 pasos con timeline (círculo `primaryContainer` + línea de 2px). CTA `Aceptar y configurar`. | L372–L399; pasos L1200–L1204 |
| **F4-7** | **Configurador**: agregar el header `Arma tu préstamo`, el bloque "CUÁNTO NECESITAS" con monto 42px, el stepper de plazo con dots animados, y el bloque azul con "Pagas cada mes / CADA día 5 / Total a pagar / Intereses incluidos" + la nota de primer pago. Reusa `DsAmountSlider`, `DsTermStepper`, `DsPaymentSummaryCard`. | L401–L463; cálculo L907–L913; estilos L1206–L1214 |
| **F4-8** | Estilar el slider igual al prototipo: track 8px `#D6E4FF`, thumb 30px blanco con borde 3px `primary` y sombra. | Journey L21–L23 |
| **F4-9** | **Regla dura:** nunca mostrar tasa ni CAT en el configurador — sólo pago, total e intereses. | `docs/IMPLEMENTACION_UI.md` L105–L107 |
| **F4-10** | Productos revolventes (`requiresAmount == false`) se saltan el configurador y van directo a contrato. | `docs/IMPLEMENTACION_UI.md` L109–L110 |

---

## 8. Fase 5 — Resumen → Firma OTP → Desembolso

| ID | Acción | Origen |
|---|---|---|
| **F5-1** | **Resumen**: tarjeta de 6 filas (Producto, Monto, Plazo, Pago mensual, Intereses, Total) con las 3 últimas en 16px y el total en `primary`. | L472–L479; L1216–L1224 |
| **F5-2** | Bloque "DÓNDE TE DEPOSITAMOS" con segmented control `Ya tengo cuenta` / `No tengo cuenta`. Con cuenta: fila `•••• 4821 · BBVA` + chip `VERIFICADA`. Sin cuenta: input de CLABE con validación de 18 dígitos que vira el borde a teal, más la tarjeta "Ábrete una cuenta Kredius". | L480–L513; L1225–L1234 |
| **F5-3** | Checkbox de contrato con el mismo patrón de tick que el consentimiento; CTA `Firmar solicitud` deshabilitado hasta aceptarlo. | L514–L518; L1236–L1239 |
| **F5-4** | **Separar la firma en su propia pantalla**: 6 cajas OTP de 62px (borde 2px `primary` en la activa) + **teclado numérico propio de 3 columnas** con `⌫`. Al llegar a 6 dígitos, navega sola tras 380ms. | L522–L543; L1241–L1255 |
| **F5-5** | Reemplazar el `signatureProof: 'otp-<timestamp>'` sintético de [contract_sign_screen.dart:172](packages/fa_credit/lib/src/presentation/screens/contract_sign_screen.dart#L172) por el OTP real capturado. **Requiere endpoint — ver §11.** | — |
| **F5-6** | **Pantalla nueva de desembolso**: héroe azul, blob verde centrado, check de 94px sobre `accentGreen` con entrada `kr-rise` (500ms, dy 12), copy "Listo, el dinero va en camino", tarjeta translúcida de 3 filas, CTA blanco `Ir a mi crédito`. | L545–L566; filas L1257–L1261 |

---

## 9. Fase 6 — Home logueado, Perfil y Contraoferta

| ID | Acción | Origen |
|---|---|---|
| **F6-1** | **Header de home**: fondo claro (no azul), "Hola," + nombre 21px w800 con chevron, campana con punto ámbar y avatar circular `primary` con iniciales. Hoy el header es azul con el wordmark y un botón de logout ([home_screen.dart:178-246](packages/fa_shell/lib/src/home/home_screen.dart#L178-L246)). | L571–L586 |
| **F6-2** | **Bottom nav**: 3 tabs (Inicio / Créditos / Movimientos), 58px, radio 14, activo con fondo `surfaceVariant` y color `primary`; inactivo `#9AA2B1`. Sustituye al `NavigationBar` de Material. | L791–L804; estilo L920 |
| **F6-3** | Tab Resumen: `DsWalletCard` a pantalla completa (saldo, `•••• 4821`, CLABE, 3 acciones), tarjeta de crédito activo con barra de progreso de pagos y grilla de 4 datos, y el banner `Todavía tienes línea`. | L589–L643 |
| **F6-4** | Tab Créditos: secciones VIGENTES / HISTÓRICO, filas expandibles; para `DISTRIBUTOR_LINE` el bloque **DISPOSICIÓN A TERCERO** con beneficiario, referencia SPEI y comisión; label de tabla variable según tipo de línea. | L646–L708; datos L954–L997 |
| **F6-5** | Tab Movimientos: tarjeta de saldo, chips de filtro (`Todos/Disposiciones/Pagos/Transferencias`) con scroll horizontal, y agrupación por día con total. | L710–L752; L999–L1022 |
| **F6-6** | Perfil (push, **no** tab): 4 grupos con chip de procedencia + histórico de contratos PDF con chip `VIGENTE`/`LIQUIDADO`. | L754–L788; L1120–L1149, L1023–L1031 |
| **F6-7** | **Contraoferta**: header azul con badge ámbar, tarjeta con borde 2px `primary`, "Qué levanta tu monto" (3 tips con punto ámbar), CTA `Aceptar $X` y `Avísame en 3 meses`. | L807–L836; tips L1263–L1267 |

---

## 10. Catálogo de animaciones a implementar

Todas salen de `Kredius Journey.dc.html` L18–L20 y se centralizan en `KrediusMotion` (F0-7).

| Nombre | Definición | Dónde |
|---|---|---|
| `kr-spin` | `rotate(360deg)`, 1.1s lineal, infinito | Anillo de análisis (L264) |
| `kr-pulse` | `opacity .4→1`, `scale .9→1`, ease-in-out | Paso activo del análisis (1.2s, L1165) y badge "SÍ CUMPLES" (1.6s, L287) |
| `kr-rise` | `opacity 0→1` + `translateY 12px→0`, 500ms ease, `both` | Bloque de éxito del desembolso (L549) |
| dot-width | `width 6→18px`, transición 200ms | Dots del carrusel (L1192) y del stepper de plazo (L1214) |
| scroll-snap | `scroll-snap-type: x mandatory` + `snap-align: center` | Carrusel de preofertas (L326, L1186) → `PageScrollPhysics` |
| progreso | ancho del track del `DsOnboardingTopBar` | Ya implementado; sólo animar el cambio de paso |

---

## 11. Gaps y decisiones que hay que resolver antes de codificar

1. **Bytes del documento en OCR.** `/ocr/extract` hoy sólo manda `fileName`. Sin esto, el prefill de la pestaña Datos no puede ser real y el mock queda como única ruta verde. *(Ya listado como pendiente abierto en `docs/IMPLEMENTACION_UI.md` L139.)*
2. **Selfie de vida y comprobante de domicilio no tienen endpoint** en el BFF. Hay que definir si van en `/kyc/submit` como adjuntos o si necesitan un `/documents` propio.
3. **Firma con OTP real** (`.../contract/sign`): falta el par enviar-código / verificar-firma; hoy se manda un proof sintético.
4. **Pantalla de beneficiario para `THIRD_PARTY_CREDIT`** (línea de distribuidor) no existe en la app y el prototipo la asume. *(Pendiente abierto, `IMPLEMENTACION_UI.md` L112–L114.)*
5. **Face ID y login social** (L105–L123): el prototipo los dibuja pero no hay integración. Propuesta: renderizarlos deshabilitados detrás de un flag de `AppConfig` en vez de omitirlos, para no perder la fidelidad visual.
6. **Los 6 productos del prototipo son datos de maqueta** (L858–L879). La app debe leerlos de `GET /credit/products`; si el catálogo real trae menos productos o distintos badges, manda el backend.
7. **El welcome de la app entra a `/onboarding/privacy`**, el prototipo entra directo a Datos. Se mantiene el aviso de privacidad de la app (requisito legal), y el prototipo se ajusta a la app en este punto — no al revés.

---

## 12. Pruebas

| Nivel | Qué |
|---|---|
| Guard | Extender `design_system_compliance_test.dart` con las pantallas nuevas (identity, análisis, firma, desembolso, cómo-solicitar, contraoferta) y con el mark invertido. |
| Widget | `KrediusMark.inverted` pinta tile blanco + astil `primary` + brazo `accentGreen`; `DsSegmentedTabs` respeta el orden Documentos→Datos; el gating de la pestaña Datos. |
| Golden | Welcome, Login, Identity (ambas pestañas), Análisis, Aprobado, Configurador, Desembolso, Home. A 402×874 para comparar 1:1 contra el prototipo. |
| E2E | `create_account_e2e_test.dart` **se rompe con esta refactorización**: hoy espera `'Frente de INE'` (L121), `'Confirmar datos'` (L149) y `'Datos personales'` (L166) como pantallas separadas. Hay que reescribir esos tres pasos como una sola pantalla con dos pestañas. |
| E2E | Nuevo `credit_journey_e2e_test.dart` que cubra buró → análisis → aprobado → preofertas → cómo → configurador → resumen → firma → desembolso → home. |
| Recordatorio | Cualquier `Scrollable` (incl. `ListView(children:)`) requiere scroll real con `dragUntilVisible` para alcanzar items fuera del viewport — aplica al carrusel de preofertas y a la pestaña Datos, que es larga. |

---

## 13. Orden de ejecución sugerido

```
F0 (fundaciones: fuente, tracking, mark invertido, motion)   ← bloquea todo
 ├── F1 (welcome + login)              — cierra los defectos 1.1 y 1.2
 ├── F2 (identity: documentos → datos) — cierra los defectos 1.3 y 1.4
 ├── F3 (buró + análisis animado)
 ├── F4 (aprobado → preofertas → cómo → configurador)
 ├── F5 (resumen → firma OTP → desembolso)
 └── F6 (home 3 tabs, perfil, contraoferta)
```

F0 primero porque toca `AppTextStyles` y por lo tanto todas las pantallas. F1 y F2 son los que resuelven lo que reportaste y se pueden entregar juntos como primer corte visible. F3–F6 dependen del backend descrito en §11 sólo para la ruta real; contra el flavor `mock` se pueden construir y validar completos.

---

## 14. Lo implementado y lo que quedó fuera

### Piezas nuevas del design system

| Archivo | Qué resuelve |
|---|---|
| `theme/ds_scale.dart` | **Escalado responsivo**: traduce los px del lienzo 402×874 a cualquier pantalla con factores acotados distintos para ancho (0.86–1.15), alto (0.90–1.12) y tipografía (0.92–1.08). Expone los tres márgenes del diseño (22 / 26 / 20), `topGap` (descuenta la status bar que ya consumió `SafeArea`), `bottomGap` (respeta el home indicator) y `isCompact` / `isShort` / `isExpanded`. `DsResponsiveBody` centra y acota el journey en tablet. |
| `motion/kredius_motion.dart` | `KrRise`, `KrPulse`, `KrSpinRing`, `KrDot` — los tres keyframes del prototipo y los dots de ancho animado. Todos respetan "Reducir movimiento" del sistema. |
| `widgets/ds_hero_scaffold.dart` | El héroe azul con blobs, scrollable en pantallas cortas. `DsWhiteCta` y `DsGlassButton`. |
| `widgets/ds_segmented_tabs.dart` | El segmented control, con soporte de pestañas bloqueadas. |
| `widgets/ds_status_chip.dart` | `DsStatusChip` (4 tonos) y `DsHeroChip`. |
| `widgets/ds_document_tile.dart` | Fila de captura con miniatura real de lo capturado. |
| `widgets/ds_field_group.dart` | Grupo con chip de procedencia + `DsDetailCard`. |
| `widgets/ds_consent_check.dart` | Caja de consentimiento (texto plano o contenido enriquecido) + `DsInfoBanner`. |
| `widgets/ds_translucent_field.dart` | `DsTranslucentField` (input sobre azul) y `DsFormField` (input del alta, con el borde que vira cuando tiene valor). |

### Decisiones que se apartaron del prototipo, y por qué

1. **Orden de pestañas invertido** (Documentos → Datos), como pediste. El propio prototipo lo respalda en L216.
2. **`headlineSmall` se redefinió a 27/w700/−1.1** en el `TextTheme` en vez de cambiar seis pantallas una por una: así cualquier pantalla que use el estilo de Material ya cae en el H2 del diseño.
3. **Los pasos del análisis no mienten.** Los tres primeros avanzan con coreografía temporizada; el cuarto se queda activo hasta que llega la decisión real del polling.
4. **Los criterios del "Aprobado" no inventan valores.** El prototipo muestra "Sin atrasos / 7 años / 18%"; el BFF todavía no devuelve el desglose del scoring, así que se listan las dimensiones evaluadas sin cifras hasta que el endpoint las exponga.
5. **Aprobado y "Cómo solicitar" se fusionaron** en una pantalla: en la app el producto se elige antes (lo exige el contrato del BFF), así que al llegar ahí ya hay oferta concreta y el salto de pantalla no aportaba.
6. **El logout salió del header del home** (el diseño reserva ese espacio para nombre + campana + avatar). Sigue disponible en el perfil, al que se llega tocando el avatar.
7. **La solicitud se crea al autorizar el buró**, no al salir del configurador — que es el momento en que de verdad se consulta a las SIC.

### Segunda pasada — lo que salió de correr la app en simulador

Correr el journey de verdad en un iPhone 16 Pro destapó cosas que ni el analyze
ni los tests unitarios ven:

| Hallazgo | Arreglo |
|---|---|
| **La miniatura del documento tumbaba el frame.** `DecorationImage` no tiene forma de degradar cuando los bytes no son decodificables (un HEIC sin soporte, un archivo truncado, el stub de un test) — lanza *"Could not decompress image"* y se lleva el render. | `DsDocumentTile` pinta la miniatura con `Image` + `errorBuilder`, que cae al icono. |
| **La numeración de pasos no cuadraba**: consentimiento, celular y código decían todos "1/4", identidad "2/4" y contraseña "4/4". La barra de progreso no comunicaba nada. | `AltaStep` (nuevo, en `fa_onboarding/lib/src/presentation/alta_step.dart`) define los 5 pasos en un solo lugar y todas las pantallas lo consumen. |
| **Celular y OTP se habían quedado fuera del rediseño** — seguían con `Gap(h*…)`, iconos sueltos y `DsTextField`. | Reescritas con `DsScale` + `DsFormField`, título 27/700 y el celular enmascarado (`55 •• •• 60 01`) igual que la firma del prototipo. La pista del código demo ahora sólo aparece en flavor `mock`. |
| **El OCR se leía como un resumen suelto**, al final de los cuatro documentos. | La pestaña Documentos ahora son dos grupos: **1 · TU IDENTIFICACIÓN** (INE frente + reverso + tarjeta de OCR pegada debajo) y **2 · PRUEBA DE VIDA Y DOMICILIO**. La secuencia INE → extrae → prellena queda explícita, y hay un test que verifica ese orden por posición en pantalla. |
| **Los campos del design system no eran direccionables**, y el helper de tests los buscaba por forma del árbol — un finder atado a una instancia de `Column` que moría en el siguiente rebuild (*"Bad state: No element"*). | `DsFormField`, `DsTranslucentField` y los selectores llevan `ValueKey(dsFieldKey(label))`. El helper `enterField` y el nuevo `selectDropdown` los buscan por esa key. |
| **`selectDropdown` elegía "el primer selector pendiente"**, criterio que deja de ser determinista en cuanto el OCR prellena algunos. | Ahora se direcciona por etiqueta, y si ya tiene valor no hace nada. |

### Tercera pasada — el bundle de diseño cambió (re-export del 2026-08-09 09:47)

El handoff se volvió a exportar y el `Kredius Journey.dc.html` pasó de 101 KB a
114 KB. **El flujo de crédito (pantallas 5–14) no cambió** — todas sus cadenas
siguen idénticas. El cambio es completo en el alta: el prototipo ahora **incluye
las tres pantallas que antes había que improvisar** y las ordena distinto.

| Antes (improvisado) | Ahora (del prototipo) |
|---|---|
| privacidad(1) → celular(2) → OTP(3) | **celular(1) → privacidad(2) → OTP(3)** — primero dices a dónde mandarte el código, luego autorizas, porque *la autorización se firma con ese código* (L215, L364) |
| Celular: sólo el número | Celular + **correo** en una tarjeta blanca, con prefijo `+52` con chevron y dos notas de confianza con palomita teal (L172–L196) |
| Consentimiento: 2 casillas de texto legal | **Documentos legales tocables** con su tiempo de lectura, tarjeta **SE CONSULTAN** nombrando BC y CC, y **tres** consentimientos con etiqueta `OBLIGATORIO`/`OPCIONAL` — el tercero es marketing y es opcional (L324–L362) |
| OTP: teclado del sistema | **Teclado propio** + tile de icono + "Borrar" + banner de constancia legal (fecha, hora e IP) (L202–L239) |
| Pestañas "Documentos" / "Datos" | `1 · Documentos` / `2 · Verifica tus datos`, con título, subtítulo y CTA que cambian por pestaña: *"Sube tus documentos" → "Leer mis documentos"*, *"Confirma que esté bien" → "Todo está correcto"* (L1226–L1236) |

**La inversión de pestañas que pediste quedó confirmada por el propio diseño**:
en el prototipo nuevo `dataStepDocs` es el estado por defecto (L279) y las
etiquetas van numeradas 1 y 2.

Piezas nuevas que salieron de esto:
- `DsPinCells` + `DsPinKeypad` en el design system — el journey tiene **dos**
  códigos (OTP del alta y firma del contrato) con el mismo teclado propio; la
  firma dejó su copia local y ahora ambos usan el mismo widget.
- `DsFormField` gana `showLabel`, `height` y `fillColor`: la tarjeta de contacto
  pinta un solo rótulo para prefijo+input, y sus campos van sobre blanco con el
  gris frío `AppColors.fieldFillOnCard`.

### Cuarta pasada — home, notificaciones y rechazo (bundle del 2026-08-09 11:04)

Tercer re-export del handoff: el Journey pasó de 114 KB a 134 KB. **El
otorgamiento (pantallas 5–14) no cambió**; lo nuevo está en el post-alta.

| Novedad del diseño | Qué se hizo |
|---|---|
| **El home tiene tres estados** (L699–L795): sin crédito, un crédito, varios | `credit_module.buildHomeCard` los implementa: `DsEmptyStateCard`, la tarjeta detallada de un solo crédito, y el carrusel horizontal `DsActiveCreditCard` con dots |
| **Tarjeta de oportunidades** siempre presente, sólo cambia el copy (L1400) | `DsPromoCard` — azul con blob verde, debajo del bloque de crédito en los tres estados |
| **Notificaciones** es pantalla nueva (L1016–L1066) | Reescrita: chips de filtro, agrupado por HOY/AYER/ESTA SEMANA, punto ámbar de no leída, icono y chip en el tono de la categoría, y acceso a preferencias |
| **Rechazo** es pantalla nueva (L960–L1013) | `rejected_screen.dart`: header azul, el porqué, las tres palancas numeradas y cuándo se puede volver. El análisis redirige ahí en vez de mostrar un mensaje seco |
| **El nav cambió**: Movimientos salió, entró Oportunidades (L943–L954) | Nav actualizado. "Oportunidades" **navega** al catálogo en vez de ser pestaña, igual que `goOffers` en el prototipo |

**Fuera de alcance por indicación explícita**: el tab de Créditos (pasará a ser
historial de movimientos) y el de Oportunidades como pestaña.

**Decisión que conviene revisar**: el diseño quita la tarjeta de wallet del home.
Se mantuvo porque, al salir Movimientos del nav, es el único acceso que queda al
saldo de la cuenta y a Enviar/Historial. Quitarla dejaría esas funciones sin
entrada.

#### El análisis se movió al alta

Cambio de flujo pedido por el usuario: **el análisis corre al crear la cuenta**,
no más tarde. Al salir de la contraseña con "Crear cuenta" aparece
`account_analysis_screen.dart` con los cuatro pasos —*creando tu cuenta,
consultando buró, consultando círculo, verificando tu capacidad de pago*— y de
ese análisis salen las ofertas.

| Antes | Ahora |
|---|---|
| contraseña → pantalla de éxito → home → catálogo plano | contraseña → **análisis** → **oportunidades clasificadas** |
| Todos los productos se mostraban igual | Dos secciones: **APROBADAS PARA TI** (`AUTO_APPROVED`, se toman hoy) y **PUEDES SOLICITARLAS** (comité o más información) |

- El primer paso del análisis es **real** (`/kyc/submit` + `/auth/register`): no
  se marca hecho hasta que responde, y si falla la pantalla se queda y ofrece
  reintentar sin perder lo capturado. Los otros tres ocurren del lado del
  servidor durante el scoring y avanzan con cadencia fija.
- La vista del análisis se extrajo al design system (`DsAnalysisView`) porque
  ahora la usan dos momentos: el alta y la solicitud de un crédito.
- El mock de precalificación deja de aprobar todo: los productos de persona se
  autoaprueban y los de negocio pasan a comité, para que las dos secciones
  tengan contenido.

#### La tarjeta de débito salió del home

`WalletModule.buildHomeCard` devuelve `null`. El producto se enfoca en el
crédito y el resumen queda para el estado del crédito y las oportunidades, como
manda el diseño. El saldo y los movimientos siguen accesibles desde el
historial.

#### El alta se bifurca: uso propio o colocación

`CreditPurpose` (en `fa_core`, porque lo elige el alta y lo consumen crédito y
shell) gobierna todo lo que sigue. Es el **paso 1 de 6**, antes del celular:
preguntarlo después obligaría a rehacer la evaluación.

| | **Para mí** | **Para colocar con mis clientes** |
|---|---|---|
| Productos que se evalúan | `B2C` | `B2B`, `B2B2C` |
| Tras el análisis | Oportunidades, con líneas ya aprobadas | Home **en revisión** — el comité decide |
| Si aparece algo aprobado | Se toma y se firma | Igual: se toma y se firma |
| Home | Pago de los préstamos | Cartera: colocado, cobranza del mes, disponible |

La regla es una sola —`approvedProducts.isNotEmpty ? oportunidades : home`— y
cubre los dos enunciados: el distribuidor cae normalmente en revisión, pero si
el scoring le abre un producto configurado, entra al mismo embudo y firma.

Cuando la solicitud queda en revisión, el home **no** muestra la tarjeta de
oportunidades: empujar a un catálogo que todavía no se puede contratar sería
enseñar una puerta cerrada.

#### Contrato en PDF y firma autógrafa

Antes se "aceptaba el contrato" con una casilla y no existía documento alguno.
Ahora, entre el resumen y el código:

- `ContractPdfBuilder` arma el PDF con el clausulado que corresponde al
  producto — **crédito simple** (a plazo), **apertura en cuenta corriente**
  (revolvente) o **línea para colocación** (distribuidor, que añade las
  cláusulas de disposición a terceros y la comisión del titular). Un producto
  nuevo no exige una pantalla nueva: sólo entra por el mismo builder.
- `ContractReviewScreen` lo renderiza para leerlo y descargarlo.
- `DsSignaturePad` captura la firma autógrafa y **se estampa sobre el documento**
  (PNG a 3× para que no salga pixelada), antes de firmar con el código de un
  solo uso. El clausulado de firma electrónica cita el artículo 89 del Código de
  Comercio y la constancia de fecha, hora e IP.

#### Lo que ya se preguntó no se vuelve a preguntar

En "Verifica tus datos", el celular y el correo aparecían **otra vez** como
campos vacíos. Ya se dieron en el paso 3 y el celular quedó verificado con el
código: pedirlos de nuevo hace pensar que algo se perdió, y dejarlos editables
invita a cambiar justo el número que se acaba de verificar. `DsReadonlyField`
los muestra como dato, con su chip `VERIFICADO` y un "Cambiar" que lleva al paso
donde la corrección puede volver a validarse.

#### Los 32 estados, alcanzables

La lista siempre tuvo los 32 (Sonora y Sinaloa incluidos): el problema era
llegar a ellos. Un `DropdownButtonFormField` acotado a ~40% de pantalla muestra
siete opciones y obliga a arrastrar a ciegas hasta la #25. `DsPickerField` los
abre en una hoja con **buscador que ignora acentos** — se escribe "son" y sale
Sonora.

#### Devengo y notificaciones en vivo (flavor mock)

Para poder *ver* moverse los valores, el mock dejó de responder ceros:

- `CreditMockInterceptor` recuerda lo firmado y **devenga interés** con un reloj
  acelerado (un segundo real ≈ un día). Cada refresco del home recalcula el
  saldo. También responde ya los endpoints de oferta, aceptación, contrato y
  firma, que antes caían al genérico `{success:true}` y dejaban el flujo colgado
  en el análisis.
- El mock de crédito **emite eventos** (`onEvent`) y el shell los traduce a
  notificaciones vía `NotificationsMockInterceptor.push`. Los módulos siguen sin
  conocerse: el cableado vive en `shell_injection`, que ya conoce a ambos.
- `CreditAccount` gana `paymentsMade` y `principalPaid` como **opcionales** —
  cuando el BFF no los manda, la UI muestra "—" y una barra indeterminada en vez
  de fingir un 0%.

### Quinta pasada — el orden del alta y el cierre del otorgamiento

#### Permiso antes que datos

El alta se reordenó a **privacidad → propósito → celular+correo → código →
documentos**. La regla es que nada se pide antes de tener permiso para pedirlo:
capturar el celular y después preguntar si se puede guardar es pedir perdón en
vez de permiso. El código sale al continuar desde el celular, sin pantallas de
por medio que enfríen la espera del SMS, y sigue firmando la autorización del
paso 1.

#### Un análisis, un contador

"Crear cuenta" mostraba el análisis **dos veces**: la pantalla del alta cerraba
sus cuatro pasos y la del módulo de crédito volvía a arrancar en el primero.
Ahora el alta cierra sólo el suyo —crear la cuenta, que es lo único que hace— y
`/credit/after-analysis` retoma en el segundo. Siguen siendo dos pantallas
porque son dos módulos, pero el contador nunca retrocede.

#### La preoferta manda sobre el catálogo

`PrequalifiedProduct` gana un bloque `preOffer`: monto, plazo y tasa que el
scoring **autorizó a esta persona**, no el rango comercial del producto.
`selectPrequalifiedProduct` los deja encima del producto (`item.offer`), así que
el slider no puede llegar a un monto que después se recorte en la resolución. El
mock los deriva del riesgo: bajo abre el tope completo, medio recorta a 60% del
monto y 75% del plazo con cuatro puntos de sobretasa.

#### Se otorga, no se vuelve a evaluar

"Revisar solicitud" ya no manda al consentimiento de buró: la autorización se
firmó al abrir el alta y la consulta se hizo en ese análisis. Repetirla dejaría
una **segunda huella de consulta** en el historial del cliente por un crédito
que su score ya tenía preaprobado. La resolución cambió sus pasos —confirmar
monto y plazo, aplicar las condiciones de la preoferta, preparar el contrato— y
su copy: *"Tu solicitud está casi lista"*.

#### El calendario, visible

El contrato declara la tabla de amortización "parte integrante" y la casilla
pedía aceptarla, pero no se mostraba en ningún lado: era un anexo invisible.
Ahora `AmortizationPdfBuilder` la imprime cuota por cuota —vencimiento, pago,
interés, capital y saldo— y se abre con `DsDocumentLink` desde el configurador y
desde la firma. El resumen de pago además dice **cuántas cuotas son y cuándo
vence la primera**: un importe suelto no es el compromiso.

#### El teclado que ya existe

Las dos pantallas de código —la del alta y la de la firma— dibujaban su propio
teclado numérico **encima del que el sistema ya abre**. El código llega por SMS
y el teclado del sistema ofrece autorrellenarlo (`AutofillHints.oneTimeCode`),
cosa que un teclado pintado no puede dar; tener los dos obliga a teclear dos
veces lo mismo.

`DsPinInput` conserva las cajas del diseño sobre un campo real invisible, así
que el pegado, el autorrelleno y el teclado que el usuario ya sabe usar
funcionan. `DsPinKeypad` quedó sin usuarios y se eliminó: es la pieza del
prototipo que no sobrevivió al contacto con un teléfono de verdad.

#### Dos defectos que salieron al probar

Ninguno de los dos se veía en pantalla hasta que se abrió el documento:

- **Los PDFs usaban Helvetica**, que no tiene soporte Unicode: "amortización",
  "interés" y "solicitó" salían con los acentos rotos. `PdfFonts` embebe Inter
  —la misma familia de la app— y cachea el tema, porque el contrato se
  regenera en cada trazo del pad de firma.
- **La CLABE se enmascaraba con "•"**, un glifo que la fuente base del PDF no
  dibuja: la cuenta de abono del contrato salía en blanco. Ahora usa asteriscos.

Y uno que salió de escribir los tests del mock: la línea revolvente no publica
plazo en el catálogo, y la preoferta le **inventaba uno** (`?? 12`). Un
configurador pidiendo elegir mensualidades de una línea que no las tiene. Ahora
la preoferta sólo acota lo que el catálogo define.

#### El home muestra el avance, y deja pagar

La tarjeta dice **"PAGO 3 DE 12"**, cuánto vence y **en qué fecha**, cuántos
pagos faltan y los intereses devengados sobre el capital vivo. "Pagar" abre una
hoja de confirmación —que enseña el saldo antes y después— y aplica el pago de
verdad, releyendo del BFF: el descuento local no sabe cuántas mensualidades van
ni cuándo vence la siguiente, que es justo lo que la tarjeta muestra. Liquidar
genera su propio aviso.

### Sexta pasada — mora, avance de pagos y conexión real

#### "Pago 3 de 12", no "pagos restantes"

En la grilla de datos, saber cuántos faltan es menos útil que saber en cuál vas
— es lo que se pregunta al ver que el saldo se movió. La franja de avance y el
dato dicen ahora lo mismo, sin contradecirse.

#### Devengar sin pagar no es estar al corriente

El chip decía "AL CORRIENTE" mientras el interés corría sobre una mensualidad
ya vencida. Ahora dice **EN MORA**, con los días (`EN MORA · 6 DÍAS`), y la
línea de abajo cambia de "tu próximo pago vence el…" a "tu pago **venció** el…
llevas 6 días de atraso", en rojo. "Con atraso" suaviza algo que en cobranza no
se suaviza.

**Quién decide la mora.** El backend, no el reloj del teléfono: dependen de días
de gracia, festivos y de cuándo se aplicó el pago, que la app no sabe.
`CreditAccount.isOverdue` prefiere `daysPastDue` de cartera, cae al `status`, y
sólo como último recurso compara contra la fecha. Un crédito liquidado nunca
está en mora, aunque el vencimiento quedara atrás — cobrarle mora a quien ya
pagó todo es un error caro.

#### Endpoints de soporte, iguales en mock y conectado

El BFF ya expone `/internal/test-support/*` (devengo diario, corte, vencidas,
mover la fecha de una mensualidad), apagados por configuración fuera de local.
El mock los **espeja con los mismos paths**, así que el mismo guion de prueba
sirve contra el mock y contra fintech-services sin cambiar una línea. Es lo que
permite ver la mora sin esperar 30 días.

El reloj de demo bajó a **un día cada dos segundos**: el devengo se sigue viendo
moverse, pero una corrida completa ya no cruza sola el primer vencimiento. Que
el crédito caiga en mora es una decisión de la prueba, no un accidente del
cronómetro. Y las pruebas unitarias lo **congelan** (`daysPerRealSecond = 0`):
con el reloj corriendo, dos llamadas seguidas caen en días distintos y cualquier
aserción sobre días de atraso es una carrera contra el segundero.

#### Cada pago avisa

El journey ahora entra a notificaciones **después de cada uno de los 12 pagos**
y verifica que llegó su aviso. Aplicar un cobro sin avisar deja al usuario sin
constancia de que su dinero entró.

### Verificación de la quinta pasada

- `flutter analyze` limpio en los 9 paquetes. **115 tests unitarios**: 61 en
  `fa_shell`, 34 en `fa_credit`, 17 en `fa_design_system`, 3 en `fa_auth`.
  Nuevos en `fa_credit`: calendario de pagos (fechas por calendario, saldo que
  cierra en cero), preoferta (recorte sobre el catálogo, parseo del DTO) y el
  mock (tope en escalón del slider, más riesgo → menos monto y más tasa, pagos
  que liquidan sin pasarse, vencimiento que se recorre).
- **Journey de demostración en verde, 4:13**: alta → oportunidades →
  configurador → tabla de amortización → resolución → contrato PDF + firma
  autógrafa → código → desembolso → devengo (`$103,222 → $106,099`) → **12
  pagos hasta liquidar** (`PAGO 1 DE 12` … `PAGO 12 DE 12` → `LIQUIDADO`) →
  notificaciones, incluidos los avisos de liquidación y de la nueva línea que
  abre el buen historial.
- `create_account_e2e_test.dart`: 12/12, con el caso del distribuidor.

#### Tres defectos que sólo aparecieron corriéndolo

1. **El contador del home se apagaba al pagar.** `_copyWith` no arrastraba
   `paymentsMade` ni `principalPaid`, así que la proyección local del pago los
   perdía y la tarjeta caía a "PLAN A PLAZO" — sin contador ni barra— justo en
   el momento en que se mira para comprobar que el pago entró.
2. **El home releía la lista equivocada.** El pago recargaba `accounts` (que
   alimenta el tab de Créditos) mientras la tarjeta lee `credit`. Se quedaba con
   la proyección optimista, que descuenta el pago completo del saldo sin saber
   cuánto es interés, y daba el crédito por liquidado **una mensualidad antes**.
3. **El aviso de liquidación no llegaba.** El evento usaba una condición propia
   en vez de la que reporta la cuenta. Ahora `_liquidado` es una sola definición
   para ambos.

### Verificación

- `flutter analyze` limpio en los 9 paquetes; 47 tests en `fa_shell`, 17 en
  `fa_design_system`, más `fa_auth` y `fa_credit`.
- **Journey de demostración en simulador, en verde**: `credit_journey_showcase_test.dart`
  recorre alta → home sin créditos → otorgamiento → desembolso → home con crédito
  → notificaciones. Verifica que el saldo **devenga** entre refrescos
  (`$81,227 → $82,762` en la corrida grabada) y que los avisos del desembolso
  llegan. Grabación en `kredius_journey_otorgamiento.mp4`.
- **E2E en simulador (iPhone 16 Pro): 11/11 en verde**, `create_account_e2e_test.dart`,
  flavor mock, 3:43. Grabación en `kredius_e2e_alta.mp4`.
- Verificado por fotograma en el video: celular **1/5**, datos **4/5** con las
  pestañas numeradas, y el celular/correo capturados en el paso 1 llegando ya
  prellenados a "CONTACTO E INGRESO" con su chip `OTP VERIFICADO`.
- **41 tests** en `fa_shell` (40 de compliance del design system + smoke), **17** en `fa_design_system`, más los de `fa_auth` y `fa_credit`. Todos en verde.
- `test/widget_test.dart` monta la app real en flavor mock y recorre welcome → login → privacy → OTP → identidad, verificando el logo invertido, los stats del prototipo, el orden Documentos→Datos y el bloqueo de la pestaña Datos. Se ejecuta a 402×874, en iPhone SE (320×568) y en tablet (1024×1366).
- `flutter build bundle` confirma que los cinco pesos de Inter se empaquetan bajo `packages/fa_design_system/assets/fonts/`.

### Pendiente

| Qué | Por qué |
|---|---|
| Contenido profundo de los tabs Créditos / Movimientos / Perfil (F6-4, F6-5, F6-6) | El envoltorio (header, bottom nav) ya es el del diseño; el interior de esas tres pantallas sigue siendo el anterior. Falta el bloque "disposición a tercero" del B2B2C, los chips de filtro de movimientos y el histórico de contratos PDF. |
| Los 7 puntos de §11 | Siguen abiertos: son gaps de backend (bytes del OCR, endpoints de selfie/comprobante, firma con OTP real, pantalla de beneficiario) o decisiones de producto (Face ID y social hoy quedan visibles pero avisan "muy pronto"). |
| Golden tests | El smoke test cubre estructura y layout; comparar píxeles 1:1 contra el prototipo requiere generar los baselines. |
