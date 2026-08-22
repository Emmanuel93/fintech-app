# Marca Kredius — material de referencia

Estos archivos **no se empaquetan en la app**: no están declarados en
`pubspec.yaml` a propósito. El isotipo y el wordmark se dibujan en código
(`lib/src/brand/kredius_mark.dart` y `kredius_wordmark.dart`), que es lo que
permite teñirlos, escalarlos y animarlos sin cargar imágenes.

Sirven para tres cosas:

1. **Verificar los painters.** `KrediusMark` reproduce 1:1 la geometría de
   `isotipo/kredius-isotipo-azul.svg` (viewBox 100×100, stroke 7.8).
2. **Generar los íconos nativos**, que sí se versionan ya generados en
   `packages/fa_shell/ios/Runner/Assets.xcassets` y en las mipmaps de Android.
   Las fuentes están en `app-icon/`.
3. **Consultar `README.md`**, que es el manual de marca: dice qué variante va
   sobre cada fondo. Los doc comments de los painters lo citan.
