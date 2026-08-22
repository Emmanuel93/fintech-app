# Kredius — assets de marca

## Construcción

El isotipo es una **K** de tres trazos rectos sobre una caja de 100×100:

- **Asta** vertical en x=33.1, de y=23 a y=77.
- **Brazo superior** de (32, 52) a (71.8, 23) — **siempre verde `#00B894`**, es el único acento del logo.
- **Brazo inferior** de (32, 48) a (71.8, 77).
- Grosor 7.8 en los tres, remates rectos (`stroke-linecap: butt`), sin redondeo.
- Contenedor: cuadrado de radio 22% del lado.

## Cuándo usar cada versión

| Versión | Cuándo |
|---|---|
| **Azul** (tile azul, K blanca) | Uso principal sobre fondos claros: header web, ícono de app, favicon |
| **Invertido** (tile blanco, K azul) | **Sobre el azul de marca** — es el que usa la pantalla de bienvenida y el login de la app |
| **Blanco sin fondo** | Sobre fotografía oscura o azul, cuando no quieres el tile |
| **Azul sin fondo** | Sobre blanco o papel `#EBF0F7`, cuando no quieres el tile |
| **Tinta sin fondo** | Documentos en una sola tinta, impresión monocromática |

## Contenido

```
isotipo/
  kredius-isotipo-azul.svg              vectorial, uso principal
  kredius-isotipo-invertido.svg         vectorial, tile blanco sobre azul  ← el del welcome
  kredius-isotipo-blanco.svg            vectorial, sin fondo
  kredius-isotipo-azul-{1024,512,256,128}.png
  kredius-isotipo-invertido-{1024,512,256,128}.png
  kredius-isotipo-blanco-transparente-1024.png
  kredius-isotipo-azul-transparente-1024.png
  kredius-isotipo-tinta-transparente-1024.png

logotipo/
  kredius-logotipo-azul.svg / .png          marca + palabra en azul
  kredius-logotipo-invertido.svg / .png     tile blanco, palabra blanca — para fondo azul
  kredius-logotipo-sobre-azul.png           lockup completo con fondo azul incluido
  kredius-logotipo-blanco.png               todo blanco, sin tile

app-icon/
  ios-appstore-1024.png                 sin radio, iOS aplica su máscara
  android-{512,192,144,96,72,48}.png     mdpi → xxxhdpi + ficha de Play
  android-adaptive-foreground-432.png    capa de primer plano, transparente
  android-adaptive-background-432.png    capa de fondo, azul sólido
  favicon-180.png                        apple-touch-icon
  favicon-32.png                         favicon web
  splash-marca-blanca-1024.png           para splash sobre azul sólido
```

## Reglas

- El logotipo se escribe **Kredius**, una sola mayúscula. Inter 800, tracking −2.2px.
- Área de respeto: como mínimo el 25% del lado del isotipo en los cuatro costados.
- Tamaño mínimo del isotipo: 24px en pantalla, 8mm impreso.
- El brazo superior **nunca** cambia de color: `#00B894` en todas las versiones.
- No rotar, no aplicar sombra, no degradados, no cambiar la proporción entre asta y brazos.

## Color

| Rol | Hex |
|---|---|
| Azul Kredius | `#0D47A1` |
| Verde acento | `#00B894` |
| Tinta | `#0F1A2E` |
| Papel | `#EBF0F7` |
| Blanco | `#FFFFFF` |

## Integración

**Android** (`ic_launcher.xml`):
```xml
<adaptive-icon xmlns:android="http://schemas.android.com/apk/res/android">
    <background android:drawable="@color/kredius_blue"/>
    <foreground android:mipmap="@mipmap/ic_launcher_foreground"/>
</adaptive-icon>
```

**Flutter splash** (`flutter_native_splash`):
```yaml
flutter_native_splash:
  color: "#0D47A1"
  image: assets/brand/splash-marca-blanca-1024.png
  android_12:
    color: "#0D47A1"
    image: assets/brand/splash-marca-blanca-1024.png
```
