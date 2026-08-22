# Videos del journey E2E

Los cinco videos del recorrido completo viven en `evidencias/` y **no se
versionan**: pesan entre 37 y 135 MB cada uno, son una salida reproducible y no
una fuente, y GitHub rechaza archivos de más de 100 MB. El `.gitignore` excluye
la carpeta entera. Aquí queda cómo volver a generarlos.

Todos corren **contra los servicios reales**, no contra los interceptores mock:
el flavor es `local` (`main_local.dart`), que apunta al gateway en
`http://mobile.localhost:8090`.

## Los cinco recorridos

| Video | Test (`--plain-name`) | Qué muestra |
|---|---|---|
| `kredius_originacion_uso_propio.mp4` | `1 Originacion y credito de uso propio` | Alta completa y un préstamo personal de punta a punta: buró, oportunidades, configurador, contrato, firma y desembolso. |
| `kredius_distribuidor_beneficiario.mp4` | `2 Originacion distribuidor y envio a beneficiario` | Alta de distribuidora (su línea pasa a comité) y, ya con línea aprobada, el envío de un préstamo a una beneficiaria. |
| `kredius_distribuidor_uso_propio_beneficiario.mp4` | `3 Originacion distribuidor uso propio y envio` | Lo anterior más un crédito que la distribuidora toma para sí. |
| `kredius_distribuidor_uso_propio.mp4` | `4 Originacion distribuidor y uso propio` | Alta de distribuidora y crédito propio, sin colocar. |
| `kredius_home_linea_y_credito_propio.mp4` | `5 Home con linea de distribuidor y credito propio` | El home con **las dos cosas vivas** — línea arriba, créditos propios debajo, oportunidades al final — y una colocación de por medio. |

## Antes de grabar

1. Los servicios arriba (`docker compose up -d` en `fintech-services`). Si se
   recreó algún servicio, hay que reiniciar el gateway o responde 502:
   ```sh
   docker compose restart gateway-service
   ```
2. Un simulador booteado. El id que usan los comandos de abajo sale de
   `xcrun simctl list devices booted`.
3. Una **distribuidora con línea activa**.

   De dónde salen: `scripts/seed-distribuidoras.py` recorre el journey real
   (OTP → KYC → alta → solicitud de línea → comité → firma) y usa la clave
   `Kredius#Cliente2026`. Pero las cuentas que suelen estar vivas en la base
   local las crearon **estos mismos E2E**: se dan de alta por `MOBILE_APP` con
   `TestData.password` (`SecurePass1!`), y su línea de distribuidor queda
   `ACTIVE` unos **43 segundos** después del alta. Por eso el valor por omisión
   de `DIST_PASSWORD` es el de `TestData` y no el del script.

   En cualquier caso el teléfono es aleatorio y caduca al resembrar. Los flujos 2 a 5 entran con
   una cuenta que ya pasó comité, y `seed-distribuidoras.py` genera los
   teléfonos al azar, así que el valor por omisión caduca al resembrar:
   ```sh
   docker exec fintech-services-postgres-1 psql -U fintech -d fintech -c "
     select c.username, ca.available_credit
     from credit_portfolio.credit_accounts ca
     join identity.credentials c on c.party_id = ca.obligor_party_id
     where ca.product_code='DL-DIST-STD-V1' and ca.status='ACTIVE'
     order by ca.available_credit desc limit 5;"
   ```
   y se pasa con `--dart-define=DIST_PHONE=<el que salga>`. La contraseña va
   por `--dart-define=DIST_PASSWORD=...` y por omisión es la de `TestData`
   (`SecurePass1!`), que es con la que quedan las cuentas del sembrado.

   Si el teléfono caducó, el síntoma es siempre el mismo: el flujo llega al
   login y muere ahí. En los logs de identity se ve
   `Login failed reason=credential_not_found`.

## Grabar

```sh
DEV=$(xcrun simctl list devices booted | grep -oE '[0-9A-F-]{36}' | head -1)

mkdir -p evidencias
xcrun simctl io booted recordVideo --codec h264 --force evidencias/salida.mp4 &
REC=$!

cd packages/fa_shell
flutter test integration_test/journey_connected_showcase_test.dart \
  -d "$DEV" --plain-name "1 Originacion y credito de uso propio"

kill -INT $REC   # SIGINT: `simctl` cierra el contenedor al recibirlo
```

El `kill -INT` importa: matar el proceso de otra forma deja el MP4 sin
finalizar y no abre.

## Notas

- Cada corrida **crea datos reales**: prospectos, credenciales, cuentas de
  crédito y colocaciones. Es lo que se quiere —el video prueba que el backend
  responde—, pero la base crece con cada grabación.
- La CURP se genera única por corrida (`TestData.uniqueCurp`), porque
  origination rechaza el alta con `DUPLICATE_PROSPECT`.
