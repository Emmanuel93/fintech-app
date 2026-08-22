# Colocación B2B2C — contrato que la app ya consume

**Fecha:** 2026-08-16
**Estado del front:** implementado y en verde contra `PlacementsMockInterceptor`.
**Estado del backend:** por implementar.

Este documento **no es una propuesta**: es el contrato que la app Flutter ya
consume hoy. El mock (`fa_placements/lib/src/infrastructure/mock/placements_mock_interceptor.dart`)
lo cumple campo por campo, y los DTOs (`fa_placements/lib/src/infrastructure/dtos/`)
lo parsean. Cuando el BFF responda esto, conectar es **sacar una línea** de
`ShellInjection.buildApiClient()` — no se toca ni el repositorio ni las
pantallas.

Todo cuelga del BFF `channel-mobile-service`, tras el gateway, con el `partyId`
del titular tomado del header `X-User-Id`. Ningún endpoint recibe el
`distributorId` en el body: se deriva del token.

---

## Convenciones

- Montos: `number` en pesos, sin centavos forzados.
- Fechas: ISO-8601 con zona (`2026-08-16T10:32:00-06:00`).
- Los campos marcados **(req)** son obligatorios; el resto puede venir `null`.
- **Los errores se devuelven como 4xx con `{"message": "..."}`.** El mensaje se
  muestra tal cual al usuario, así que se escribe para él, no para el log.

---

## 1. `GET /distributor/line-summary`

La tarjeta "MI LÍNEA DE DISTRIBUIDOR" del home y el tope del configurador.

**Respuesta 200**

```json
{
  "authorized": 250000,
  "placed": 45000,
  "available": 205000,
  "toCollect": 11700,
  "dueToKredius": 9360,
  "commissionAccrued": 8240,
  "nextDueDate": "2026-09-05T00:00:00-06:00",
  "daysPastDue": 0
}
```

| Campo | Tipo | Notas |
|---|---|---|
| `authorized` **(req)** | number | Línea total que aprobó el comité. |
| `placed` **(req)** | number | Colocado y vivo. |
| `available` | number | La app recalcula `authorized − placed` si no viene. |
| `toCollect` | number | Lo que sus beneficiarios le pagan en el corte. |
| `dueToKredius` | number | Lo que él le paga a Kredius en el corte. |
| `commissionAccrued` | number | Bonificación devengada del periodo. |
| `nextDueDate` | date | Corte. |
| `daysPastDue` | int | Mora **de la línea con Kredius**, no la de sus clientes. |

> **Sin línea:** responder **200 con `authorized: 0`**, no 404. La app lo lee
> como "este titular no coloca" y esconde el módulo entero — pestañas incluidas.
> Un 404 la haría mostrar un error donde no hay ninguno.

---

## 2. `POST /placements`

Crea la colocación y manda la liga de KYC al beneficiario.

**Request**

```json
{
  "beneficiary": {
    "fullName": "Rosa Elena Díaz Fuentes",
    "phone": "5549029037",
    "relationship": "Clienta de mi tienda desde 2023"
  },
  "amount": 18000,
  "termFortnights": 24,
  "verificationMode": "SELF_SERVICE_LINK"
}
```

- `phone`: 10 dígitos, **sin** formato ni lada país. Es el celular **del
  beneficiario**; ahí le llega su liga y su código.
- `verificationMode`: hoy siempre `SELF_SERVICE_LINK`. El enum existe porque el
  diseño contempla un modo asistido más adelante.

**Respuesta 201** — el objeto Colocación (§3).

**Errores esperados**

| Status | Cuándo | `message` sugerido |
|---|---|---|
| 400 | falta nombre o el celular no trae 10 dígitos | `Faltan el nombre o el celular del beneficiario` |
| 409 | `amount` supera `available` | `El monto supera tu línea disponible` |
| 409 | ese celular ya tiene una colocación viva sin terminar | `Ya le enviaste una liga a este número` |

> **La línea NO se aparta aquí.** Se descuenta al aprobar (§6). La app lo
> promete en pantalla con estas palabras: *"Tu línea sigue completa en $X: solo
> se descuenta cuando ella termine su verificación y tú apruebes."*

---

## 3. El objeto Colocación

Lo devuelven `GET /placements/{id}`, `POST /placements` y las acciones.

```json
{
  "placementId": "pl-01J8Z4",
  "beneficiaryName": "Rosa Elena Díaz Fuentes",
  "beneficiaryPhoneMask": "55 •• •• 90 37",
  "beneficiaryPartyId": null,
  "relationship": "Clienta de mi tienda desde 2023",
  "amount": 18000,
  "termFortnights": 24,
  "fortnightlyPayment": 868.06,
  "status": "invited",
  "commissionAccrued": 0,
  "paymentsMade": 0,
  "daysPastDue": 0,
  "placedOn": null,
  "inviteExpiresAt": "2026-08-23T10:32:00-06:00"
}
```

| Campo | Notas |
|---|---|
| `beneficiaryPhoneMask` **(req)** | **Enmascarado desde el servidor.** La app nunca recibe el celular completo de un tercero; el formato es `55 •• •• 90 37`. |
| `beneficiaryPartyId` | `null` hasta que completa su KYC y se crea su Party. |
| `fortnightlyPayment` **(req)** | Lo calcula el backend. La app lo estima localmente sólo mientras el usuario mueve el slider; **la cifra del contrato es la del servidor**. |
| `commissionAccrued` | Bonificación ya devengada de esta colocación. |
| `daysPastDue` | Lo decide el backend (días de gracia, festivos, fecha de aplicación del pago). La app **no** lo calcula contra el reloj del teléfono. |
| `inviteExpiresAt` | `createdAt + 7 días`. |

### `status` — máquina de estados

```
invited ──▶ kycInProgress ──▶ bureauReady ──┬─▶ approved ──▶ active ──▶ paidOff
   │              │                          └─▶ declined
   ├──▶ expired (7 días sin completar)
   └──▶ cancelled (el distribuidor la revoca)
```

| Valor | Significado | ¿Consume línea? |
|---|---|---|
| `invited` | liga enviada, sin abrir | no |
| `kycInProgress` | el beneficiario está en su verificación | no |
| `bureauReady` | KYC hecho y buró consultado — **espera decisión** | no |
| `approved` | aprobada, desembolsando | sí |
| `active` | depositada, con contrato vivo | sí |
| `paidOff` | liquidada | sí |
| `declined` | el distribuidor decidió no colocar | no |
| `expired` | la liga venció | no |
| `cancelled` | revocada antes de que terminara | no |

**Estos son los strings exactos que la app parsea** (`PlacementStatus.fromName`).
Un valor desconocido cae a `invited`, así que agregar estados requiere avisar.

---

## 4. `GET /placements`

```json
{ "placements": [ { …objeto Colocación… } ] }
```

Ordenado por actividad reciente. La app filtra y busca en cliente (la cartera de
un distribuidor es de decenas, no de miles); si eso cambia, se añaden
`?status=` y `?page=` sin romper este contrato.

---

## 5. `GET /placements/{id}/bureau`

Sólo válido con `status = bureauReady` (o posterior).

```json
{
  "score": 664,
  "band": "medium",
  "bandLabel": "RIESGO MEDIO",
  "title": "Paga, pero se ha atrasado",
  "description": "Cumple con sus dos créditos actuales y trae un atraso de 29 días en los últimos dos años. No es un historial limpio ni uno malo.",
  "facts": [
    { "label": "Peor atraso en 24 meses", "value": "29 días", "tone": "warn" },
    { "label": "Créditos vigentes", "value": "2, ambos al corriente", "tone": "ok" },
    { "label": "Deuda contra su ingreso", "value": "38%", "tone": "ok" },
    { "label": "Consultas en 6 meses", "value": "2", "tone": "ok" },
    { "label": "Recomendación de Kredius", "value": "Colocar con reserva", "tone": "warn" }
  ]
}
```

- `band`: `low` | `medium` | `high`.
- `tone`: `ok` | `warn` | `bad` — sólo gobierna el color del renglón.
- `title` y `description` los redacta el **backend**, no la app: son la lectura
  del historial en palabras y dependen de datos que la app no tiene.
- `facts` es una lista abierta: la app pinta las que lleguen, en orden.

**409 si todavía no hay reporte.** No devolver un objeto vacío ni ceros: un
reporte en blanco se lee como historial limpio, y esa confusión cuesta dinero.

> **Requisito legal, no de UI:** este reporte se obtiene con la autorización que
> firmó **el beneficiario** en su propio flujo, nunca con la del distribuidor.
> La consulta debe quedar registrada a nombre de él, con fecha, hora e IP.

---

## 6. `POST /placements/{id}/approve`

```json
{ "riskAcknowledged": true }
```

Es la decisión del distribuidor. Dispara la disposición
`THIRD_PARTY_CREDIT` con el `beneficiaryPartyId` y el desembolso a su CLABE.

- **Aquí se descuenta la línea**, no antes.
- `riskAcknowledged: true` es la constancia de que vio el historial. **Guárdala
  con timestamp**: es la defensa del "yo no sabía".
- Responde el objeto Colocación en `approved` o `active`.
- **409** si la colocación no está en `bureauReady`.

## 7. `POST /placements/{id}/reject`

Cierra la colocación en `declined` sin tocar la línea. Body opcional:
`{ "reason": "..." }`.

## 8. `POST /placements/{id}/resend` y `/cancel`

Reenvían la liga (reiniciando los 7 días) o revocan la colocación. Ambos
devuelven el objeto Colocación.

---

## 9. `GET /beneficiaries`

El directorio de personas — distinto de las colocaciones: una persona puede
tener varias a lo largo del tiempo.

```json
{
  "beneficiaries": [
    {
      "partyId": "9f1c…",
      "fullName": "María Luisa Cortés",
      "phoneMask": "55 •• •• 90 37",
      "summary": "Clienta desde 2023 · 2 préstamos contigo",
      "status": "active",
      "placementsCount": 2,
      "facts": [
        { "label": "Le has prestado", "value": "$63,000" },
        { "label": "Saldo hoy", "value": "$45,000" },
        { "label": "Te ha generado", "value": "$3,240", "good": true },
        { "label": "Puntualidad", "value": "100%", "good": true }
      ]
    }
  ]
}
```

- `status`: `active` | `overdue` | `onboarding` | `paidOff`.
- `facts`: **valores ya formateados** (con `$` y separadores). Son de lectura, no
  de cálculo, y formatearlos en el servidor evita que la app y el backoffice
  redondeen distinto el mismo dato.
- `good` / `bad`: opcionales, tiñen el valor de verde o rojo.

---

## 10. Reglas de negocio que el contrato debe honrar

Están escritas en la pantalla, así que el backend no puede contradecirlas:

1. **La línea no se aparta al invitar.** Se descuenta al aprobar.
2. **La liga vive 7 días.** Si expira, la colocación no se crea.
3. **El KYC es todo o nada.** Sin selfie no hay expediente.
4. **El buró se consulta con la autorización del beneficiario.**
5. **Kredius no filtra por score.** Entrega el reporte; decide el distribuidor.
6. **Bonificación del 20 % sobre lo cobrado a tiempo**, decreciente por día de
   atraso: 17 %, 14 %, 10 %, 6 % y **cero al quinto día**. Implementado y
   probado en `CommissionPolicy` (`fa_placements`); el backend debe devolver
   `commissionAccrued` ya calculado con esta misma escala.

---

## 11. Pricing que hoy vive en la app

`PlacementPricing` (fa_placements) tiene los valores del prototipo: tasa
**28.9 % anual sobre 24 quincenas**, plazos **12 / 24 / 36 / 48**, monto mínimo
**$5,000** y escalón de **$1,000**.

Es un *fallback* para que el slider responda sin ir al servidor. **Cuando
`/distributor/line-summary` devuelva estos valores** (`annualRate`,
`terms`, `minAmount`, `amountStep`), la app los tomará de ahí y el fallback
quedará sólo para el primer render.

---

## 12. Lo que falta y no está en este contrato

| Qué | Por qué no está |
|---|---|
| **API pública del KYC web del beneficiario** | Es otra superficie (web, sin JWT, por token de liga). No la consume esta app. |
| `GET /beneficiaries/{id}/contract` y `/payments` | Las dos acciones de la ficha están dibujadas y **desactivadas** hasta que existan. |
| Detalle de una colocación activa | La fila abre el expediente sólo para las que esperan decisión; el resto no tiene pantalla propia todavía. |
