import 'package:flutter/material.dart';

import '../brand/kredius_mark.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../theme/ds_scale.dart';

/// Barra de marca global — Journey App L63–L82, estilos L1732–L1746.
///
/// Es la barra que el diseño monta **encima de todas las pantallas** salvo la
/// bienvenida y el login (`showBrand: !(s.login || s.screen === 0)`): 38 px de
/// alto, pegada al borde superior del área segura, con el isotipo y el wordmark
/// **centrados** y dos acciones a los lados.
///
/// Las acciones no siempre se ven. El diseño las esconde con `visibility:hidden`
/// fuera de la app (`inApp = [13, 16]`, home y notificaciones): durante el alta
/// no hay a quién mostrarle su perfil ni notificaciones que leer, pero el hueco
/// se conserva para que el logo quede centrado igual en todo el recorrido. Por
/// eso [showActions] oculta sin desmontar.
///
/// [dark] es el tratamiento sobre el azul de marca (`brandDark`, pantallas 6,
/// 12, 14, 15 y 23: aprobado, desembolso, contraoferta, rechazo y liga enviada).
class DsBrandBar extends StatelessWidget {
  const DsBrandBar({
    super.key,
    required this.initials,
    this.onProfile,
    this.onNotifications,
    this.showActions = false,
    this.dark = false,
    this.hasUnread = true,
  });

  /// Iniciales de quien está dentro ("EH" en el diseño).
  final String initials;

  final VoidCallback? onProfile;
  final VoidCallback? onNotifications;

  /// Avatar y campana visibles. Fuera de home/notificaciones el diseño los
  /// esconde pero les guarda el lugar.
  final bool showActions;

  /// Tratamiento sobre fondo azul de marca.
  final bool dark;

  /// Punto ámbar sobre la campana. El diseño lo apaga estando ya en
  /// notificaciones (`brandDotStyle` en la pantalla 16).
  final bool hasUnread;

  /// Alto de la barra en unidades de diseño (L1733). El hueco que necesita
  /// debajo ya está repartido en los gaps de `DsScale` (`topGap` = 96 desde el
  /// borde físico, `topGapBand` = 112), no se reserva desde aquí.
  static const double designHeight = 38;

  /// "Laura Méndez" → "LM"; "Laura" → "LA"; vacío → "—".
  static String initialsOf(String name) {
    final parts =
        name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return '—';
    if (parts.length == 1) {
      final one = parts.first;
      return one.substring(0, one.length >= 2 ? 2 : 1).toUpperCase();
    }
    return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final ds = context.ds;
    final onBrand = dark ? AppColors.onPrimary : AppColors.primary;

    return SizedBox(
      height: ds.h(designHeight),
      child: Row(
        children: [
          // Flex 1 a cada lado (L1734/L1735): así el logo queda centrado
          // aunque las acciones estén ocultas.
          Expanded(
            child: Align(
              alignment: Alignment.centerLeft,
              child: Visibility(
                visible: showActions,
                maintainSize: true,
                maintainAnimation: true,
                maintainState: true,
                child: _CircleTap(
                  onTap: onProfile,
                  semanticLabel: 'Mi perfil',
                  background: dark ? AppColors.surface : AppColors.primary,
                  child: Text(
                    initials,
                    style: AppTextStyles.cardTitle(
                      fontSize: ds.sp(12),
                      color: dark ? AppColors.primary : AppColors.onPrimary,
                    ).copyWith(height: 1.0),
                  ),
                ),
              ),
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              KrediusMark(
                size: ds.w(24),
                badge: true,
                // Sobre azul el tile es un velo blanco, no un bloque (L1739).
                badgeColor: dark
                    ? AppColors.onPrimary.withValues(alpha: 0.18)
                    : AppColors.primary,
                strokeColor: AppColors.onPrimary,
              ),
              SizedBox(width: ds.w(8)),
              Text(
                'Kredius',
                style: AppTextStyles.cardTitle(
                  fontSize: ds.sp(14),
                  color: onBrand,
                ).copyWith(
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.7,
                  height: 1.0,
                ),
              ),
            ],
          ),
          Expanded(
            child: Align(
              alignment: Alignment.centerRight,
              child: Visibility(
                visible: showActions,
                maintainSize: true,
                maintainAnimation: true,
                maintainState: true,
                child: _CircleTap(
                  onTap: onNotifications,
                  semanticLabel: hasUnread
                      ? 'Notificaciones, tienes sin leer'
                      : 'Notificaciones',
                  background: dark
                      ? AppColors.onPrimary.withValues(alpha: 0.16)
                      : AppColors.surface,
                  border: dark ? null : AppColors.outline,
                  child: Stack(
                    clipBehavior: Clip.none,
                    alignment: Alignment.center,
                    children: [
                      Icon(
                        Icons.notifications_none_rounded,
                        size: ds.sp(17),
                        color: dark
                            ? AppColors.onPrimary
                            : AppColors.onSurfaceVariant,
                      ),
                      if (hasUnread)
                        Positioned(
                          top: ds.h(1),
                          right: ds.w(1),
                          child: Container(
                            width: ds.w(6),
                            height: ds.w(6),
                            decoration: BoxDecoration(
                              color: AppColors.tertiary,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: dark
                                    ? AppColors.primary
                                    : AppColors.surface,
                                width: 1.5,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Botón circular de 34 px — el avatar y la campana de la barra.
class _CircleTap extends StatelessWidget {
  const _CircleTap({
    required this.child,
    required this.onTap,
    required this.semanticLabel,
    required this.background,
    this.border,
  });

  final Widget child;
  final VoidCallback? onTap;
  final String semanticLabel;
  final Color background;
  final Color? border;

  @override
  Widget build(BuildContext context) {
    final ds = context.ds;
    return Semantics(
      button: true,
      label: semanticLabel,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Container(
          width: ds.w(34),
          height: ds.w(34),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: background,
            shape: BoxShape.circle,
            border: border == null ? null : Border.all(color: border!),
          ),
          child: child,
        ),
      ),
    );
  }
}
