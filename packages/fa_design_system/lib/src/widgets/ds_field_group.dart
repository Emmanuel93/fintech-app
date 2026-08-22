import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_radii.dart';
import '../theme/app_text_styles.dart';
import '../theme/ds_scale.dart';
import 'ds_status_chip.dart';

/// Encabezado de grupo del prototipo: etiqueta en mayúsculas a la izquierda y
/// **chip de procedencia** a la derecha — `IDENTIDAD · INE · OCR`,
/// `DOMICILIO · CP VALIDADO`, `CONTACTO E INGRESO · OTP VERIFICADO`
/// (Journey L182–L185, datos L1069–L1099).
///
/// El chip es la pieza que le dice al usuario **de dónde salió cada dato**, que
/// es lo que hace creíble el prellenado por OCR.
class DsFieldGroup extends StatelessWidget {
  const DsFieldGroup({
    super.key,
    required this.title,
    required this.children,
    this.source,
    this.sourceTone = DsChipTone.ok,
    this.spacing = 10,
  });

  final String title;

  /// Texto del chip de procedencia. `null` = sin chip.
  final String? source;
  final DsChipTone sourceTone;

  final List<Widget> children;
  final double spacing;

  @override
  Widget build(BuildContext context) {
    final ds = DsScale.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.captionLabel(fontSize: ds.sp(10)),
              ),
            ),
            if (source != null) ...[
              SizedBox(width: ds.w(8)),
              DsStatusChip(label: source!, tone: sourceTone),
            ],
          ],
        ),
        SizedBox(height: ds.h(spacing)),
        for (var i = 0; i < children.length; i++) ...[
          if (i > 0) SizedBox(height: ds.h(spacing)),
          children[i],
        ],
      ],
    );
  }
}

/// Tarjeta blanca de filas etiqueta/valor separadas por `divider` — el bloque
/// de sólo lectura del perfil (Journey L767–L774) y del resumen (L472–L479).
class DsDetailCard extends StatelessWidget {
  const DsDetailCard({
    super.key,
    required this.rows,
    this.labelWidth,
    this.emphasizeLast = false,
  });

  /// Pares (etiqueta, valor).
  final List<(String, String)> rows;

  /// Ancho fijo de la columna de etiquetas (perfil usa 118). `null` = flexible,
  /// con el valor alineado a la derecha (resumen).
  final double? labelWidth;

  /// Resalta la última fila — "Total a pagar" va en `primary` (Journey L1223).
  final bool emphasizeLast;

  @override
  Widget build(BuildContext context) {
    final ds = DsScale.of(context);
    return Container(
      padding: EdgeInsets.symmetric(horizontal: ds.w(16)),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(ds.r(AppRadii.card)),
        border: Border.all(color: AppColors.outlineVariant),
      ),
      child: Column(
        children: [
          for (var i = 0; i < rows.length; i++)
            Container(
              padding: EdgeInsets.symmetric(vertical: ds.h(13)),
              decoration: BoxDecoration(
                border: i < rows.length - 1
                    ? const Border(
                        bottom: BorderSide(color: AppColors.divider))
                    : null,
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: labelWidth == null ? null : ds.w(labelWidth!),
                    child: Text(
                      rows[i].$1,
                      style: AppTextStyles.body(
                        fontSize: ds.sp(13.5),
                        color: labelWidth == null
                            ? AppColors.onSurfaceVariant
                            : AppColors.disabled,
                      ).copyWith(height: 1.3),
                    ),
                  ),
                  SizedBox(width: ds.w(12)),
                  Expanded(
                    child: Text(
                      rows[i].$2,
                      textAlign: TextAlign.end,
                      style: AppTextStyles.body(
                        fontSize:
                            ds.sp(emphasizeLast && i == rows.length - 1 ? 16 : 13.5),
                        weight: FontWeight.w700,
                        color: emphasizeLast && i == rows.length - 1
                            ? AppColors.primary
                            : AppColors.onSurface,
                      ).copyWith(height: 1.35),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
