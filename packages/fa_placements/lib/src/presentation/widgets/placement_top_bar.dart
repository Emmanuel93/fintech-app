import 'package:fa_design_system/fa_design_system.dart';
import 'package:flutter/material.dart';

/// Barra superior de las pantallas de colocación — botón de volver, título y,
/// a la derecha, el chip de la línea disponible (Journey App L1032–L1036).
///
/// El chip no es decorativo: en cada paso de la colocación la pregunta de fondo
/// es "¿me alcanza?", y tenerlo a la vista evita llegar al monto y descubrirlo.
class PlacementTopBar extends StatelessWidget {
  const PlacementTopBar({
    super.key,
    required this.title,
    required this.onBack,
    this.trailing,
    this.trailingTone = DsChipTone.info,
  });

  final String title;
  final VoidCallback onBack;
  final String? trailing;
  final DsChipTone trailingTone;

  @override
  Widget build(BuildContext context) {
    final ds = context.ds;
    return Row(
      children: [
        Semantics(
          button: true,
          label: 'Volver',
          child: Material(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(ds.r(12)),
            child: InkWell(
              onTap: onBack,
              borderRadius: BorderRadius.circular(ds.r(12)),
              child: SizedBox(
                width: ds.w(38),
                height: ds.w(38),
                child: Icon(Icons.arrow_back_rounded,
                    size: ds.sp(18), color: AppColors.onSurface),
              ),
            ),
          ),
        ),
        SizedBox(width: ds.w(12)),
        Expanded(
          child: Text(title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.body(
                fontSize: ds.sp(15),
                weight: FontWeight.w600,
                color: AppColors.onSurface,
              ).copyWith(height: 1.0)),
        ),
        if (trailing != null) ...[
          SizedBox(width: ds.w(10)),
          DsStatusChip(label: trailing!, tone: trailingTone, fontSize: 9.5),
        ],
      ],
    );
  }
}
