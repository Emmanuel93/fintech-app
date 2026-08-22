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

## Cómo está construido

Arquitectura hexagonal, como todos los módulos: el dominio en el centro sin
importar nada, los casos de uso alrededor, y los adaptadores —HTTP, mocks,
DTOs— en el borde implementando los puertos que el dominio declara. El diagrama
y la regla de las flechas están en
[`fa_core`](../fa_core/README.md#el-hexágono-que-hace-posible-todo-esto).

```
lib/src/
├── domain/          entidades, reglas y puertos
├── application/     casos de uso
├── infrastructure/  adaptadores, DTOs y el mock del módulo
└── presentation/    providers y pantallas
```
