# fa_design_system

Los tokens y los componentes con los que se pinta el journey. 49 archivos, cero
lógica de negocio: nada de aquí sabe qué es un crédito.

La fuente de verdad es `docs/design/Kredius Journey App.dc.html`, el prototipo
exportado desde Claude Design. **186 comentarios del código lo citan por número
de línea** (`Journey L2095`), así que si se vuelve a exportar hay que revisar
esas citas antes de dar nada por bueno.

## Los tokens

| Token | Qué gobierna |
|---|---|
| `AppColors` | La paleta. `primary` es el azul de marca (#0D47A1); `accentGreen` el verde del brazo del isotipo. |
| `AppTextStyles` | Inter embebida 400–800, con los estilos del prototipo. |
| `AppRadii` | Radios de tarjeta, chip y campo. |
| `DsScale` | Traduce el lienzo de 402×874 a píxeles del dispositivo. |

### `DsScale`, o por qué nada usa proporciones

El prototipo mide en píxeles sobre un lienzo fijo. Traducir eso con
proporciones (`h * 0.008`) produce una app que en un iPhone SE se ve apretada y
en un iPad se estira. `DsScale` acota los factores —ancho 0.86–1.15, tipografía
0.92–1.08— y expone los márgenes ya escalados:

```dart
final ds = context.ds;
Padding(padding: EdgeInsets.all(ds.w(16)), child: …)   // 16 del diseño
Text('Saldo', style: AppTextStyles.body(fontSize: ds.sp(10.5)))
```

Los gaps superiores tienen nombre porque el diseño los cambió al meter la barra
de marca: `topGap` (96 desde el borde físico, pantallas claras), `topGapHero`
(92, héroes azules) y `topGapBand` (112, pantallas que abren con banda azul a
sangre y por eso no pueden usar `SafeArea`).

## La marca

El isotipo y el wordmark **se dibujan en código** (`KrediusMark`,
`KrediusWordmark`), no se cargan como imagen: así se tiñen, escalan y animan sin
assets. Los archivos originales están en `assets/brand/` como referencia y para
generar los íconos nativos — no se empaquetan, y `assets/brand/USO.md` explica
por qué.

## El guard de tokens

`fa_shell/test/design_system_compliance_test.dart` recorre las pantallas ya
migradas y **falla si aparece un `Color(0x…)` o un `Colors.<matiz>`**. No es
burocracia: el drift de color no se ve en un diff, se ve tres semanas después
cuando dos pantallas hermanas ya no combinan.

## Componentes

Unos 35, del `DsButton` al `DsSignaturePad`. Los que gobiernan el recorrido:

- **`DsBrandBar`** — la barra global con avatar, isotipo y campana. La monta el
  shell **sobre todas las pantallas**, no cada una.
- **`DsTopBar`** — botón de volver, título y chip. La barra *de pantalla*.
- **`DsActiveCreditCard`**, **`DsLineSummaryCard`** — las dos tarjetas azules
  del home. Comparten fondo y estilo a propósito: son el mismo tipo de objeto.
- **`DsHeroScaffold`** — el azul a sangre con sus blobs, para los desenlaces.
