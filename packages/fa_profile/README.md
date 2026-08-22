# fa_profile

El expediente de quien está dentro, en modo consulta.

| | |
|---|---|
| Rutas | `/profile` |
| Tabs | ninguno |
| Tarjeta del home | ninguna |
| Depende de | `fa_core`, `fa_design_system` |

Se abre desde el avatar de la barra de marca. Sigue el tab 4 del diseño
(Journey L951–L982): fondo claro y el expediente en **grupos de campos de sólo
lectura**, cada uno con el sello de dónde salió el dato — `INE · OCR`,
`VALIDADO`, `CP VALIDADO`, `OTP VERIFICADO` —, más los contratos vigentes.

## Dos fuentes, una pantalla

El BFF arma `/users/me` juntando **party-service** (identidad ya verificada:
nombre, CURP, RFC, estatus KYC) con **origination** (el expediente tal como la
persona lo capturó: domicilio, género, el celular que verificó con el código).
Si la segunda consulta falla, el perfil sale igual con lo que party sí tiene.

Por eso **los renglones sin valor no se pintan**: es más honesto enseñar menos
que enseñar etiquetas con la nada al lado.

El nombre se muestra con `comoNombrePropio` — llega en mayúsculas porque así lo
guarda la INE. La normalización es de presentación: el dato no se toca.
