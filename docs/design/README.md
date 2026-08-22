# Referencia de diseño

## `Kredius Journey App.dc.html`

El prototipo del que sale la app, exportado desde Claude Design. **Es la fuente
de verdad de la interfaz**: 186 comentarios repartidos en 69 archivos de
`packages/*/lib` lo citan por número de línea (`Journey L2095`, `Journey
L779–L794`), así que el archivo no se toca ni se reordena — si se vuelve a
exportar, hay que revisar esas citas.

Se abre en cualquier navegador. Las 30 pantallas se recorren con el riel de la
izquierda; el lienzo es de 402×874, que es el que `DsScale` traduce a píxeles
del dispositivo.

Dónde está lo que más se consulta:

| Qué | Dónde |
|---|---|
| Barra de marca global (avatar, isotipo, campana) | L63–L82, estilos en L1732–L1746 |
| Home y sus tarjetas | L705–L805 |
| Tarjeta de crédito activo (azul) | L764–L790, estilo en L2095 |
| Tabs del bottom nav según perfil | L1719–L1726 |
| Barra superior de pantalla (`topBar`, `backBtn`) | L1701–L1702 |
| Catálogo de productos y sus tasas | L1563–L1583 |

## `IMPLEMENTACION_UI.md`

Las notas de implementación que venían con el bundle.

## Lo que no está aquí

El bundle original traía además el backoffice, la landing, el KYC de
beneficiario, una web estática y 12 MB de capturas de pantalla. Nada de eso
alimenta esta app, así que no se versionó.

Los archivos de marca —isotipo, logotipo, íconos y el manual que dice cuál
variante va sobre cada fondo— viven en
`packages/fa_design_system/assets/brand/`, junto a los `CustomPainter` que los
reproducen.
