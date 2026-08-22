import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../theme/ds_scale.dart';
import 'ds_status_chip.dart';

/// La barra superior de las pantallas claras — Journey App L1701–L1702.
///
/// El diseño la define una sola vez y la reusa en todo el journey:
///
/// ```
/// topBar: display:flex; align-items:center; gap:14px
/// backBtn: 38×38, radio 12, fondo #fff, borde 1px #E0E0E0
/// ```
///
/// Es un **tile blanco con borde**, no un `IconButton` ni una flecha suelta: se
/// lee como control tocable sobre el papel gris, que es justo lo que un icono
/// sin fondo no consigue. Y no es un `AppBar` de Material — el diseño no tiene
/// elevación, ni centra el título, ni reserva los 56 px de alto de Material.
///
/// A la derecha admite un chip (la línea disponible, el estado del KYC) o
/// cualquier widget; el título se trunca antes que empujarlo fuera.
class DsTopBar extends StatelessWidget {
  const DsTopBar({
    super.key,
    required this.onBack,
    this.title,
    this.chipLabel,
    this.chipTone = DsChipTone.info,
    this.trailing,
    this.backSemanticLabel = 'Volver',
  });

  final VoidCallback onBack;

  /// Título a la izquierda, pegado al botón. Nulo en las pantallas que abren
  /// con barra de progreso en vez de nombre.
  final String? title;

  /// Chip a la derecha. Excluyente con [trailing].
  final String? chipLabel;
  final DsChipTone chipTone;

  /// Contenido libre a la derecha — una barra de progreso, un contador.
  final Widget? trailing;

  final String backSemanticLabel;

  @override
  Widget build(BuildContext context) {
    final ds = DsScale.of(context);

    return Row(
      children: [
        Semantics(
          button: true,
          label: backSemanticLabel,
          child: Material(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(ds.r(12)),
            child: InkWell(
              onTap: onBack,
              borderRadius: BorderRadius.circular(ds.r(12)),
              child: Container(
                width: ds.w(38),
                height: ds.w(38),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(ds.r(12)),
                  border: Border.all(color: AppColors.outlineVariant),
                ),
                child: Icon(Icons.arrow_back_rounded,
                    size: ds.sp(18), color: AppColors.onSurface),
              ),
            ),
          ),
        ),
        if (title != null) ...[
          SizedBox(width: ds.w(14)),
          Expanded(
            child: Text(title!,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.body(
                  fontSize: ds.sp(15),
                  weight: FontWeight.w600,
                  color: AppColors.onSurface,
                ).copyWith(height: 1.0)),
          ),
        ] else
          const Spacer(),
        if (trailing != null) ...[
          SizedBox(width: ds.w(10)),
          trailing!,
        ] else if (chipLabel != null) ...[
          SizedBox(width: ds.w(10)),
          DsStatusChip(label: chipLabel!, tone: chipTone, fontSize: 9.5),
        ],
      ],
    );
  }
}
