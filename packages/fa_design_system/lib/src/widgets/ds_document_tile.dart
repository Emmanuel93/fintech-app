import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_radii.dart';
import '../theme/app_text_styles.dart';
import '../theme/ds_scale.dart';
import '../motion/kredius_motion.dart';
import 'ds_status_chip.dart';

/// Fila de captura de documento — Journey L199–L210, estilos L1112–L1117.
///
/// Capturado: borde `outlineVariant`, icono sobre `secondaryContainer`, chip
/// teal `LISTO`. Pendiente: borde `primary` (llama la atención sobre lo que
/// falta), icono sobre `primaryContainer`, chip azul `CAPTURAR`.
///
/// Cuando hay [preview] se muestra la miniatura real de lo capturado en lugar
/// del icono — el prototipo no lo contempla, pero sin ella el usuario no tiene
/// forma de saber *qué* foto quedó guardada.
class DsDocumentTile extends StatelessWidget {
  const DsDocumentTile({
    super.key,
    required this.name,
    required this.hint,
    required this.captured,
    required this.onTap,
    this.icon = Icons.photo_camera_outlined,
    this.preview,
    this.isBusy = false,
  });

  final String name;
  final String hint;
  final bool captured;
  final VoidCallback onTap;
  final IconData icon;

  /// Miniatura del documento ya capturado.
  final ImageProvider? preview;

  /// Muestra un indicador en lugar del chip (ej. subiendo/OCR en curso).
  final bool isBusy;

  Widget _fallbackIcon(DsScale ds) => Icon(
        icon,
        size: ds.sp(19),
        color: captured ? AppColors.secondary : AppColors.primary,
      );

  @override
  Widget build(BuildContext context) {
    final ds = DsScale.of(context);
    final double box = ds.w(42);

    return Semantics(
      button: true,
      label: '$name. ${captured ? 'Capturado' : 'Pendiente de capturar'}. $hint',
      child: Material(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(ds.r(AppRadii.cardSmall)),
        child: InkWell(
          onTap: isBusy ? null : onTap,
          borderRadius: BorderRadius.circular(ds.r(AppRadii.cardSmall)),
          child: AnimatedContainer(
            duration: KrediusMotion.tab,
            curve: KrediusMotion.ease,
            padding: EdgeInsets.all(ds.w(15)),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(ds.r(AppRadii.cardSmall)),
              border: Border.all(
                color: captured ? AppColors.outlineVariant : AppColors.primary,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: box,
                  height: box,
                  alignment: Alignment.center,
                  clipBehavior: Clip.antiAlias,
                  decoration: BoxDecoration(
                    color: captured
                        ? AppColors.secondaryContainer
                        : AppColors.primaryContainer,
                    borderRadius: BorderRadius.circular(ds.r(12)),
                  ),
                  // La miniatura se pinta con `Image` y no con `DecorationImage`
                  // a propósito: los bytes que llegan del picker no siempre son
                  // una imagen decodificable (un HEIC que el decoder no soporta,
                  // un archivo truncado, un stub de test), y `DecorationImage`
                  // no ofrece forma de degradar — lanza y tumba el frame. Con
                  // `errorBuilder` la tarjeta cae al icono y el usuario sigue.
                  child: preview != null
                      ? Image(
                          image: preview!,
                          fit: BoxFit.cover,
                          width: box,
                          height: box,
                          gaplessPlayback: true,
                          errorBuilder: (_, __, ___) => _fallbackIcon(ds),
                        )
                      : _fallbackIcon(ds),
                ),
                SizedBox(width: ds.w(13)),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.body(
                          fontSize: ds.sp(14),
                          weight: FontWeight.w600,
                          color: AppColors.onSurface,
                        ).copyWith(height: 1.2),
                      ),
                      SizedBox(height: ds.h(5)),
                      Text(
                        hint,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.body(
                          fontSize: ds.sp(11.5),
                          color: AppColors.disabled,
                        ).copyWith(height: 1.35),
                      ),
                    ],
                  ),
                ),
                SizedBox(width: ds.w(10)),
                if (isBusy)
                  SizedBox(
                    width: ds.w(18),
                    height: ds.w(18),
                    child: const CircularProgressIndicator(strokeWidth: 2),
                  )
                else
                  DsStatusChip(
                    label: captured ? 'LISTO' : 'CAPTURAR',
                    tone: captured ? DsChipTone.ok : DsChipTone.info,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
