# fa_auth

Splash, login y sesión. El módulo más pequeño con estado y el único que puede
decir quién está dentro.

| | |
|---|---|
| Rutas | `/splash`, `/login` |
| Tabs | ninguno |
| Tarjeta del home | ninguna |
| Depende de | `fa_core`, `fa_design_system` |

## Qué hace

Guarda el token, lo renueva y lo entrega al `ApiClient` para que lo ponga en
cada petición. Cuando el token muere, avisa al shell por
`NavigationCallbacks.onLogout` — no navega solo, porque a dónde ir tras cerrar
sesión es una decisión de la app, no del módulo.

El login pide **celular y contraseña**; el celular es el `username` frente a
identity-service. Las etiquetas van en versalitas (`CELULAR`, `CONTRASEÑA`)
porque así las pinta el diseño.

## Lo que no hace

No da de alta a nadie: eso es `fa_onboarding`. La frontera es útil — una app que
sólo consuma `fa_auth` puede autenticar contra un backend que ya tenga usuarios,
sin arrastrar OCR de INE ni consultas a buró.
