# fa_wallet

La cuenta: saldo, movimientos y envíos.

| | |
|---|---|
| Rutas | `/wallet/movements`, `/wallet/send` |
| Tabs | `HomeTab.movimientos` |
| Tarjeta del home | ninguna |
| Depende de | `fa_core`, `fa_design_system` |

Aporta el tab **Movimientos**, que en el diseño es el segundo del nav para todos
los perfiles: con línea de distribuidor o sin ella, el dinero que entra y sale
se mira en el mismo sitio.

`fa_credit` depende de este módulo —es la única dependencia entre módulos de
dominio del monorepo— porque el desembolso aterriza en la cuenta y el pago sale
de ella. Es una dependencia real del negocio, no un atajo de código.
