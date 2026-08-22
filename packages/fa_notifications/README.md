# fa_notifications

La bandeja de notificaciones y el contador de no leídas.

| | |
|---|---|
| Rutas | `/notifications` |
| Tabs | ninguno |
| Tarjeta del home | ninguna |
| Depende de | `fa_core`, `fa_design_system` |

## Cómo aparece en el home sin estar en el home

No pone tarjeta ni tab: expone el número de no leídas por
`IModule.getHeaderBadgeCount`, y el shell lo usa para encender el punto ámbar de
la campana en la barra de marca. Es el ejemplo más limpio del contrato — el
módulo aporta un dato, no un widget, y el shell decide dónde se ve.

## Tolerancia a un backend incompleto

`NotificationProvider` se traga los fallos y deja la lista vacía: si
notifications-service todavía no responde, la app sigue funcionando sin bandeja
en vez de romperse. Y hereda `SafeNotifier`, porque una carga en vuelo que
termina después de que la pantalla se fue no debe avisarle a nadie.
