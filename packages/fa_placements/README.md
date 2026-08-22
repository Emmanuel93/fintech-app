# fa_placements

Colocación B2B2C: un distribuidor presta **su** línea a un tercero. La deuda
sigue siendo del distribuidor; el crédito y el contrato quedan a nombre de la
persona que recibe.

| | |
|---|---|
| Rutas | `/placements/new`, `/placements/new/amount`, `/placements/sent`, `/placements/:id/bureau` |
| Tabs | `HomeTab.colocaciones`, `HomeTab.beneficiarios` |
| Tarjeta del home | sí — `homeCardOrder = 10`, la primera |
| Depende de | `fa_core`, `fa_design_system` |

## Por qué va primero en el home

La línea de colocación es el dinero del que el distribuidor **responde frente a
Kredius**, y de ella cuelga todo lo demás que hace en la app. Quien abre y ve
primero una promoción y hasta abajo su línea no está viendo su situación: está
viendo un catálogo.

## El flujo

Enviar préstamo → a quién (nombre, celular, cómo la conoces) → monto, plazo y
bonificación → liga enviada. La beneficiaria completa su KYC desde esa liga; el
distribuidor ve su historial y decide. Los estados viven en `PlacementStatus`
(10 valores, incluido `failed`) y la bonificación sale de una tabla de comisión
decreciente `[0.20, 0.17, 0.14, 0.10, 0.06]`.

## Tabs condicionales

`areTabsVisible` devuelve `false` mientras no haya línea: un tab que sólo puede
enseñar un vacío es peor que no estar. Los dos tabs aparecen juntos cuando la
línea se aprueba — **la operación** (Colocaciones) y **el directorio**
(Beneficiarios) del mismo dominio.

El contrato de API está congelado en `docs/KREDIUS_COLOCACION_API.md`.
