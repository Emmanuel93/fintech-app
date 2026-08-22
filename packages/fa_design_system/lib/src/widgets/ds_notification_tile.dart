import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_radii.dart';
import '../theme/app_text_styles.dart';
import '../theme/ds_scale.dart';

/// Tono de una notificación — Journey L1449. Cada uno fija el par
/// texto/fondo que comparten el icono y el chip de categoría.
enum DsNotificationTone {
  /// Teal — pago recibido, línea que subió, contrato firmado.
  ok,

  /// Ámbar — pago por vencer.
  warn,

  /// Rojo — alerta de seguridad.
  bad,

  /// Azul — informativo.
  info;

  Color get foreground => switch (this) {
        DsNotificationTone.ok => AppColors.secondary,
        DsNotificationTone.warn => AppColors.onTertiaryContainer,
        DsNotificationTone.bad => AppColors.error,
        DsNotificationTone.info => AppColors.primary,
      };

  Color get background => switch (this) {
        DsNotificationTone.ok => AppColors.secondaryContainer,
        DsNotificationTone.warn => AppColors.tertiaryContainer,
        DsNotificationTone.bad => AppColors.errorContainer,
        DsNotificationTone.info => AppColors.primaryContainer,
      };
}

/// Fila de notificación — Journey L1035–L1050.
///
/// Icono en tile de 36 con el tono de la categoría, título con el punto ámbar
/// de "sin leer" a la derecha, cuerpo, y al pie el chip de categoría con la
/// hora. Las filas van dentro de una tarjeta blanca compartida, separadas por
/// `divider`, así que el separador lo dibuja la propia fila salvo la última.
class DsNotificationTile extends StatelessWidget {
  const DsNotificationTile({
    super.key,
    required this.icon,
    required this.title,
    required this.body,
    required this.tag,
    required this.time,
    this.tone = DsNotificationTone.info,
    this.unread = false,
    this.isLast = false,
    this.onTap,
  });

  final IconData icon;
  final String title, body, tag, time;
  final DsNotificationTone tone;
  final bool unread;
  final bool isLast;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final ds = DsScale.of(context);

    final row = Container(
      padding: EdgeInsets.symmetric(vertical: ds.h(15)),
      decoration: BoxDecoration(
        border: isLast
            ? null
            : const Border(bottom: BorderSide(color: AppColors.divider)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: ds.w(36),
            height: ds.w(36),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: tone.background,
              borderRadius: BorderRadius.circular(ds.r(11)),
            ),
            child: Icon(icon, size: ds.sp(17), color: tone.foreground),
          ),
          SizedBox(width: ds.w(12)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(title,
                          style: AppTextStyles.body(
                            fontSize: ds.sp(13.5),
                            weight: FontWeight.w600,
                            color: AppColors.onSurface,
                          ).copyWith(height: 1.25)),
                    ),
                    if (unread) ...[
                      SizedBox(width: ds.w(7)),
                      Container(
                        width: ds.w(8),
                        height: ds.w(8),
                        margin: EdgeInsets.only(top: ds.h(4)),
                        decoration: const BoxDecoration(
                            color: AppColors.tertiary, shape: BoxShape.circle),
                      ),
                    ],
                  ],
                ),
                SizedBox(height: ds.h(5)),
                Text(body,
                    style: AppTextStyles.body(fontSize: ds.sp(12))
                        .copyWith(height: 1.45)),
                SizedBox(height: ds.h(8)),
                Row(
                  children: [
                    Container(
                      padding: EdgeInsets.symmetric(
                          horizontal: ds.w(8), vertical: ds.h(3)),
                      decoration: BoxDecoration(
                        color: tone.background,
                        borderRadius: BorderRadius.circular(AppRadii.chip),
                      ),
                      child: Text(tag,
                          style: AppTextStyles.chipLabel(
                              fontSize: ds.sp(8.5), color: tone.foreground)
                          .copyWith(height: 1.5)),
                    ),
                    SizedBox(width: ds.w(9)),
                    Text(time,
                        style: AppTextStyles.body(
                          fontSize: ds.sp(10.5),
                          color: AppColors.disabled,
                        ).copyWith(height: 1.0)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );

    if (onTap == null) return row;
    return Semantics(
      button: true,
      label: '$title. $body',
      child: InkWell(onTap: onTap, child: row),
    );
  }
}
